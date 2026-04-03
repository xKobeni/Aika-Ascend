import 'package:hive/hive.dart';
import '../core/constants.dart';

part 'user_model.g.dart';

@HiveType(typeId: AppConstants.userModelTypeId)
class UserModel extends HiveObject {
  @HiveField(0) int level;
  @HiveField(1) int exp;
  @HiveField(2) int streak;
  @HiveField(3) String lastLoginDate;
  @HiveField(4) bool hasPendingPunishment;
  @HiveField(5) String hunterName;
  @HiveField(6) int skillPath;           // 0=Strength 1=Endurance 2=Discipline
  @HiveField(7) int titleId;
  @HiveField(8) int consecutiveMisses;
  @HiveField(9) double difficultyModifier;
  @HiveField(10) List<double> recentCompletionRates; // last 7 days
  @HiveField(11) int totalQuestsCompleted;
  @HiveField(12) int totalExpEarned;
  @HiveField(13) int bestStreak;
  @HiveField(14) bool restDayUsedThisWeek;
  @HiveField(15) bool bossDefeatedThisWeek;
  @HiveField(16) int lastBossWeekYear;
  @HiveField(17) int lastBossWeekNum;
  @HiveField(18) bool isLocked;
  @HiveField(19) bool isOnboarded;
  @HiveField(20) bool doubleExpToday;
  @HiveField(21) int punishmentQuestsCompleted;
  @HiveField(22) int bossDefeatsTotal;

  UserModel({
    this.level = 1,
    this.exp = 0,
    this.streak = 0,
    this.lastLoginDate = '',
    this.hasPendingPunishment = false,
    this.hunterName = '',
    this.skillPath = 0,
    this.titleId = 0,
    this.consecutiveMisses = 0,
    this.difficultyModifier = 0.0,
    List<double>? recentCompletionRates,
    this.totalQuestsCompleted = 0,
    this.totalExpEarned = 0,
    this.bestStreak = 0,
    this.restDayUsedThisWeek = false,
    this.bossDefeatedThisWeek = false,
    this.lastBossWeekYear = 0,
    this.lastBossWeekNum = 0,
    this.isLocked = false,
    this.isOnboarded = false,
    this.doubleExpToday = false,
    this.punishmentQuestsCompleted = 0,
    this.bossDefeatsTotal = 0,
  }) : recentCompletionRates = recentCompletionRates ?? [];
}
