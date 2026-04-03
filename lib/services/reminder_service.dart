import 'package:flutter/material.dart';

import 'storage_service.dart';
import 'system_service.dart';

class ReminderService {
  final StorageService _storage = StorageService();

  Future<void> checkAndTrigger(BuildContext context, {required bool hasPendingPunishment}) async {
    final settings = _storage.getAppSettings();
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final minutes = now.hour * 60 + now.minute;

    int toMinutes(String value) {
      final parts = value.split(':');
      final h = int.tryParse(parts.first) ?? 0;
      final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      return h * 60 + m;
    }

    Future<void> mark(String key) async {
      settings[key] = today;
      await _storage.saveAppSettings(settings);
    }

    final morningEnabled = (settings['reminderMorningEnabled'] as bool?) ?? true;
    final eveningEnabled = (settings['reminderEveningEnabled'] as bool?) ?? true;
    final missedWarningEnabled = (settings['missedDayWarningEnabled'] as bool?) ?? true;

    if (morningEnabled && (settings['lastMorningReminderDate'] as String? ?? '') != today) {
      if (minutes >= toMinutes((settings['reminderMorningTime'] as String?) ?? '07:00')) {
        await SystemService.show(
          context,
          type: SystemMessageType.info,
          title: '[ MORNING BRIEFING ]',
          message: 'Your missions are waiting.',
          subMessage: 'Start strong and protect your streak.',
        );
        await mark('lastMorningReminderDate');
      }
    }

    if (eveningEnabled && (settings['lastEveningReminderDate'] as String? ?? '') != today) {
      if (minutes >= toMinutes((settings['reminderEveningTime'] as String?) ?? '20:00')) {
        await SystemService.show(
          context,
          type: SystemMessageType.info,
          title: '[ EVENING CHECK ]',
          message: 'Daily missions close at midnight.',
          subMessage: 'Finish your remaining tasks now.',
        );
        await mark('lastEveningReminderDate');
      }
    }

    if (missedWarningEnabled && hasPendingPunishment && (settings['lastMissedWarningDate'] as String? ?? '') != today) {
      await SystemService.show(
        context,
        type: SystemMessageType.punishment,
        title: '[ MISSED-DAY WARNING ]',
        message: 'Penalty protocol is active.',
        subMessage: 'Clear the punishment to stabilize progression.',
      );
      await mark('lastMissedWarningDate');
    }
  }
}
