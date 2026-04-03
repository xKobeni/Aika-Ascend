// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'achievement_model.dart';

class AchievementModelAdapter extends TypeAdapter<AchievementModel> {
  @override
  final int typeId = 2;

  @override
  AchievementModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AchievementModel(
      id: (fields[0] as String?) ?? '',
      unlocked: (fields[1] as bool?) ?? false,
      unlockedDate: (fields[2] as String?) ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, AchievementModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.unlocked)
      ..writeByte(2)..write(obj.unlockedDate);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
