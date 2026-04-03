import 'storage_service.dart';

class SettingsViewService {
  SettingsViewService._();

  static final StorageService _storage = StorageService();

  static bool get useMetricUnits {
    return (_storage.getAppSettings()['useMetricUnits'] as bool?) ?? true;
  }

  static double distanceDisplayValue(double meters) {
    if (useMetricUnits) return meters / 1000;
    return meters / 1609.344;
  }

  static String distanceUnitLabel() {
    return useMetricUnits ? 'km' : 'mi';
  }

  static String paceLabel(double? paceMinutesPerKm) {
    if (paceMinutesPerKm == null) return '--';
    if (useMetricUnits) return '${paceMinutesPerKm.toStringAsFixed(1)} min/km';
    final paceMinutesPerMile = paceMinutesPerKm * 1.609344;
    return '${paceMinutesPerMile.toStringAsFixed(1)} min/mi';
  }
}
