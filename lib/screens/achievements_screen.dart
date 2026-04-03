import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../services/storage_service.dart';
import '../services/content_service.dart';
import '../widgets/animated_background.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'uncommon': return AppColors.rarityUncommon;
      case 'rare': return AppColors.rarityRare;
      case 'epic': return AppColors.rarityEpic;
      case 'legendary': return AppColors.rarityLegendary;
      default: return AppColors.rarityCommon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievements = StorageService().getAchievements();
    final achieveMap = {for (var a in achievements) a.id: a};
    final defs = ContentService.instance.achievements;

    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ACHIEVEMENTS', style: GoogleFonts.rajdhani(
                        color: AppColors.textPrimary, fontSize: 28,
                        fontWeight: FontWeight.bold, letterSpacing: 3,
                      )),
                      Text('Badge collection system', style: GoogleFonts.shareTechMono(
                        color: AppColors.textMuted, fontSize: 10, letterSpacing: 1,
                      )),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.violet.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.violet.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$unlockedCount / ${defs.length}',
                      style: GoogleFonts.rajdhani(
                        color: AppColors.violet, fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: defs.isEmpty ? 0 : unlockedCount / defs.length,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.violet),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: defs.length,
                  itemBuilder: (_, i) {
                    final def = defs[i];
                    final id = def['id'] as String;
                    final model = achieveMap[id];
                    final unlocked = model?.unlocked ?? false;
                    final rarity = def['rarity'] as String;
                    final color = unlocked ? _rarityColor(rarity) : AppColors.textMuted;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? color.withValues(alpha: 0.08)
                            : AppColors.surface,
                        border: Border.all(
                          color: unlocked
                              ? color.withValues(alpha: 0.5)
                              : AppColors.cardBorder,
                          width: unlocked ? 1 : 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: unlocked
                            ? [BoxShadow(
                                color: color.withValues(alpha: 0.15),
                                blurRadius: 12,
                              )]
                            : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                unlocked ? Icons.military_tech_rounded : Icons.lock_outline_rounded,
                                color: color,
                                size: 20,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  rarity.toUpperCase(),
                                  style: GoogleFonts.shareTechMono(
                                    color: color, fontSize: 8, letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            def['title'] as String,
                            style: GoogleFonts.rajdhani(
                              color: unlocked ? color : AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            def['desc'] as String,
                            style: GoogleFonts.shareTechMono(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (unlocked && (model?.unlockedDate.isNotEmpty ?? false)) ...[
                            const SizedBox(height: 4),
                            Text(
                              model!.unlockedDate,
                              style: GoogleFonts.shareTechMono(
                                color: color.withValues(alpha: 0.6),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
