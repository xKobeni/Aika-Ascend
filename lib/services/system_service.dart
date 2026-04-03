import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/constants.dart';
import 'content_service.dart';

enum SystemMessageType { success, failure, levelUp, punishment, info, achievement, boss, event }

class SystemService {
  // ── Shared animated dialog ──────────────────────────────────────────────
  static Future<void> show(
    BuildContext context, {
    required SystemMessageType type,
    required String title,
    required String message,
    String? subMessage,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) => _SystemDialog(
        type: type, title: title, message: message, subMessage: subMessage,
      ),
    );
  }

  // ── Convenience methods ─────────────────────────────────────────────────
  static Future<void> questCompleted(BuildContext context, int expReward) =>
      show(context,
        type: SystemMessageType.success,
        title: '[ QUEST COMPLETED ]',
        message: 'You have grown stronger.',
        subMessage: '+$expReward EXP awarded.',
      );

  static Future<void> allQuestsCompleted(BuildContext context) =>
      show(context,
        type: SystemMessageType.success,
        title: '[ DAILY MISSION COMPLETE ]',
        message: 'Outstanding performance, Hunter.',
        subMessage: 'Streak bonus applied.',
      );

  static Future<void> questFailed(BuildContext context) =>
      show(context,
        type: SystemMessageType.failure,
        title: '[ MISSION FAILED ]',
        message: 'You failed your mission.',
        subMessage: 'Penalty has been assigned.',
      );

  static Future<void> punishmentAssigned(BuildContext context) =>
      show(context,
        type: SystemMessageType.punishment,
        title: '[ PENALTY ACTIVATED ]',
        message: 'The System does not forgive.',
        subMessage: 'Complete the punishment quest to continue.',
      );

  static Future<void> levelUp(BuildContext context, int newLevel) =>
      show(context,
        type: SystemMessageType.levelUp,
        title: '[ LEVEL UP ]',
        message: 'You have ascended.',
        subMessage: 'Current Level: $newLevel — ${AppConstants.rankLabel(newLevel)}',
      );

  static Future<void> newDay(BuildContext context) =>
      show(context,
        type: SystemMessageType.info,
        title: '[ NEW DAY DETECTED ]',
        message: 'Daily quests have been generated.',
        subMessage: 'Complete all missions before midnight.',
      );

  static Future<void> bossAppeared(BuildContext context) =>
      show(context,
        type: SystemMessageType.boss,
        title: '[ BOSS RAID AVAILABLE ]',
        message: 'A powerful enemy has appeared.',
        subMessage: 'Defeat it for 300 EXP and title rewards.',
      );

  static Future<void> randomEvent(BuildContext context, String eventType) {
    String title, message, sub;
    switch (eventType) {
      case 'double_exp':
        title = '[ DOUBLE EXP EVENT ]';
        message = 'The System has amplified your potential.';
        sub = 'All EXP earned today is doubled.';
        break;
      case 'bonus':
        title = '[ BONUS QUEST DETECTED ]';
        message = 'Anomaly detected. Bonus mission added.';
        sub = 'Complete for extra EXP rewards.';
        break;
      default:
        title = '[ SYSTEM MALFUNCTION ]';
        message = 'Anomaly detected. The System has intervened.';
        sub = 'One quest difficulty has increased.';
    }
    return show(context,
      type: SystemMessageType.event,
      title: title, message: message, subMessage: sub,
    );
  }

  static Future<void> achievementUnlocked(BuildContext context, String id) {
    final def = ContentService.instance.achievements.firstWhere(
      (a) => a['id'] == id,
      orElse: () => {'title': 'Achievement', 'rarity': 'common'},
    );
    return show(context,
      type: SystemMessageType.achievement,
      title: '[ ACHIEVEMENT UNLOCKED ]',
      message: def['title'] as String,
      subMessage: '${(def['rarity'] as String).toUpperCase()} — New badge added.',
    );
  }
}

// ── Dialog Widget ────────────────────────────────────────────────────────────
class _SystemDialog extends StatefulWidget {
  final SystemMessageType type;
  final String title;
  final String message;
  final String? subMessage;

  const _SystemDialog({
    required this.type,
    required this.title,
    required this.message,
    this.subMessage,
  });

  @override
  State<_SystemDialog> createState() => _SystemDialogState();
}

class _SystemDialogState extends State<_SystemDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.type) {
      case SystemMessageType.success: return AppColors.emerald;
      case SystemMessageType.failure: return AppColors.crimson;
      case SystemMessageType.levelUp: return AppColors.gold;
      case SystemMessageType.punishment: return AppColors.crimson;
      case SystemMessageType.info: return AppColors.cyan;
      case SystemMessageType.achievement: return AppColors.violet;
      case SystemMessageType.boss: return AppColors.bossColor;
      case SystemMessageType.event: return AppColors.violet;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case SystemMessageType.success: return Icons.check_circle_outline;
      case SystemMessageType.failure: return Icons.warning_amber_rounded;
      case SystemMessageType.levelUp: return Icons.trending_up_rounded;
      case SystemMessageType.punishment: return Icons.local_fire_department_rounded;
      case SystemMessageType.info: return Icons.info_outline;
      case SystemMessageType.achievement: return Icons.military_tech_rounded;
      case SystemMessageType.boss: return Icons.shield_rounded;
      case SystemMessageType.event: return Icons.electric_bolt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _glow,
          builder: (_, child) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: _color.withValues(alpha: 0.8), width: 1.5),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: _color.withValues(alpha: 0.25 * _glow.value),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.08),
                  border: Border(
                    bottom: BorderSide(color: _color.withValues(alpha: 0.4)),
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SYSTEM',
                      style: GoogleFonts.shareTechMono(
                        color: _color, fontSize: 9, letterSpacing: 3,
                      ),
                    ),
                    const Spacer(),
                    Text('■ ■ ■', style: GoogleFonts.shareTechMono(
                      color: _color.withValues(alpha: 0.4), fontSize: 7,
                    )),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    Icon(_icon, color: _color, size: 44),
                    const SizedBox(height: 14),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.shareTechMono(
                        color: _color, fontSize: 11,
                        fontWeight: FontWeight.bold, letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(
                        color: AppColors.textPrimary, fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.subMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.subMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.shareTechMono(
                          color: AppColors.textMuted, fontSize: 11, height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 28,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: _color),
                          borderRadius: BorderRadius.circular(3),
                          color: _color.withValues(alpha: 0.1),
                        ),
                        child: Text(
                          'ACKNOWLEDGE',
                          style: GoogleFonts.rajdhani(
                            color: _color, fontSize: 13,
                            fontWeight: FontWeight.bold, letterSpacing: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
