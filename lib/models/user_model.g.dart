// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'user_model.dart';

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      level: (fields[0] as int?) ?? 1,
      exp: (fields[1] as int?) ?? 0,
      streak: (fields[2] as int?) ?? 0,
      lastLoginDate: (fields[3] as String?) ?? '',
      hasPendingPunishment: (fields[4] as bool?) ?? false,
      hunterName: (fields[5] as String?) ?? '',
      skillPath: (fields[6] as int?) ?? 0,
      titleId: (fields[7] as int?) ?? 0,
      consecutiveMisses: (fields[8] as int?) ?? 0,
      difficultyModifier: (fields[9] as double?) ?? 0.0,
      recentCompletionRates: (fields[10] as List?)
          ?.map((e) => (e as num).toDouble())
          .toList() ?? [],
      totalQuestsCompleted: (fields[11] as int?) ?? 0,
      totalExpEarned: (fields[12] as int?) ?? 0,
      bestStreak: (fields[13] as int?) ?? 0,
      restDayUsedThisWeek: (fields[14] as bool?) ?? false,
      bossDefeatedThisWeek: (fields[15] as bool?) ?? false,
      lastBossWeekYear: (fields[16] as int?) ?? 0,
      lastBossWeekNum: (fields[17] as int?) ?? 0,
      isLocked: (fields[18] as bool?) ?? false,
      isOnboarded: (fields[19] as bool?) ?? false,
      doubleExpToday: (fields[20] as bool?) ?? false,
      punishmentQuestsCompleted: (fields[21] as int?) ?? 0,
      bossDefeatsTotal: (fields[22] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)..write(obj.level)
      ..writeByte(1)..write(obj.exp)
      ..writeByte(2)..write(obj.streak)
      ..writeByte(3)..write(obj.lastLoginDate)
      ..writeByte(4)..write(obj.hasPendingPunishment)
      ..writeByte(5)..write(obj.hunterName)
      ..writeByte(6)..write(obj.skillPath)
      ..writeByte(7)..write(obj.titleId)
      ..writeByte(8)..write(obj.consecutiveMisses)
      ..writeByte(9)..write(obj.difficultyModifier)
      ..writeByte(10)..write(obj.recentCompletionRates)
      ..writeByte(11)..write(obj.totalQuestsCompleted)
      ..writeByte(12)..write(obj.totalExpEarned)
      ..writeByte(13)..write(obj.bestStreak)
      ..writeByte(14)..write(obj.restDayUsedThisWeek)
      ..writeByte(15)..write(obj.bossDefeatedThisWeek)
      ..writeByte(16)..write(obj.lastBossWeekYear)
      ..writeByte(17)..write(obj.lastBossWeekNum)
      ..writeByte(18)..write(obj.isLocked)
      ..writeByte(19)..write(obj.isOnboarded)
      ..writeByte(20)..write(obj.doubleExpToday)
      ..writeByte(21)..write(obj.punishmentQuestsCompleted)
      ..writeByte(22)..write(obj.bossDefeatsTotal);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
