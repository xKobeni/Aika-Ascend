import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/constants.dart';

class ContentService {
  ContentService._();

  static final ContentService instance = ContentService._();

  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/game_content.json');
    _cache = jsonDecode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  List<Map<String, dynamic>> _list(String key, List<Map<String, dynamic>> fallback) {
    final src = _cache?[key];
    if (src is List) {
      return src.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return fallback;
  }

  Map<String, dynamic> _map(String key, Map<String, dynamic> fallback) {
    final src = _cache?[key];
    if (src is Map) {
      return Map<String, dynamic>.from(src);
    }
    return fallback;
  }

  String _string(String key, String fallback) {
    final src = _cache?[key];
    return src is String ? src : fallback;
  }

  List<Map<String, dynamic>> get strengthQuests =>
      _list('strength_quests', AppConstants.strengthQuests);

  List<Map<String, dynamic>> get cardioQuests =>
      _list('cardio_quests', AppConstants.cardioQuests);

  List<Map<String, dynamic>> get disciplineQuests =>
      _list('discipline_quests', AppConstants.disciplineQuests);

  List<Map<String, dynamic>> get punishmentQuests =>
      _list('punishment_quests', AppConstants.punishmentQuests);

  String get bossQuestTitle => _string('boss_quest_title', AppConstants.bossQuestTitle);

  List<Map<String, dynamic>> get titles => _list('titles', AppConstants.titles);

  List<Map<String, dynamic>> get skillPaths => _list('skill_paths', AppConstants.skillPaths);

  List<Map<String, dynamic>> get achievements =>
      _list('achievements', AppConstants.achievements);

  List<Map<String, dynamic>> get challengeCategories =>
      _list('challenge_categories', AppConstants.challengeCategories);

  List<Map<String, dynamic>> get bossChallenges =>
      _list('boss_challenges', AppConstants.bossChallenges);

  List<Map<String, dynamic>> get interactiveWorkouts =>
      _list('interactive_workouts', const []);

  Map<String, dynamic> get transformationChallenge {
    final src = _cache?['transformation_30_day'];
    if (src is Map) return Map<String, dynamic>.from(src);
    return {
      'title': '30-Day Transformation Challenge',
      'desc': 'Submit your current weight and progress photos.',
      'checkin_frequency': 'Daily',
      'required_fields': ['weight', 'photo'],
      'milestones': [7, 14, 21, 30],
    };
  }

  List<String> get dailyChallengePrompts {
    final src = _cache?['daily_challenge_prompts'];
    if (src is List) {
      return src.map((e) => e.toString()).toList();
    }
    return const [
      'Hit all planned sets today.',
      'Drink at least 2L of water.',
      'Take a progress photo and log your weight.',
    ];
  }

  Map<String, dynamic> get dailyMissionSystem => _map('daily_mission_system', {
    'title': 'SYSTEM DAILY QUEST',
    'subtitle': 'Complete all missions before midnight.',
    'failure': 'Failure will trigger a penalty quest.',
    'tiers': [
      {
        'id': 'beginner',
        'name': 'Beginner',
        'maxLevel': 4,
        'targetScale': 0.55,
        'quests': [
          {'title': 'Push-up Trial', 'baseTarget': 5, 'category': 'strength', 'isTimedQuest': false},
          {'title': 'Squat Trial', 'baseTarget': 10, 'category': 'strength', 'isTimedQuest': false},
          {'title': 'Walk Trial', 'baseTarget': 800, 'category': 'cardio', 'isTimedQuest': false},
          {'title': 'Plank Trial', 'baseTarget': 20, 'category': 'discipline', 'isTimedQuest': true},
        ],
      },
      {
        'id': 'standard',
        'name': 'Hunter',
        'maxLevel': 19,
        'targetScale': 1.0,
        'quests': [
          {'title': 'Push-up Trial', 'baseTarget': 12, 'category': 'strength', 'isTimedQuest': false},
          {'title': 'Squat Trial', 'baseTarget': 25, 'category': 'strength', 'isTimedQuest': false},
          {'title': 'Run Trial', 'baseTarget': 1500, 'category': 'cardio', 'isTimedQuest': false},
          {'title': 'Plank Trial', 'baseTarget': 45, 'category': 'discipline', 'isTimedQuest': true},
        ],
      },
      {
        'id': 'advanced',
        'name': 'Elite',
        'maxLevel': 999,
        'targetScale': 1.4,
        'quests': [
          {'title': 'Push-up Trial', 'baseTarget': 20, 'category': 'strength', 'isTimedQuest': false},
          {'title': 'Squat Trial', 'baseTarget': 40, 'category': 'strength', 'isTimedQuest': false},
          {'title': 'Run Trial', 'baseTarget': 3000, 'category': 'cardio', 'isTimedQuest': false},
          {'title': 'Plank Trial', 'baseTarget': 60, 'category': 'discipline', 'isTimedQuest': true},
        ],
      },
    ],
  });
}