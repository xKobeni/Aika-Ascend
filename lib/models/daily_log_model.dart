import 'package:hive/hive.dart';
import '../core/constants.dart';

part 'daily_log_model.g.dart';

@HiveType(typeId: AppConstants.dailyLogModelTypeId)
class DailyLogModel extends HiveObject {
  @HiveField(0) String date;
  @HiveField(1) int expGained;
  @HiveField(2) int completedCount;
  @HiveField(3) int totalCount;
  @HiveField(4) double completionRate;
  @HiveField(5) int steps;
  @HiveField(6) double distanceMeters;
  @HiveField(7) double activeMinutes;
  @HiveField(8) double elevationGainMeters;
  @HiveField(9) String activityType;

  DailyLogModel({
    required this.date,
    this.expGained = 0,
    this.completedCount = 0,
    this.totalCount = 0,
    this.completionRate = 0.0,
    this.steps = 0,
    this.distanceMeters = 0.0,
    this.activeMinutes = 0.0,
    this.elevationGainMeters = 0.0,
    this.activityType = '',
  });

  DailyLogModel copyWith({
    String? date,
    int? expGained,
    int? completedCount,
    int? totalCount,
    double? completionRate,
    int? steps,
    double? distanceMeters,
    double? activeMinutes,
    double? elevationGainMeters,
    String? activityType,
  }) {
    return DailyLogModel(
      date: date ?? this.date,
      expGained: expGained ?? this.expGained,
      completedCount: completedCount ?? this.completedCount,
      totalCount: totalCount ?? this.totalCount,
      completionRate: completionRate ?? this.completionRate,
      steps: steps ?? this.steps,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      activityType: activityType ?? this.activityType,
    );
  }
}
