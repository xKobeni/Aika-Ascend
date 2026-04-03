class AppConstants {
  // ── Hive Box Names ──────────────────────────────────────────────────────────
  static const String userBox = 'user_box';
  static const String questBox = 'quest_box';
  static const String achievementBox = 'achievement_box';
  static const String dailyLogBox = 'daily_log_box';
  static const String challengeBox = 'challenge_box';

  // ── Hive Type IDs ───────────────────────────────────────────────────────────
  static const int userModelTypeId = 0;
  static const int questModelTypeId = 1;
  static const int achievementModelTypeId = 2;
  static const int dailyLogModelTypeId = 3;

  // ── EXP & Level ─────────────────────────────────────────────────────────────
  static const int baseExpPerQuest = 30;
  static const int streakBonusExp = 10;
  static const int bossExpReward = 300;
  static const int bonusQuestExp = 50;
  static const int skillPathChangePenalty = 50;
  static int expToLevelUp(int level) => level * 100;

  // ── Regression (Option A: EXP loss only) ────────────────────────────────────
  static const int regressionMiss2Pct = 20; // % exp lost at 2 consecutive misses
  static const int regressionMiss4Pct = 40; // % exp lost at 4 consecutive misses
  static const int lockThreshold = 5;       // misses before system lock

  // ── Quest Pool ──────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> strengthQuests = [
    {'title': 'Push-ups', 'baseTarget': 20, 'category': 'strength', 'isTimedQuest': false},
    {'title': 'Diamond Push-ups', 'baseTarget': 15, 'category': 'strength', 'isTimedQuest': false},
    {'title': 'Squats', 'baseTarget': 30, 'category': 'strength', 'isTimedQuest': false},
    {'title': 'Lunges', 'baseTarget': 20, 'category': 'strength', 'isTimedQuest': false},
    {'title': 'Sit-ups', 'baseTarget': 25, 'category': 'strength', 'isTimedQuest': false},
    {'title': 'Dips', 'baseTarget': 15, 'category': 'strength', 'isTimedQuest': false},
    {'title': 'Pike Push-ups', 'baseTarget': 12, 'category': 'strength', 'isTimedQuest': false},
  ];

  static const List<Map<String, dynamic>> cardioQuests = [
    {'title': 'Jumping Jacks', 'baseTarget': 40, 'category': 'cardio', 'isTimedQuest': false},
    {'title': 'Mountain Climbers', 'baseTarget': 30, 'category': 'cardio', 'isTimedQuest': false},
    {'title': 'High Knees', 'baseTarget': 50, 'category': 'cardio', 'isTimedQuest': false},
    {'title': 'Burpees', 'baseTarget': 15, 'category': 'cardio', 'isTimedQuest': false},
    {'title': 'Jump Rope', 'baseTarget': 60, 'category': 'cardio', 'isTimedQuest': false},
    {'title': 'Box Step-ups', 'baseTarget': 20, 'category': 'cardio', 'isTimedQuest': false},
  ];

  static const List<Map<String, dynamic>> disciplineQuests = [
    {'title': 'Plank Hold', 'baseTarget': 60, 'category': 'discipline', 'isTimedQuest': true},
    {'title': 'Wall Sit', 'baseTarget': 45, 'category': 'discipline', 'isTimedQuest': true},
    {'title': 'Dead Hang', 'baseTarget': 30, 'category': 'discipline', 'isTimedQuest': true},
    {'title': 'L-Sit Hold', 'baseTarget': 20, 'category': 'discipline', 'isTimedQuest': true},
  ];

  // ── Punishment Quests ────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> punishmentQuests = [
    {'title': 'Punishment: Burpee Gauntlet', 'baseTarget': 30, 'category': 'cardio', 'isTimedQuest': false},
    {'title': 'Punishment: Squat Hold', 'baseTarget': 90, 'category': 'discipline', 'isTimedQuest': true},
    {'title': 'Punishment: Push-up Grind', 'baseTarget': 40, 'category': 'strength', 'isTimedQuest': false},
  ];

  // ── Boss Quest ───────────────────────────────────────────────────────────────
  // Boss target = (level + 4) * 20 computed in QuestService
  static const String bossQuestTitle = 'BOSS RAID: Total Annihilation';

  // ── Titles ───────────────────────────────────────────────────────────────────
  // Priority: higher id = higher priority (evaluated in order, last match wins)
  static const List<Map<String, dynamic>> titles = [
    {'id': 0, 'name': 'Awakened', 'desc': 'Your journey begins.'},
    {'id': 1, 'name': 'Disciplined', 'desc': '3-day streak achieved.'},
    {'id': 2, 'name': 'Iron Will', 'desc': '7-day streak achieved.'},
    {'id': 3, 'name': 'Unbreakable', 'desc': '14-day streak achieved.'},
    {'id': 4, 'name': 'Obsessed', 'desc': '30-day streak achieved.'},
    {'id': 5, 'name': 'Ascendant', 'desc': 'Reached Level 20.'},
    {'id': 6, 'name': 'Dragon Slayer', 'desc': 'Defeated a Boss raid.'},
    {'id': 7, 'name': 'Survivor', 'desc': 'Completed 5 punishment quests.'},
    {'id': 8, 'name': 'Redeemed', 'desc': 'Recovered from failure.'},
    {'id': 9, 'name': 'Warlord', 'desc': 'Reached Level 50.'},
    {'id': 10, 'name': 'Shadow Monarch', 'desc': 'Reached Level 50 and defeated a Boss.'},
    {'id': 11, 'name': 'Failure', 'desc': '3+ consecutive missed days.'},
  ];

  // ── Skill Paths ──────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> skillPaths = [
    {
      'id': 0, 'name': 'Strength', 'badge': 'STR',
      'desc': 'Raw power. More resistance training, heavier loads.',
      'bonus': '+15% EXP from strength quests',
    },
    {
      'id': 1, 'name': 'Endurance', 'badge': 'END',
      'desc': 'Stamina and cardio dominance. Streak bonuses doubled.',
      'bonus': '2× streak bonus EXP',
    },
    {
      'id': 2, 'name': 'Discipline', 'badge': 'DIS',
      'desc': 'The hardest path. Severe punishments, maximum rewards.',
      'bonus': '+25% EXP all quests',
    },
  ];

  // ── Challenges ─────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> challengeCategories = [
    {
      'id': 'strength',
      'name': 'Strength Trials',
      'badge': 'STR',
      'color': 'crimson',
      'items': ['Push-ups', 'Dips', 'Squats', 'Lunges', 'Pike Push-ups'],
    },
    {
      'id': 'cardio',
      'name': 'Endurance Trials',
      'badge': 'END',
      'color': 'cyan',
      'items': ['Burpees', 'Jump Rope', 'Mountain Climbers', 'High Knees', 'Jumping Jacks'],
    },
    {
      'id': 'discipline',
      'name': 'Discipline Trials',
      'badge': 'DIS',
      'color': 'violet',
      'items': ['Plank Hold', 'Wall Sit', 'Dead Hang', 'L-Sit Hold'],
    },
  ];

  static const List<Map<String, dynamic>> bossChallenges = [
    {
      'title': 'Boss Raid I: Shadow Beast',
      'desc': 'Complete 3 trials in a row without skipping a set.',
      'difficulty': 'BOSS',
      'target': 3,
      'exp': 300,
    },
    {
      'title': 'Boss Raid II: Iron Monarch',
      'desc': 'Finish a full strength + cardio circuit.',
      'difficulty': 'BOSS',
      'target': 1,
      'exp': 450,
    },
    {
      'title': 'Boss Raid III: Final Gate',
      'desc': 'Clear the week with zero missed days.',
      'difficulty': 'BOSS',
      'target': 7,
      'exp': 600,
    },
  ];

  // ── Achievements ─────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> achievements = [
    {'id': 'first_blood', 'title': 'First Blood', 'desc': 'Complete your first quest.', 'rarity': 'common'},
    {'id': 'path_chosen', 'title': 'Path Chosen', 'desc': 'Select your skill path.', 'rarity': 'common'},
    {'id': 'iron_start', 'title': 'Iron Start', 'desc': 'Achieve a 3-day streak.', 'rarity': 'common'},
    {'id': 'penalty_survivor', 'title': 'Penalty Survivor', 'desc': 'Complete a punishment quest.', 'rarity': 'uncommon'},
    {'id': 'unbroken', 'title': 'Unbroken', 'desc': 'Achieve a 7-day streak.', 'rarity': 'rare'},
    {'id': 'centurion', 'title': 'Centurion', 'desc': 'Reach Level 10.', 'rarity': 'rare'},
    {'id': 'hundred_quests', 'title': 'Quest Master', 'desc': 'Complete 100 total quests.', 'rarity': 'rare'},
    {'id': 'boss_slayer', 'title': 'Boss Slayer', 'desc': 'Defeat your first Boss raid.', 'rarity': 'epic'},
    {'id': 'perfect_week', 'title': 'Perfect Week', 'desc': '7 consecutive days fully completed.', 'rarity': 'epic'},
    {'id': 'redeemed', 'title': 'Redeemed', 'desc': 'Clear the system lockout.', 'rarity': 'rare'},
    {'id': 'obsessed', 'title': 'Obsessed', 'desc': 'Achieve a 30-day streak.', 'rarity': 'legendary'},
    {'id': 'shadow_monarch', 'title': 'Shadow Monarch', 'desc': 'Reach Level 50.', 'rarity': 'legendary'},
  ];

  // ── Rank Labels by Level ─────────────────────────────────────────────────────
  static String rankLabel(int level) {
    if (level < 5) return 'E-Rank Hunter';
    if (level < 10) return 'D-Rank Hunter';
    if (level < 20) return 'C-Rank Hunter';
    if (level < 35) return 'B-Rank Hunter';
    if (level < 50) return 'A-Rank Hunter';
    return 'S-Rank Hunter';
  }
}
