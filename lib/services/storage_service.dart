import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/quest_model.dart';
import '../models/achievement_model.dart';
import '../models/daily_log_model.dart';
import '../core/constants.dart';
import 'content_service.dart';

class StorageService {
  late Box<UserModel> _userBox;
  late Box<QuestModel> _questBox;
  late Box<AchievementModel> _achievementBox;
  late Box<DailyLogModel> _dailyLogBox;
  late Box _challengeBox;
  final StreamController<void> _changeController = StreamController<void>.broadcast();
  final StreamController<void> _settingsChangeController = StreamController<void>.broadcast();

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Stream<void> get changes => _changeController.stream;
  Stream<void> get settingsChanges => _settingsChangeController.stream;

  void _notifyChange() {
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
  }

  void _notifySettingsChange() {
    if (!_settingsChangeController.isClosed) {
      _settingsChangeController.add(null);
    }
  }

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(AppConstants.userModelTypeId)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.questModelTypeId)) {
      Hive.registerAdapter(QuestModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.achievementModelTypeId)) {
      Hive.registerAdapter(AchievementModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.dailyLogModelTypeId)) {
      Hive.registerAdapter(DailyLogModelAdapter());
    }

    _userBox = await Hive.openBox<UserModel>(AppConstants.userBox);
    _questBox = await Hive.openBox<QuestModel>(AppConstants.questBox);
    _achievementBox = await Hive.openBox<AchievementModel>(AppConstants.achievementBox);
    _dailyLogBox = await Hive.openBox<DailyLogModel>(AppConstants.dailyLogBox);
    _challengeBox = await Hive.openBox(AppConstants.challengeBox);

    // Seed achievements if empty
    if (_achievementBox.isEmpty) {
      for (final a in ContentService.instance.achievements) {
        await _achievementBox.put(
          a['id'] as String,
          AchievementModel(id: a['id'] as String),
        );
      }
    }
  }

  // ── User ──────────────────────────────────────────────────────────────────
  UserModel getUser() {
    if (_userBox.isEmpty) {
      final u = UserModel();
      _userBox.put('user', u);
      return u;
    }
    return _userBox.get('user')!;
  }

  Future<void> saveUser(UserModel user) async {
    await _userBox.put('user', user);
    _notifyChange();
  }

  // ── Quests ────────────────────────────────────────────────────────────────
  List<QuestModel> getQuests() => _questBox.values.toList();

  Future<void> saveQuests(List<QuestModel> quests) async {
    await _questBox.clear();
    for (var i = 0; i < quests.length; i++) {
      await _questBox.put(i, quests[i]);
    }
    _notifyChange();
  }

  Future<void> updateQuest(int index, QuestModel quest) async =>
      _questBox.put(index, quest).then((_) => _notifyChange());

  // ── Achievements ──────────────────────────────────────────────────────────
  List<AchievementModel> getAchievements() => _achievementBox.values.toList();

  AchievementModel? getAchievement(String id) => _achievementBox.get(id);

  Future<void> unlockAchievement(String id) async {
    final a = _achievementBox.get(id);
    if (a != null && !a.unlocked) {
      final now = DateTime.now();
      a.unlocked = true;
      a.unlockedDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await _achievementBox.put(id, a);
      _notifyChange();
    }
  }

  // ── Daily Logs ────────────────────────────────────────────────────────────
  List<DailyLogModel> getDailyLogs() => _dailyLogBox.values.toList();

  Future<void> addDailyLog(DailyLogModel log) async {
    final existing = _dailyLogBox.get(log.date);
    if (existing == null) {
      await _dailyLogBox.put(log.date, log);
      _notifyChange();
      return;
    }

    await _dailyLogBox.put(log.date, _mergeDailyLogs(existing, log));
    _notifyChange();
  }

  DailyLogModel _mergeDailyLogs(DailyLogModel existing, DailyLogModel incoming) {
    return existing.copyWith(
      expGained: incoming.expGained != 0 ? incoming.expGained : existing.expGained,
      completedCount: incoming.completedCount != 0 ? incoming.completedCount : existing.completedCount,
      totalCount: incoming.totalCount != 0 ? incoming.totalCount : existing.totalCount,
      completionRate: incoming.completionRate != 0 ? incoming.completionRate : existing.completionRate,
      steps: incoming.steps != 0 ? incoming.steps : existing.steps,
      distanceMeters: incoming.distanceMeters != 0 ? incoming.distanceMeters : existing.distanceMeters,
      activeMinutes: incoming.activeMinutes != 0 ? incoming.activeMinutes : existing.activeMinutes,
      elevationGainMeters: incoming.elevationGainMeters != 0 ? incoming.elevationGainMeters : existing.elevationGainMeters,
      activityType: incoming.activityType.isNotEmpty ? incoming.activityType : existing.activityType,
    );
  }

  List<DailyLogModel> getLastNLogs(int n) {
    final logs = getDailyLogs();
    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs.take(n).toList().reversed.toList();
  }

  // ── 30-Day Transformation Challenge ─────────────────────────────────────
  Map<String, dynamic> getTransformation() {
    final data = _challengeBox.get('transformation');
    if (data is Map) return Map<String, dynamic>.from(data);
    return {
      'beforeWeight': null,
      'afterWeight': null,
      'beforeImagePath': '',
      'afterImagePath': '',
      'startDate': '',
      'endDate': '',
    };
  }

  Future<void> saveTransformation(Map<String, dynamic> value) async {
    await _challengeBox.put('transformation', value);
    _notifyChange();
  }

  List<Map<String, dynamic>> getChallengeCheckins() {
    final data = _challengeBox.get('checkins');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  Future<void> addChallengeCheckin(Map<String, dynamic> checkin) async {
    final logs = getChallengeCheckins();
    logs.add(checkin);
    await _challengeBox.put('checkins', logs);
    _notifyChange();
  }

  Map<String, dynamic> getBossRaidState() {
    final data = _challengeBox.get('bossRaid');
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {
      'active': false,
      'bossIndex': -1,
      'bossTitle': '',
      'bossDesc': '',
      'target': 0,
      'progress': 0,
      'expReward': 0,
      'completed': false,
      'startedDate': '',
      'completedDate': '',
    };
  }

  Future<void> saveBossRaidState(Map<String, dynamic> value) async {
    await _challengeBox.put('bossRaid', value);
    _notifyChange();
  }

  Future<void> clearBossRaidState() async {
    await _challengeBox.delete('bossRaid');
    _notifyChange();
  }

  // ── App Settings ─────────────────────────────────────────────────────────
  Map<String, dynamic> getAppSettings() {
    final data = _challengeBox.get('appSettings');
    if (data is Map) {
      final merged = Map<String, dynamic>.from(_defaultAppSettings())
        ..addAll(Map<String, dynamic>.from(data));
      return merged;
    }
    return _defaultAppSettings();
  }

  Future<void> saveAppSettings(Map<String, dynamic> value) async {
    await _challengeBox.put('appSettings', value);
    _notifySettingsChange();
    _notifyChange();
  }

  Future<void> updateAppSetting(String key, dynamic value) async {
    final settings = getAppSettings();
    settings[key] = value;
    await saveAppSettings(settings);
  }

  Map<String, dynamic> _defaultAppSettings() {
    return {
      'reminderMorningEnabled': true,
      'reminderMorningTime': '07:00',
      'reminderEveningEnabled': true,
      'reminderEveningTime': '20:00',
      'missedDayWarningEnabled': true,
      'lastMorningReminderDate': '',
      'lastEveningReminderDate': '',
      'lastMissedWarningDate': '',
      'quietHoursEnabled': false,
      'quietHoursStart': '22:00',
      'quietHoursEnd': '06:00',
      'punishmentIntensity': 'standard',
      'punishmentAllowedKinds': ['reps', 'timed', 'distance'],
      'punishmentHighImpactEnabled': true,
      'workoutFocus': 'any',
      'workoutSessionMinutes': 0,
      'equipmentMode': 'bodyweight',
      'trackerAutoStart': false,
      'trackerGpsMode': 'balanced',
      'trackerBackgroundEnabled': false,
      'trackerStepGoal': 8000,
      'trackerDistanceGoalKm': 5.0,
      'useMetricUnits': true,
      'use24HourTime': true,
      'weekStartsMonday': true,
      'notificationsEnabled': true,
      'popupMessagesEnabled': true,
      'soundEffectsEnabled': true,
      'vibrationEnabled': true,
      'offlineOnlyMode': true,
      'fontScale': 1.0,
      'highContrastMode': false,
      'reducedMotion': false,
      'compactCards': false,
      'adaptiveDifficultyEnabled': true,
      'confirmPathSwitch': true,
    };
  }
}
