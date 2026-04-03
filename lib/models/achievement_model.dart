import 'package:hive/hive.dart';
import '../core/constants.dart';

part 'achievement_model.g.dart';

@HiveType(typeId: AppConstants.achievementModelTypeId)
class AchievementModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) bool unlocked;
  @HiveField(2) String unlockedDate;

  AchievementModel({
    required this.id,
    this.unlocked = false,
    this.unlockedDate = '',
  });
}
