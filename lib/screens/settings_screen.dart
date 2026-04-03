import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../services/storage_service.dart';
import '../widgets/animated_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  Map<String, dynamic> _settings = {};

  @override
  void initState() {
    super.initState();
    _settings = _storage.getAppSettings();
  }

  Future<void> _set(String key, dynamic value) async {
    final next = Map<String, dynamic>.from(_settings)..[key] = value;
    setState(() => _settings = next);
    await _storage.saveAppSettings(next);
  }

  bool _bool(String key) => (_settings[key] as bool?) ?? false;
  String _str(String key) => (_settings[key] as String?) ?? '';
  int _int(String key) => (_settings[key] as num?)?.toInt() ?? 0;
  double _double(String key) => (_settings[key] as num?)?.toDouble() ?? 0;

  List<String> _list(String key) {
    final raw = _settings[key];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  Future<void> _pickTime(String key) async {
    final parts = _str(key).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 7,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;

    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    await _set(key, '$hh:$mm');
  }

  String _formatTimeForDisplay(String hhmm) {
    final use24 = _bool('use24HourTime');
    if (use24) return hhmm;

    final parts = hhmm.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '${hour12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $suffix';
  }

  Future<void> _exportSettings() async {
    final text = const JsonEncoder.withIndent('  ').convert(_settings);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text('Settings copied to clipboard.', style: GoogleFonts.shareTechMono(color: AppColors.textPrimary)),
      ),
    );
  }

  Future<void> _importSettings() async {
    final ctrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('IMPORT SETTINGS JSON', style: GoogleFonts.rajdhani(color: AppColors.violet, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          maxLines: 10,
          style: GoogleFonts.shareTechMono(color: AppColors.textPrimary, fontSize: 11),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Import')),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      final decoded = jsonDecode(ctrl.text.trim());
      if (decoded is! Map) throw const FormatException('Invalid JSON object');
      final merged = Map<String, dynamic>.from(_storage.getAppSettings())
        ..addAll(Map<String, dynamic>.from(decoded));
      await _storage.saveAppSettings(merged);
      if (!mounted) return;
      setState(() => _settings = merged);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: Text('Settings imported.', style: GoogleFonts.shareTechMono(color: AppColors.textPrimary)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.crimson,
          content: Text('Invalid settings JSON.', style: GoogleFonts.shareTechMono(color: Colors.white)),
        ),
      );
    }
  }

  Future<void> _clearTrackerHistory() async {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final existing = _storage.getDailyLogs().where((log) => log.date == todayKey);
    if (existing.isNotEmpty) {
      final log = existing.first.copyWith(
        steps: 0,
        distanceMeters: 0,
        activeMinutes: 0,
        elevationGainMeters: 0,
        activityType: '',
      );
      await _storage.addDailyLog(log);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text('Today tracker stats cleared.', style: GoogleFonts.shareTechMono(color: AppColors.textPrimary)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allowedKinds = _list('punishmentAllowedKinds');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('SETTINGS', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 3)),
              Text('Customize your training system', style: GoogleFonts.shareTechMono(color: AppColors.textMuted, fontSize: 10)),
              const SizedBox(height: 16),

              _section('Daily Reminders', [
                _switchTile('Morning reminder', _bool('reminderMorningEnabled'), (v) => _set('reminderMorningEnabled', v)),
                _timeTile('Morning time', _str('reminderMorningTime'), () => _pickTime('reminderMorningTime')),
                _switchTile('Evening reminder', _bool('reminderEveningEnabled'), (v) => _set('reminderEveningEnabled', v)),
                _timeTile('Evening time', _str('reminderEveningTime'), () => _pickTime('reminderEveningTime')),
                _switchTile('Missed-day warning', _bool('missedDayWarningEnabled'), (v) => _set('missedDayWarningEnabled', v)),
              ]),

              _section('Punishment', [
                _dropdownTile<String>(
                  'Intensity',
                  _str('punishmentIntensity'),
                  const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'standard', child: Text('Standard')),
                    DropdownMenuItem(value: 'hard', child: Text('Hard')),
                  ],
                  (v) => _set('punishmentIntensity', v ?? 'standard'),
                ),
                _chipSelector('Allowed punishment types',
                  const ['reps', 'timed', 'distance'],
                  allowedKinds,
                  (value) async {
                    final next = List<String>.from(allowedKinds);
                    if (next.contains(value)) {
                      next.remove(value);
                    } else {
                      next.add(value);
                    }
                    await _set('punishmentAllowedKinds', next);
                  },
                ),
                _switchTile('Allow high-impact punishments', _bool('punishmentHighImpactEnabled'), (v) => _set('punishmentHighImpactEnabled', v)),
              ]),

              _section('Workout Preferences', [
                _dropdownTile<String>(
                  'Workout focus',
                  _str('workoutFocus'),
                  const [
                    DropdownMenuItem(value: 'any', child: Text('Any')),
                    DropdownMenuItem(value: 'upper', child: Text('Upper body')),
                    DropdownMenuItem(value: 'lower', child: Text('Lower body')),
                    DropdownMenuItem(value: 'core', child: Text('Core')),
                    DropdownMenuItem(value: 'full', child: Text('Full body')),
                    DropdownMenuItem(value: 'endurance', child: Text('Endurance')),
                    DropdownMenuItem(value: 'stamina', child: Text('Stamina')),
                  ],
                  (v) => _set('workoutFocus', v ?? 'any'),
                ),
                _dropdownTile<int>(
                  'Session length',
                  _int('workoutSessionMinutes'),
                  const [
                    DropdownMenuItem(value: 0, child: Text('Any')),
                    DropdownMenuItem(value: 20, child: Text('Up to 20 min')),
                    DropdownMenuItem(value: 30, child: Text('Up to 30 min')),
                    DropdownMenuItem(value: 45, child: Text('Up to 45 min')),
                    DropdownMenuItem(value: 60, child: Text('Up to 60 min')),
                  ],
                  (v) => _set('workoutSessionMinutes', v ?? 0),
                ),
                _dropdownTile<String>(
                  'Equipment mode',
                  _str('equipmentMode'),
                  const [
                    DropdownMenuItem(value: 'bodyweight', child: Text('Bodyweight only')),
                    DropdownMenuItem(value: 'home_gym', child: Text('Home gym')),
                  ],
                  (v) => _set('equipmentMode', v ?? 'bodyweight'),
                ),
              ]),

              _section('Activity Tracker', [
                _switchTile('Auto-start tracker on open', _bool('trackerAutoStart'), (v) => _set('trackerAutoStart', v)),
                _dropdownTile<String>(
                  'GPS mode',
                  _str('trackerGpsMode'),
                  const [
                    DropdownMenuItem(value: 'battery', child: Text('Battery saver')),
                    DropdownMenuItem(value: 'balanced', child: Text('Balanced')),
                    DropdownMenuItem(value: 'precise', child: Text('Precise')),
                  ],
                  (v) => _set('trackerGpsMode', v ?? 'balanced'),
                ),
                _switchTile('Background tracking', _bool('trackerBackgroundEnabled'), (v) => _set('trackerBackgroundEnabled', v)),
                _sliderTile('Step goal', _int('trackerStepGoal').toDouble(), 2000, 20000, 1000, '${_int('trackerStepGoal')} steps',
                    (v) => _set('trackerStepGoal', v.round())),
                _sliderTile('Distance goal', _double('trackerDistanceGoalKm'), 1, 20, 1, '${_double('trackerDistanceGoalKm').toStringAsFixed(1)} km',
                    (v) => _set('trackerDistanceGoalKm', double.parse(v.toStringAsFixed(1)))),
              ]),

              _section('Units And Locale', [
                _switchTile('Use metric units', _bool('useMetricUnits'), (v) => _set('useMetricUnits', v)),
                _switchTile('Use 24-hour time', _bool('use24HourTime'), (v) => _set('use24HourTime', v)),
                _switchTile('Week starts Monday', _bool('weekStartsMonday'), (v) => _set('weekStartsMonday', v)),
              ]),

              _section('Notifications And Feedback', [
                _switchTile('Enable notifications', _bool('notificationsEnabled'), (v) => _set('notificationsEnabled', v)),
                _switchTile('Show system popups', _bool('popupMessagesEnabled'), (v) => _set('popupMessagesEnabled', v)),
                _switchTile('Sound effects', _bool('soundEffectsEnabled'), (v) => _set('soundEffectsEnabled', v)),
                _switchTile('Vibration feedback', _bool('vibrationEnabled'), (v) => _set('vibrationEnabled', v)),
                _switchTile('Quiet hours', _bool('quietHoursEnabled'), (v) => _set('quietHoursEnabled', v)),
                _timeTile('Quiet start', _str('quietHoursStart'), () => _pickTime('quietHoursStart')),
                _timeTile('Quiet end', _str('quietHoursEnd'), () => _pickTime('quietHoursEnd')),
              ]),

              _section('Data And Backup', [
                _buttonTile('Export settings to clipboard', _exportSettings),
                _buttonTile('Import settings JSON', _importSettings),
                _buttonTile('Clear today tracker history', _clearTrackerHistory),
              ]),

              _section('Privacy And Display', [
                _switchTile('Offline-only mode', _bool('offlineOnlyMode'), (v) => _set('offlineOnlyMode', v)),
                _switchTile('High contrast mode', _bool('highContrastMode'), (v) => _set('highContrastMode', v)),
                _switchTile('Reduced motion', _bool('reducedMotion'), (v) => _set('reducedMotion', v)),
                _switchTile('Compact cards', _bool('compactCards'), (v) => _set('compactCards', v)),
                _sliderTile('Font scale', _double('fontScale'), 0.8, 1.3, 0.1, '${_double('fontScale').toStringAsFixed(1)}x',
                    (v) => _set('fontScale', double.parse(v.toStringAsFixed(1)))),
              ]),

              _section('Gameplay', [
                _switchTile('Adaptive difficulty', _bool('adaptiveDifficultyEnabled'), (v) => _set('adaptiveDifficultyEnabled', v)),
                _switchTile('Confirm path switch', _bool('confirmPathSwitch'), (v) => _set('confirmPathSwitch', v)),
              ]),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: GoogleFonts.rajdhani(color: AppColors.violet, fontWeight: FontWeight.bold, letterSpacing: 1.8)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: GoogleFonts.shareTechMono(color: AppColors.textPrimary, fontSize: 11)),
      value: value,
      activeColor: AppColors.violet,
      onChanged: onChanged,
    );
  }

  Widget _timeTile(String label, String value, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: GoogleFonts.shareTechMono(color: AppColors.textPrimary, fontSize: 11)),
      trailing: TextButton(
        onPressed: onTap,
        child: Text(
          _formatTimeForDisplay(value),
          style: GoogleFonts.rajdhani(color: AppColors.violet, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buttonTile(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.cardBorder),
          minimumSize: const Size(double.infinity, 42),
        ),
        child: Text(label.toUpperCase(), style: GoogleFonts.rajdhani(color: AppColors.textPrimary, letterSpacing: 1.3)),
      ),
    );
  }

  Widget _dropdownTile<T>(String label, T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.shareTechMono(color: AppColors.textPrimary, fontSize: 11))),
          const SizedBox(width: 10),
          DropdownButton<T>(
            value: value,
            dropdownColor: AppColors.surface,
            style: GoogleFonts.shareTechMono(color: AppColors.textPrimary, fontSize: 11),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _sliderTile(String label, double value, double min, double max, double divisions, String valueText, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $valueText', style: GoogleFonts.shareTechMono(color: AppColors.textPrimary, fontSize: 11)),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) ~/ divisions).toInt(),
          activeColor: AppColors.violet,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _chipSelector(String label, List<String> options, List<String> selected, ValueChanged<String> onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.shareTechMono(color: AppColors.textPrimary, fontSize: 11)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: options.map((item) {
              final active = selected.contains(item);
              return FilterChip(
                label: Text(item.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 10)),
                selected: active,
                onSelected: (_) => onTap(item),
                selectedColor: AppColors.violet.withValues(alpha: 0.25),
                checkmarkColor: AppColors.violet,
                side: BorderSide(color: active ? AppColors.violet : AppColors.cardBorder),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
