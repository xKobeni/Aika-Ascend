import '../models/user_model.dart';
import 'storage_service.dart';

/// Tracks completion rates and adjusts the user's difficulty modifier.
class AdaptiveService {
  final StorageService _storage = StorageService();

  /// Call this at the end of each day with that day's completion rate.
  Future<void> recordDay(double completionRate) async {
    final user = _storage.getUser();

    final rates = List<double>.from(user.recentCompletionRates);
    rates.add(completionRate);
    if (rates.length > 7) rates.removeAt(0); // keep last 7 days
    user.recentCompletionRates = rates;

    // Recalculate modifier based on last 3 days average
    if (rates.length >= 3) {
      final last3 = rates.sublist(rates.length - 3);
      final avg = last3.reduce((a, b) => a + b) / last3.length;

      if (avg > 0.9) {
        // Too easy → increase difficulty
        user.difficultyModifier =
            (user.difficultyModifier + 0.10).clamp(-0.3, 0.5);
      } else if (avg < 0.5) {
        // Too hard → reduce difficulty slightly
        user.difficultyModifier =
            (user.difficultyModifier - 0.05).clamp(-0.3, 0.5);
      }
    }
    await _storage.saveUser(user);
  }

  /// Returns the behavior label reflecting adaptive state.
  String adaptiveStatusMessage(UserModel user) {
    if (user.difficultyModifier >= 0.3) {
      return 'Difficulty: EXTREME [ADAPTIVE+]';
    } else if (user.difficultyModifier >= 0.1) {
      return 'Difficulty: HARD [ADAPTIVE+]';
    } else if (user.difficultyModifier <= -0.2) {
      return 'Difficulty: REDUCED [ADAPTIVE-]';
    }
    return 'Difficulty: STANDARD';
  }
}
