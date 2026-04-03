import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/daily_log_model.dart';
import 'storage_service.dart';

class ActivitySnapshot {
  final bool isTracking;
  final String activityLabel;
  final int steps;
  final double distanceMeters;
  final double elevationGainMeters;
  final double activeMinutes;
  final double? paceMinutesPerKm;
  final double stepRateSpm;
  final DateTime? lastUpdated;

  const ActivitySnapshot({
    required this.isTracking,
    required this.activityLabel,
    required this.steps,
    required this.distanceMeters,
    required this.elevationGainMeters,
    required this.activeMinutes,
    required this.paceMinutesPerKm,
    required this.stepRateSpm,
    required this.lastUpdated,
  });

  factory ActivitySnapshot.idle() {
    return const ActivitySnapshot(
      isTracking: false,
      activityLabel: 'INACTIVE',
      steps: 0,
      distanceMeters: 0,
      elevationGainMeters: 0,
      activeMinutes: 0,
      paceMinutesPerKm: null,
      stepRateSpm: 0,
      lastUpdated: null,
    );
  }
}

class ActivityTrackingService {
  ActivityTrackingService._internal();

  static final ActivityTrackingService instance = ActivityTrackingService._internal();

  final StreamController<ActivitySnapshot> _controller = StreamController<ActivitySnapshot>.broadcast();

  Stream<ActivitySnapshot> get stream => _controller.stream;

  ActivitySnapshot _snapshot = ActivitySnapshot.idle();
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _persistTimer;

  bool _tracking = false;
  int _baselineSteps = -1;
  int _rawSteps = 0;
  String _pedestrianStatus = 'unknown';
  DateTime? _sessionStart;
  DateTime? _movingSince;
  Duration _movingDuration = Duration.zero;
  Position? _lastPosition;
  double _distanceMeters = 0;
  double _elevationGainMeters = 0;

  Future<bool> start() async {
    if (!Platform.isAndroid) {
      _emit(ActivitySnapshot.idle());
      return false;
    }

    if (_tracking) {
      return true;
    }

    final activityGranted = await Permission.activityRecognition.request().isGranted;
    if (!activityGranted) {
      _emit(ActivitySnapshot.idle());
      return false;
    }

    final locationPermission = await Geolocator.checkPermission();
    final locationAllowed = locationPermission == LocationPermission.always || locationPermission == LocationPermission.whileInUse || await _requestLocationPermission();

    _tracking = true;
    _sessionStart = DateTime.now();
    _baselineSteps = -1;
    _rawSteps = 0;
    _pedestrianStatus = 'unknown';
    _movingSince = null;
    _movingDuration = Duration.zero;
    _lastPosition = null;
    _distanceMeters = 0;
    _elevationGainMeters = 0;

    _stepSubscription = Pedometer.stepCountStream.listen(
      _handleStepCount,
      onError: (_) => _emit(_buildSnapshot('STEP SENSOR UNAVAILABLE')),
    );

    _statusSubscription = Pedometer.pedestrianStatusStream.listen(
      _handlePedestrianStatus,
      onError: (_) => _emit(_buildSnapshot('STATUS SENSOR UNAVAILABLE')),
    );

    if (locationAllowed) {
      final gpsMode = (StorageService().getAppSettings()['trackerGpsMode'] as String?) ?? 'balanced';
      LocationAccuracy accuracy = LocationAccuracy.medium;
      int distanceFilter = 10;
      if (gpsMode == 'battery') {
        accuracy = LocationAccuracy.low;
        distanceFilter = 25;
      } else if (gpsMode == 'precise') {
        accuracy = LocationAccuracy.bestForNavigation;
        distanceFilter = 5;
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        ),
      ).listen(
        _handlePosition,
        onError: (_) => _schedulePersist(),
      );

      try {
        final currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
        _lastPosition = currentPosition;
      } catch (_) {
        // Location is optional; the tracker still works with steps and status.
      }
    }

    _emit(_buildSnapshot('TRACKING ACTIVE'));
    _schedulePersist();
    return true;
  }

  Future<void> stop() async {
    if (!_tracking) {
      return;
    }

    if (_movingSince != null && _sessionStart != null) {
      _movingDuration += DateTime.now().difference(_movingSince!);
      _movingSince = null;
    }

    await _persistSnapshot();

    await _stepSubscription?.cancel();
    await _statusSubscription?.cancel();
    await _positionSubscription?.cancel();
    _stepSubscription = null;
    _statusSubscription = null;
    _positionSubscription = null;
    _persistTimer?.cancel();
    _persistTimer = null;

    _tracking = false;
    _emit(_buildSnapshot('TRACKING PAUSED'));
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  Future<bool> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  void _handleStepCount(StepCount event) {
    _rawSteps = event.steps;
    if (_baselineSteps < 0) {
      _baselineSteps = event.steps;
      _emit(_buildSnapshot('READY'));
      return;
    }

    _emit(_buildSnapshot(_currentStatusLabel));
    _schedulePersist();
  }

  void _handlePedestrianStatus(PedestrianStatus status) {
    _pedestrianStatus = status.status;

    final moving = _isMovingStatus;
    if (moving && _movingSince == null) {
      _movingSince = DateTime.now();
    }
    if (!moving && _movingSince != null && _sessionStart != null) {
      _movingDuration += DateTime.now().difference(_movingSince!);
      _movingSince = null;
    }

    _emit(_buildSnapshot(_currentStatusLabel));
    _schedulePersist();
  }

  void _handlePosition(Position position) {
    if (_lastPosition != null) {
      final delta = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (delta > 0 && position.accuracy <= 30 && _isMovingStatus) {
        _distanceMeters += delta;
      }

      final elevationDelta = position.altitude - _lastPosition!.altitude;
      if (elevationDelta > 0.75) {
        _elevationGainMeters += elevationDelta;
      }
    }

    _lastPosition = position;
    _emit(_buildSnapshot(_currentStatusLabel));
    _schedulePersist();
  }

  bool get _isMovingStatus => _pedestrianStatus == 'walking' || _pedestrianStatus == 'running';

  String get _currentStatusLabel {
    if (!_tracking) {
      return 'INACTIVE';
    }

    final stepRate = _stepRateSpm;
    if (_pedestrianStatus == 'running' || stepRate >= 145) {
      return 'RUNNING';
    }
    if (_pedestrianStatus == 'walking' || stepRate >= 30) {
      return 'WALKING';
    }
    if (_pedestrianStatus == 'stopped') {
      return 'STILL';
    }
    return 'TRACKING';
  }

  double get _stepRateSpm {
    if (_sessionStart == null) {
      return 0;
    }

    final elapsedMinutes = math.max(1 / 60, DateTime.now().difference(_sessionStart!).inSeconds / 60);
    return _stepsForSession / elapsedMinutes;
  }

  int get _stepsForSession {
    if (_baselineSteps < 0) {
      return 0;
    }
    return math.max(0, _rawSteps - _baselineSteps);
  }

  double get _activeMinutes {
    if (_sessionStart == null) {
      return 0;
    }

    final active = _movingDuration + (_movingSince == null ? Duration.zero : DateTime.now().difference(_movingSince!));
    return active.inSeconds / 60;
  }

  double? get _paceMinutesPerKm {
    if (_distanceMeters < 10) {
      return null;
    }

    final activeMinutes = _activeMinutes;
    if (activeMinutes <= 0) {
      return null;
    }

    return activeMinutes / (_distanceMeters / 1000);
  }

  ActivitySnapshot _buildSnapshot(String label) {
    return ActivitySnapshot(
      isTracking: _tracking,
      activityLabel: label,
      steps: _stepsForSession,
      distanceMeters: _distanceMeters,
      elevationGainMeters: _elevationGainMeters,
      activeMinutes: _activeMinutes,
      paceMinutesPerKm: _paceMinutesPerKm,
      stepRateSpm: _stepRateSpm,
      lastUpdated: DateTime.now(),
    );
  }

  void _emit(ActivitySnapshot snapshot) {
    _snapshot = snapshot;
    if (!_controller.isClosed) {
      _controller.add(snapshot);
    }
  }

  void _schedulePersist() {
    if (!_tracking) {
      return;
    }

    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 5), _persistSnapshot);
  }

  Future<void> _persistSnapshot() async {
    if (!_tracking) {
      return;
    }

    final snapshot = _snapshot;
    final today = _dateKey(DateTime.now());
    await StorageService().addDailyLog(
      DailyLogModel(
        date: today,
        steps: snapshot.steps,
        distanceMeters: snapshot.distanceMeters,
        activeMinutes: snapshot.activeMinutes,
        elevationGainMeters: snapshot.elevationGainMeters,
        activityType: snapshot.activityLabel,
      ),
    );
  }

  String _dateKey(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}