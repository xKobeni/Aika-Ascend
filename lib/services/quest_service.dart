import 'dart:math';
import '../models/quest_model.dart';
import '../models/user_model.dart';
import '../models/daily_log_model.dart';
import '../core/constants.dart';
import 'storage_service.dart';
import 'adaptive_service.dart';
import 'title_service.dart';
import 'achievement_service.dart';
import 'content_service.dart';

class QuestService {
  final StorageService _storage = StorageService();
  final AdaptiveService _adaptive = AdaptiveService();
  final TitleService _titleSvc = TitleService();
  final AchievementService _achieveSvc = AchievementService();
  final ContentService _content = ContentService.instance;
  final Random _rng = Random();

  // ── Difficulty multiplier ──────────────────────────────────────────────────
  double _multiplier(UserModel user) {
    final base = 1.0 + ((user.level - 1) * 0.04);
    return (base + user.difficultyModifier).clamp(0.7, 4.0);
  }

  Map<String, dynamic> _dailySystem() => _content.dailyMissionSystem;

  List<Map<String, dynamic>> _legacyDailyPool(int skillPath) {
    final strength = List<Map<String, dynamic>>.from(_content.strengthQuests)..shuffle();
    final cardio = List<Map<String, dynamic>>.from(_content.cardioQuests)..shuffle();
    final discipline = List<Map<String, dynamic>>.from(_content.disciplineQuests)..shuffle();

    switch (skillPath) {
      case 0:
        return [strength[0], strength[1], cardio[0]];
      case 1:
        return [cardio[0], cardio[1], strength[0]];
      case 2:
        return [discipline[0], strength[0], cardio[0]];
      default:
        return [strength[0], cardio[0], discipline[0]];
    }
  }

  List<Map<String, dynamic>> _dailyTierQuests(UserModel user) {
    final system = _dailySystem();
    final tiers = system['tiers'];
    if (tiers is! List || tiers.isEmpty) {
      return _legacyDailyPool(user.skillPath);
    }

    final normalizedTiers = tiers
        .whereType<Map>()
        .map((tier) => Map<String, dynamic>.from(tier))
        .toList();
    normalizedTiers.sort((a, b) {
      final aLevel = (a['maxLevel'] as num?)?.toInt() ?? 0;
      final bLevel = (b['maxLevel'] as num?)?.toInt() ?? 0;
      return aLevel.compareTo(bLevel);
    });

    final matchedTier = normalizedTiers.firstWhere(
      (tier) {
        final maxLevel = (tier['maxLevel'] as num?)?.toInt() ?? 0;
        return user.level <= maxLevel;
      },
      orElse: () => normalizedTiers.last,
    );

    final quests = matchedTier['quests'];
    if (quests is! List || quests.isEmpty) {
      return _legacyDailyPool(user.skillPath);
    }

    return quests.whereType<Map>().map((quest) => Map<String, dynamic>.from(quest)).toList();
  }

  // ── EXP reward with path bonuses ──────────────────────────────────────────
  int _calcExp(UserModel user, QuestModel quest) {
    int base = AppConstants.baseExpPerQuest;
    if (quest.isBossQuest) return AppConstants.bossExpReward;
    if (quest.eventType == 'bonus') base = AppConstants.bonusQuestExp;

    // Skill path bonuses
    if (user.skillPath == 0 && quest.category == 'strength') {
      base = (base * 1.15).round(); // +15% for Strength path
    } else if (user.skillPath == 2) {
      base = (base * 1.25).round(); // +25% Discipline path all quests
    }

    // Double EXP event
    if (user.doubleExpToday) base *= 2;

    return base;
  }

  // ── Generate daily quests ─────────────────────────────────────────────────
  List<QuestModel> generateDailyQuests(UserModel user) {
    final multi = _multiplier(user);
    final pool = _dailyTierQuests(user);
    final quests = <QuestModel>[];
    final system = _dailySystem();
    final tiers = system['tiers'];
    final normalizedTiers = tiers is List
        ? tiers.whereType<Map>().map((tier) => Map<String, dynamic>.from(tier)).toList()
        : <Map<String, dynamic>>[];
    final matchedTier = normalizedTiers.firstWhere(
      (tier) {
        final maxLevel = (tier['maxLevel'] as num?)?.toInt() ?? 0;
        return user.level <= maxLevel;
      },
      orElse: () => {'name': 'Hunter', 'targetScale': 1.0},
    );
    final scale = ((matchedTier['targetScale'] as num?)?.toDouble() ?? 1.0) * multi;

    for (final q in pool) {
      final rawTarget = (q['baseTarget'] as num?)?.toDouble() ?? 0;
      int target = (rawTarget * scale).round();
      final category = q['category'] as String;
      final isTimedQuest = q['isTimedQuest'] as bool;

      // Determine difficulty label
      String diff = (matchedTier['id'] as String?) ?? 'normal';
      if (multi >= 1.5 && multi < 2.0) diff = 'hard';
      if (multi >= 2.0) diff = 'extreme';

      final quest = QuestModel(
        title: q['title'] as String,
        target: target,
        category: category,
        difficulty: diff,
        isTimedQuest: isTimedQuest,
      );
      quest.expReward = _calcExp(user, quest);
      quests.add(quest);
    }

    return quests;
  }

  // ── Boss quest (every Sunday) ──────────────────────────────────────────────
  QuestModel? _tryGenerateBossQuest(UserModel user) {
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return null;

    // Check if already defeated this week
    final currentWeek = _isoWeek(now);
    if (user.bossDefeatedThisWeek &&
        user.lastBossWeekYear == now.year &&
        user.lastBossWeekNum == currentWeek) {
      return null;
    }

    // Boss target scales with level
    final target = (user.level + 4) * 20;
    return QuestModel(
      title: _content.bossQuestTitle,
      target: target,
      category: 'strength',
      difficulty: 'boss',
      isBossQuest: true,
      expReward: AppConstants.bossExpReward,
    );
  }

  // ── Random event (10% chance) ──────────────────────────────────────────────
  String? _rollRandomEvent(List<QuestModel> quests) {
    if (_rng.nextDouble() > 0.10) return null;
    final events = ['bonus', 'double_exp', 'malfunction'];
    return events[_rng.nextInt(events.length)];
  }

  void _applyRandomEvent(String event, List<QuestModel> quests, UserModel user) {
    switch (event) {
      case 'bonus':
        // Add a bonus quest
        final pool = List<Map<String, dynamic>>.from(_content.cardioQuests)..shuffle();
        final q = pool.first;
        quests.add(QuestModel(
          title: '[BONUS] ${q['title']}',
          target: ((q['baseTarget'] as int) * _multiplier(user)).round(),
          category: 'cardio',
          difficulty: 'normal',
          isTimedQuest: q['isTimedQuest'] as bool,
          isRandomEvent: true,
          eventType: 'bonus',
          expReward: AppConstants.bonusQuestExp,
        ));
        break;
      case 'double_exp':
        user.doubleExpToday = true;
        for (final q in quests) {
          q.isRandomEvent = true;
          q.eventType = 'double_exp';
          q.expReward = q.expReward * 2;
        }
        break;
      case 'malfunction':
        // Make one random quest 30% harder
        if (quests.isNotEmpty) {
          final idx = _rng.nextInt(quests.length);
          quests[idx].target = (quests[idx].target * 1.3).round();
          quests[idx].isRandomEvent = true;
          quests[idx].eventType = 'malfunction';
          quests[idx].difficulty = 'extreme';
        }
        break;
    }
  }

  // ── Punishment quest ───────────────────────────────────────────────────────
  QuestModel _generatePunishment(UserModel user) {
    final pool = List<Map<String, dynamic>>.from(_content.punishmentQuests)..shuffle();
    final q = pool.first;
    double multi = _multiplier(user) * 1.5;
    if (user.skillPath == 2) multi *= 1.5; // Discipline path extra harsh

    return QuestModel(
      title: q['title'] as String,
      target: ((q['baseTarget'] as int) * multi).round(),
      category: q['category'] as String,
      difficulty: 'punishment',
      isPunishment: true,
      isTimedQuest: q['isTimedQuest'] as bool,
      expReward: AppConstants.baseExpPerQuest,
    );
  }

  // ── Main daily check ───────────────────────────────────────────────────────
  Future<DailyCheckResult> runDailyCheck() async {
    final user = _storage.getUser();
    final today = _todayStr();
    final quests = _storage.getQuests();
    final isNewDay = user.lastLoginDate != today;

    if (!isNewDay) {
      return DailyCheckResult(
        quests: quests, isNewDay: false,
        hadPunishment: false, leveledUp: false,
        hadBoss: false, randomEvent: '',
        newlyUnlocked: [],
      );
    }

    bool hadPunishment = false;
    bool leveledUp = false;
    String randomEvent = '';

    // ── Evaluate yesterday ────────────────────────────────────────────────
    if (quests.isNotEmpty) {
      final completed = quests.where((q) => q.completed).length;
      final rate = completed / quests.length;
      await _adaptive.recordDay(rate);

      if (rate >= 1.0) {
        // Full completion
        user.consecutiveMisses = 0;
        user.streak++;
        if (user.streak > user.bestStreak) user.bestStreak = user.streak;

        int expGained = 0;
        for (final q in quests) {
          if (q.completed) expGained += q.expReward;
        }

        // Streak bonus (Endurance path = 2×)
        int streakBonus = AppConstants.streakBonusExp * (user.streak > 1 ? 1 : 0);
        if (user.skillPath == 1) streakBonus *= 2;
        expGained += streakBonus;

        user.exp += expGained;
        user.totalExpEarned += expGained;
        user.hasPendingPunishment = false;
        user.isLocked = false;
      } else {
        // Failed day
        user.streak = 0;
        user.consecutiveMisses++;
        user.hasPendingPunishment = true;

        // Regression: EXP loss (Option A)
        if (user.consecutiveMisses == 2) {
          final loss = (user.exp * AppConstants.regressionMiss2Pct / 100).round();
          user.exp = (user.exp - loss).clamp(0, 999999);
        } else if (user.consecutiveMisses >= 4) {
          final loss = (user.exp * AppConstants.regressionMiss4Pct / 100).round();
          user.exp = (user.exp - loss).clamp(0, 999999);
        }

        // Lock system
        if (user.consecutiveMisses >= AppConstants.lockThreshold) {
          user.isLocked = true;
        }
      }

      // Level up check
      while (user.exp >= AppConstants.expToLevelUp(user.level)) {
        user.exp -= AppConstants.expToLevelUp(user.level);
        user.level++;
        leveledUp = true;
      }

      // Log this day
      await _storage.addDailyLog(DailyLogModel(
        date: user.lastLoginDate,
        expGained: quests.where((q) => q.completed).fold(0, (sum, q) => sum + q.expReward),
        completedCount: completed,
        totalCount: quests.length,
        completionRate: rate,
      ));

      await _storage.saveUser(user);
    }

    // ── Generate new quests ───────────────────────────────────────────────
    user.doubleExpToday = false;
    final newQuests = <QuestModel>[];

    // Punishment first
    if (user.hasPendingPunishment) {
      newQuests.add(_generatePunishment(user));
      user.hasPendingPunishment = false;
      hadPunishment = true;
    }

    // Boss quest (Sunday check)
    final bossQuest = _tryGenerateBossQuest(user);
    final hadBoss = bossQuest != null;
    if (bossQuest != null) newQuests.insert(0, bossQuest);

    // Regular daily quests
    newQuests.addAll(generateDailyQuests(user));

    // Random event
    final event = _rollRandomEvent(newQuests);
    if (event != null) {
      _applyRandomEvent(event, newQuests, user);
      randomEvent = event;
    }

    // Update title
    user.titleId = _titleSvc.evaluateTitle(user);

    // Save
    user.lastLoginDate = today;
    await _storage.saveUser(user);
    await _storage.saveQuests(newQuests);

    // Check achievements
    final newlyUnlocked = await _achieveSvc.checkAll(user);

    return DailyCheckResult(
      quests: newQuests,
      isNewDay: true,
      hadPunishment: hadPunishment,
      leveledUp: leveledUp,
      hadBoss: hadBoss,
      randomEvent: randomEvent,
      newlyUnlocked: newlyUnlocked,
    );
  }

  // ── Complete a quest ───────────────────────────────────────────────────────
  Future<CompleteQuestResult> completeQuest(int index) async {
    final quests = _storage.getQuests();
    final user = _storage.getUser();

    if (index < 0 || index >= quests.length) {
      return CompleteQuestResult(leveledUp: false, allCompleted: false, newlyUnlocked: []);
    }
    final quest = quests[index];
    if (quest.completed) {
      return CompleteQuestResult(leveledUp: false, allCompleted: false, newlyUnlocked: []);
    }

    quest.progress = quest.target;
    quest.completed = true;
    await _storage.updateQuest(index, quest);

    // Award EXP
    user.exp += quest.expReward;
    user.totalExpEarned += quest.expReward;
    user.totalQuestsCompleted++;

    if (quest.isPunishment) user.punishmentQuestsCompleted++;

    if (quest.isBossQuest) {
      user.bossDefeatsTotal++;
      user.bossDefeatedThisWeek = true;
      final now = DateTime.now();
      user.lastBossWeekYear = now.year;
      user.lastBossWeekNum = _isoWeek(now);
    }

    // Level up
    bool leveledUp = false;
    while (user.exp >= AppConstants.expToLevelUp(user.level)) {
      user.exp -= AppConstants.expToLevelUp(user.level);
      user.level++;
      leveledUp = true;
    }

    // Update title
    user.titleId = _titleSvc.evaluateTitle(user);
    await _storage.saveUser(user);

    final freshQuests = _storage.getQuests();
    final allCompleted = freshQuests.every((q) => q.completed);

    // Check achievements
    final newlyUnlocked = await _achieveSvc.checkAll(user);

    return CompleteQuestResult(
      leveledUp: leveledUp,
      allCompleted: allCompleted,
      newlyUnlocked: newlyUnlocked,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  int _isoWeek(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}

// ── Result objects ─────────────────────────────────────────────────────────
class DailyCheckResult {
  final List<QuestModel> quests;
  final bool isNewDay;
  final bool hadPunishment;
  final bool leveledUp;
  final bool hadBoss;
  final String randomEvent;
  final List<String> newlyUnlocked;

  DailyCheckResult({
    required this.quests,
    required this.isNewDay,
    required this.hadPunishment,
    required this.leveledUp,
    required this.hadBoss,
    required this.randomEvent,
    required this.newlyUnlocked,
  });
}

class CompleteQuestResult {
  final bool leveledUp;
  final bool allCompleted;
  final List<String> newlyUnlocked;

  CompleteQuestResult({
    required this.leveledUp,
    required this.allCompleted,
    required this.newlyUnlocked,
  });
}
