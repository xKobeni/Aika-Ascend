import '../models/user_model.dart';

/// Generates context-aware system messages based on user behaviour.
class BehaviorService {
  String generateMessage(UserModel user) {
    // Negative states take priority
    if (user.isLocked) {
      return '> SYSTEM LOCKOUT ACTIVE.\n> Complete the redemption quest to restore access.';
    }
    if (user.consecutiveMisses >= 4) {
      return '> Warning. You are getting weaker.\n> ${user.hunterName.isEmpty ? "Hunter" : user.hunterName}, the System does not wait for the fallen.';
    }
    if (user.consecutiveMisses >= 2) {
      return '> Your consistency is declining.\n> Two failures logged. Do not make it three.';
    }
    if (user.titleId == 11) {
      return '> Designation reassigned: FAILURE.\n> Redemption requires immediate action.';
    }

    // Positive / neutral states
    if (user.streak >= 30) {
      return '> 30-day streak confirmed.\n> ${user.hunterName.isEmpty ? "Hunter" : user.hunterName}. You are becoming something different.';
    }
    if (user.streak >= 14) {
      return '> Exceptional. 14 days without failure.\n> The System acknowledges your unwavering discipline.';
    }
    if (user.streak >= 7) {
      return '> 7-day streak active.\n> Your consistency is becoming a force of nature.';
    }
    if (user.difficultyModifier >= 0.3) {
      return '> You are improving rapidly.\n> Difficulty has been escalated. The System respects the strong.';
    }
    if (user.bossDefeatsTotal >= 1) {
      return '> Boss raid cleared. You are feared.\n> Continue on your path, ${user.hunterName.isEmpty ? "Hunter" : user.hunterName}.';
    }
    if (user.streak >= 3) {
      return '> 3-day streak. Showing promise.\n> Do not let momentum die here.';
    }
    if (user.level >= 10) {
      return '> Level ${user.level} achieved.\n> ${user.hunterName.isEmpty ? "Hunter" : user.hunterName}, you have surpassed most who started this path.';
    }
    if (user.totalQuestsCompleted == 0) {
      return '> System online.\n> Your first mission awaits. Begin.';
    }

    return '> System monitoring active.\n> Complete all daily missions before midnight.';
  }
}
