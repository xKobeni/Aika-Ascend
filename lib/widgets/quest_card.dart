import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../models/quest_model.dart';

class QuestCard extends StatefulWidget {
  final QuestModel quest;
  final int index;
  final VoidCallback onComplete;

  const QuestCard({
    super.key,
    required this.quest,
    required this.index,
    required this.onComplete,
  });

  @override
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // Timer state for timed quests
  Timer? _questTimer;
  int _timerSeconds = 0;
  bool _timerRunning = false;
  bool _timerStarted = false;

  @override
  void initState() {
    super.initState();
    _timerSeconds = widget.quest.target;
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _questTimer?.cancel();
    super.dispose();
  }

  // ── Colors ─────────────────────────────────────────────────────────────────
  Color get _accentColor {
    if (widget.quest.isBossQuest) return AppColors.bossColor;
    if (widget.quest.isPunishment) return AppColors.punishmentColor;
    if (widget.quest.eventType == 'bonus') return AppColors.bonusColor;
    if (widget.quest.eventType == 'malfunction') return AppColors.crimson;
    if (widget.quest.completed) return AppColors.emerald;
    switch (widget.quest.difficulty) {
      case 'extreme': return AppColors.extremeColor;
      case 'hard': return AppColors.hardColor;
      default: return AppColors.normalColor;
    }
  }

  String get _difficultyLabel {
    if (widget.quest.isBossQuest) return 'BOSS';
    if (widget.quest.isPunishment) return 'PENALTY';
    if (widget.quest.eventType == 'bonus') return 'BONUS';
    if (widget.quest.eventType == 'malfunction') return 'MALFUNCTION';
    if (widget.quest.difficulty == 'beginner') return 'NOVICE';
    if (widget.quest.difficulty == 'standard') return 'HUNTER';
    if (widget.quest.difficulty == 'advanced') return 'ELITE';
    return widget.quest.difficulty.toUpperCase();
  }

  // ── Timer logic ────────────────────────────────────────────────────────────
  void _startTimer() {
    setState(() {
      _timerRunning = true;
      _timerStarted = true;
    });
    _questTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timerSeconds--);
      if (_timerSeconds <= 0) {
        t.cancel();
        _timerRunning = false;
        HapticFeedback.mediumImpact();
        widget.onComplete();
      }
    });
  }

  void _pauseTimer() {
    _questTimer?.cancel();
    setState(() {
      _timerRunning = false;
      _timerSeconds += 10; // +10s penalty for pausing
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 20, end: 0),
      duration: Duration(milliseconds: 320 + (widget.index * 55)),
      curve: Curves.easeOutCubic,
      builder: (_, y, child) => Transform.translate(
        offset: Offset(0, y),
        child: Opacity(
          opacity: (1 - (y / 20)).clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            border: Border.all(
              color: widget.quest.completed
                  ? _accentColor.withValues(alpha: 0.3)
                  : _accentColor.withValues(alpha: 0.5 + 0.4 * _pulse.value),
              width: widget.quest.isBossQuest ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: widget.quest.completed ? [] : [
              BoxShadow(
                color: _accentColor.withValues(alpha: 0.10 * _pulse.value),
                blurRadius: 16, spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              if (widget.quest.isTimedQuest && !widget.quest.completed)
                _buildTimerSection()
              else
                _buildProgressBar(),
              const SizedBox(height: 10),
              _buildActionArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Category icon
        _CategoryIcon(category: widget.quest.category, color: _accentColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.quest.title.toUpperCase(),
            style: GoogleFonts.rajdhani(
              color: widget.quest.completed
                  ? AppColors.textMuted
                  : AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              decoration: widget.quest.completed
                  ? TextDecoration.lineThrough
                  : null,
              decorationColor: AppColors.textMuted,
            ),
          ),
        ),
        // Difficulty / event badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.12),
            border: Border.all(color: _accentColor.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            _difficultyLabel,
            style: GoogleFonts.shareTechMono(
              color: _accentColor, fontSize: 9, letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: widget.quest.completionRatio,
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${widget.quest.progress}/${widget.quest.target}  (${(widget.quest.completionRatio * 100).toInt()}%)',
          style: GoogleFonts.shareTechMono(
            color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerSection() {
    final mins = (_timerSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_timerSeconds % 60).toString().padLeft(2, '0');
    final urgentColor = _timerSeconds < 10 ? AppColors.crimson : _accentColor;

    return Row(
      children: [
        Icon(Icons.timer_outlined, color: urgentColor, size: 16),
        const SizedBox(width: 8),
        Text(
          '$mins:$secs',
          style: GoogleFonts.rajdhani(
            color: urgentColor, fontSize: 22, fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'sec hold',
          style: GoogleFonts.shareTechMono(
            color: AppColors.textMuted, fontSize: 11,
          ),
        ),
        const Spacer(),
        if (_timerStarted && _timerRunning)
          GestureDetector(
            onTap: _pauseTimer,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                'PAUSE +10s',
                style: GoogleFonts.shareTechMono(
                  color: AppColors.gold, fontSize: 10, letterSpacing: 0.8,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionArea() {
    if (widget.quest.completed) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.emerald, size: 14),
          const SizedBox(width: 6),
          Text(
            'MISSION COMPLETE  +${widget.quest.expReward} EXP',
            style: GoogleFonts.rajdhani(
              color: AppColors.emerald, fontSize: 12, letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    if (widget.quest.isTimedQuest && !_timerStarted) {
      return _buildButton(
        label: '[ START TIMER ]',
        color: _accentColor,
        onTap: _startTimer,
      );
    }

    if (widget.quest.isTimedQuest && _timerRunning) {
      return _buildButton(
        label: '[ HOLDING... ]',
        color: _accentColor,
        onTap: null,
      );
    }

    return _buildButton(
      label: '[ MARK COMPLETE ]',
      color: _accentColor,
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onComplete();
      },
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: onTap == null ? 0.05 : 0.12),
          border: Border.all(
            color: color.withValues(alpha: onTap == null ? 0.3 : 0.7),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.rajdhani(
            color: onTap == null ? color.withValues(alpha: 0.5) : color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}

// ── Category icon helper ───────────────────────────────────────────────────
class _CategoryIcon extends StatelessWidget {
  final String category;
  final Color color;

  const _CategoryIcon({required this.category, required this.color});

  IconData get _icon {
    switch (category) {
      case 'cardio': return Icons.directions_run_rounded;
      case 'discipline': return Icons.self_improvement_rounded;
      default: return Icons.fitness_center_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(_icon, color: color, size: 14),
    );
  }
}
