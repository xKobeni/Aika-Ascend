import 'package:hive/hive.dart';
import '../core/constants.dart';

part 'quest_model.g.dart';

@HiveType(typeId: AppConstants.questModelTypeId)
class QuestModel extends HiveObject {
  @HiveField(0) String title;
  @HiveField(1) int target;
  @HiveField(2) int progress;
  @HiveField(3) bool completed;
  @HiveField(4) bool isPunishment;
  @HiveField(5) String category;     // 'strength' | 'cardio' | 'discipline'
  @HiveField(6) String difficulty;   // 'normal' | 'hard' | 'extreme' | 'boss' | 'punishment'
  @HiveField(7) bool isTimedQuest;
  @HiveField(8) bool isBossQuest;
  @HiveField(9) bool isRandomEvent;
  @HiveField(10) String eventType;   // '' | 'bonus' | 'double_exp' | 'malfunction'
  @HiveField(11) int expReward;

  QuestModel({
    required this.title,
    required this.target,
    this.progress = 0,
    this.completed = false,
    this.isPunishment = false,
    this.category = 'strength',
    this.difficulty = 'normal',
    this.isTimedQuest = false,
    this.isBossQuest = false,
    this.isRandomEvent = false,
    this.eventType = '',
    this.expReward = AppConstants.baseExpPerQuest,
  });

  double get completionRatio =>
      target == 0 ? 1.0 : (progress / target).clamp(0.0, 1.0);
}
