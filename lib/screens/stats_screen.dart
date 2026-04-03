import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/daily_log_model.dart';
import '../services/storage_service.dart';
import '../widgets/animated_background.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();
    final user = storage.getUser();
    final logs = storage.getLastNLogs(7);
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayLog = storage.getDailyLogs().cast<DailyLogModel?>().firstWhere(
      (log) => log?.date == todayKey,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('STATISTICS', style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary, fontSize: 28,
                fontWeight: FontWeight.bold, letterSpacing: 3,
              )),
              Text('Performance tracking dashboard', style: GoogleFonts.shareTechMono(
                color: AppColors.textMuted, fontSize: 10, letterSpacing: 1,
              )),
              const SizedBox(height: 20),

              // ── Stat Cards ─────────────────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _statCard('LEVEL', '${user.level}', AppColors.violet, Icons.trending_up),
                  _statCard('STREAK', '${user.streak}d', AppColors.gold, Icons.local_fire_department),
                  _statCard('BEST STREAK', '${user.bestStreak}d', AppColors.cyan, Icons.emoji_events),
                  _statCard('QUESTS DONE', '${user.totalQuestsCompleted}', AppColors.emerald, Icons.check_circle_outline),
                  _statCard('EXP EARNED', '${user.totalExpEarned}', AppColors.violet, Icons.bolt),
                  _statCard('BOSS WINS', '${user.bossDefeatsTotal}', AppColors.gold, Icons.shield),
                ],
              ),

              const SizedBox(height: 20),

              _sectionHeader('OFFLINE ACTIVITY — TODAY'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: todayLog == null
                    ? Text(
                        'No offline movement data saved yet. Start tracking from Home to collect steps, pace, and elevation locally.',
                        style: GoogleFonts.shareTechMono(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          height: 1.5,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                todayLog.activityType.isEmpty ? 'TRACKING' : todayLog.activityType,
                                style: GoogleFonts.rajdhani(
                                  color: AppColors.emerald,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${todayLog.activeMinutes.toStringAsFixed(0)} min active',
                                style: GoogleFonts.shareTechMono(
                                  color: AppColors.textMuted,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.4,
                            children: [
                              _statCard(
                                'PACE',
                                todayLog.distanceMeters < 10 || todayLog.activeMinutes <= 0
                                    ? '--'
                                    : '${(todayLog.activeMinutes / (todayLog.distanceMeters / 1000)).toStringAsFixed(1)} min/km',
                                AppColors.gold,
                                Icons.speed,
                              ),
                              _statCard('STEPS', '${todayLog.steps}', AppColors.cyan, Icons.directions_walk),
                              _statCard('DISTANCE', '${(todayLog.distanceMeters / 1000).toStringAsFixed(2)} km', AppColors.violet, Icons.route),
                              _statCard('ASCENT', '${todayLog.elevationGainMeters.toStringAsFixed(0)} m', AppColors.emerald, Icons.terrain),
                            ],
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 20),

              // ── EXP chart ─────────────────────────────────────────────
              if (logs.isNotEmpty) ...[
                _sectionHeader('EXP GAINED — LAST ${logs.length} DAYS'),
                const SizedBox(height: 12),
                Container(
                  height: 180,
                  padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: BarChart(
                    BarChartData(
                      backgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.cardBorder,
                          strokeWidth: 0.5,
                        ),
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: GoogleFonts.shareTechMono(
                                color: AppColors.textMuted, fontSize: 8,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= logs.length) return const SizedBox();
                              final d = logs[i].date;
                              return Text(
                                d.substring(8),
                                style: GoogleFonts.shareTechMono(
                                  color: AppColors.textMuted, fontSize: 8,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      barGroups: List.generate(logs.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: logs[i].expGained.toDouble(),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4F46E5), AppColors.violet],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Completion rate chart ─────────────────────────────────
                _sectionHeader('COMPLETION RATE — LAST ${logs.length} DAYS'),
                const SizedBox(height: 12),
                Container(
                  height: 140,
                  padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: LineChart(
                    LineChartData(
                      backgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 0.25,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.cardBorder, strokeWidth: 0.5,
                        ),
                        drawVerticalLine: false,
                      ),
                      minY: 0, maxY: 1,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (v, _) => Text(
                              '${(v * 100).toInt()}%',
                              style: GoogleFonts.shareTechMono(
                                color: AppColors.textMuted, fontSize: 8,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(logs.length, (i) =>
                              FlSpot(i.toDouble(), logs[i].completionRate)),
                          isCurved: true,
                          color: AppColors.cyan,
                          barWidth: 2,
                          dotData: FlDotData(
                            getDotPainter: (_, __, ___, ____) =>
                                FlDotCirclePainter(radius: 3, color: AppColors.cyan),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.cyan.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'No history yet.\nComplete your first daily missions.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.shareTechMono(
                      color: AppColors.textMuted, fontSize: 11, height: 1.8,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Adaptive Status ──────────────────────────────────────────
              _sectionHeader('ADAPTIVE DIFFICULTY'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modifier: ${user.difficultyModifier >= 0 ? '+' : ''}${(user.difficultyModifier * 100).toInt()}%',
                      style: GoogleFonts.rajdhani(
                        color: user.difficultyModifier > 0
                            ? AppColors.crimson
                            : user.difficultyModifier < 0
                                ? AppColors.cyan
                                : AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tracking ${user.recentCompletionRates.length} day(s) of performance data.',
                      style: GoogleFonts.shareTechMono(
                        color: AppColors.textMuted, fontSize: 10, height: 1.5,
                      ),
                    ),
                    if (user.recentCompletionRates.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Avg rate: ${(user.recentCompletionRates.reduce((a, b) => a + b) / user.recentCompletionRates.length * 100).toInt()}%',
                        style: GoogleFonts.shareTechMono(
                          color: AppColors.textMuted, fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const Spacer(),
              Text(label, style: GoogleFonts.shareTechMono(
                color: AppColors.textMuted, fontSize: 9, letterSpacing: 1.3,
              )),
            ],
          ),
          const Spacer(),
          Text(value, style: GoogleFonts.rajdhani(
            color: color, fontSize: 26, fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(text, style: GoogleFonts.shareTechMono(
      color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.8,
    ));
  }
}
