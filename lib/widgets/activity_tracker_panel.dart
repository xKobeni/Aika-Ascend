import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../services/activity_tracking_service.dart';
import '../services/storage_service.dart';
import '../services/settings_view_service.dart';

class ActivityTrackerPanel extends StatefulWidget {
  const ActivityTrackerPanel({super.key});

  @override
  State<ActivityTrackerPanel> createState() => _ActivityTrackerPanelState();
}

class _ActivityTrackerPanelState extends State<ActivityTrackerPanel> {
  final ActivityTrackingService _service = ActivityTrackingService.instance;
  final StorageService _storage = StorageService();
  bool _busy = false;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final autoStart = (_storage.getAppSettings()['trackerAutoStart'] as bool?) ?? false;
      if (!autoStart || !mounted) return;
      final started = await _service.start();
      if (!mounted) return;
      setState(() => _enabled = started);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ActivitySnapshot>(
      stream: _service.stream,
      initialData: ActivitySnapshot.idle(),
      builder: (context, snapshot) {
        final settings = _storage.getAppSettings();
        final compactCards = (settings['compactCards'] as bool?) ?? false;
        final data = snapshot.data ?? ActivitySnapshot.idle();
        final isEnabled = _enabled || data.isTracking;
        final pace = SettingsViewService.paceLabel(data.paceMinutesPerKm);
        final distance = SettingsViewService.distanceDisplayValue(data.distanceMeters);
        final distanceUnit = SettingsViewService.distanceUnitLabel();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compactCards ? 12 : 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: isEnabled ? AppColors.emerald.withValues(alpha: 0.4) : AppColors.cardBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.directions_run, color: AppColors.emerald, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OFFLINE ACTIVITY TRACKER',
                          style: GoogleFonts.shareTechMono(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Android sensors only. No network required.',
                          style: GoogleFonts.shareTechMono(
                            color: AppColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(data),
                ],
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: compactCards ? 2.5 : 2.2,
                children: [
                  _metric('STEPS', '${data.steps}'),
                  _metric('DISTANCE', '${distance.toStringAsFixed(2)} $distanceUnit'),
                  _metric('PACE', pace),
                  _metric('ELEVATION', '${data.elevationGainMeters.toStringAsFixed(0)} m'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      label: isEnabled ? 'STOP TRACKING' : 'START TRACKING',
                      color: isEnabled ? AppColors.crimson : AppColors.emerald,
                      onPressed: _busy ? null : () async {
                        setState(() => _busy = true);
                        if (isEnabled) {
                          await _service.stop();
                          if (mounted) {
                            setState(() => _enabled = false);
                          }
                        } else {
                          final started = await _service.start();
                          if (mounted) {
                            setState(() => _enabled = started);
                          }
                        }
                        if (mounted) {
                          setState(() => _busy = false);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      data.activityLabel,
                      style: GoogleFonts.rajdhani(
                        color: AppColors.cyan,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data.isTracking
                    ? 'Live cadence: ${data.stepRateSpm.toStringAsFixed(0)} steps/min'
                    : 'Enable tracking to begin collecting offline movement data.',
                style: GoogleFonts.shareTechMono(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.shareTechMono(
              color: AppColors.textMuted,
              fontSize: 7,
              height: 1,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(ActivitySnapshot data) {
    final color = data.isTracking ? AppColors.emerald : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        data.isTracking ? 'LIVE' : 'PAUSED',
        style: GoogleFonts.shareTechMono(
          color: color,
          fontSize: 9,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 0,
        ),
        child: Text(
          _busy ? 'PROCESSING...' : label,
          style: GoogleFonts.shareTechMono(
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}