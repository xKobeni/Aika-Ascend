import '../models/user_model.dart';
import 'storage_service.dart';

/// Checks and unlocks achievements based on user state.
class AchievementService {
  final StorageService _storage = StorageService();

  /// Call after any state change. Returns list of newly unlocked achievement IDs.
  Future<List<String>> checkAll(UserModel user) async {
    final newly = <String>[];

    Future<void> check(String id, bool condition) async {
      if (!condition) return;
      final a = _storage.getAchievement(id);
      if (a != null && !a.unlocked) {
        await _storage.unlockAchievement(id);
        newly.add(id);
      }
    }

    await check('first_blood', user.totalQuestsCompleted >= 1);
    await check('path_chosen', user.isOnboarded);
    await check('iron_start', user.streak >= 3);
    await check('penalty_survivor', user.punishmentQuestsCompleted >= 1);
    await check('unbroken', user.streak >= 7);
    await check('centurion', user.level >= 10);
    await check('hundred_quests', user.totalQuestsCompleted >= 100);
    await check('boss_slayer', user.bossDefeatsTotal >= 1);
    await check('perfect_week', user.streak >= 7);
    await check('obsessed', user.streak >= 30);
    await check('shadow_monarch', user.level >= 50);
    // 'redeemed' is unlocked manually by quest_service when lock is cleared

    return newly;
  }

  /// Called when user clears a lockout.
  Future<void> unlockRedeemed() async =>
      _storage.unlockAchievement('redeemed');
}
