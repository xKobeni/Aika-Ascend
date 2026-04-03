import '../models/user_model.dart';
import 'content_service.dart';

/// Evaluates which title the user should currently display.
class TitleService {
  final ContentService _content = ContentService.instance;

  /// Returns the best matching titleId based on user state.
  int evaluateTitle(UserModel user) {
    int titleId = 0; // 'Awakened' default

    // Streak-based titles (lower priority)
    if (user.streak >= 3) titleId = 1;  // Disciplined
    if (user.streak >= 7) titleId = 2;  // Iron Will
    if (user.streak >= 14) titleId = 3; // Unbreakable
    if (user.streak >= 30) titleId = 4; // Obsessed

    // Level-based titles
    if (user.level >= 20) titleId = 5; // Ascendant

    // Achievement titles (higher priority)
    if (user.bossDefeatsTotal >= 1) titleId = 6; // Dragon Slayer
    if (user.punishmentQuestsCompleted >= 5) titleId = 7; // Survivor

    // Highest level titles
    if (user.level >= 50) titleId = 9;                              // Warlord
    if (user.level >= 50 && user.bossDefeatsTotal >= 1) titleId = 10; // Shadow Monarch

    // Negative title overrides positive ones when active
    // 'Failure' is only shown when actively in 3+ miss state
    if (user.consecutiveMisses >= 3 && user.streak == 0) titleId = 11;

    return titleId;
  }

  String titleName(int id) {
    final titles = _content.titles;
    if (id < 0 || id >= titles.length) return 'Awakened';
    return titles[id]['name'] as String;
  }

  String titleDesc(int id) {
    final titles = _content.titles;
    if (id < 0 || id >= titles.length) return '';
    return titles[id]['desc'] as String;
  }
}
