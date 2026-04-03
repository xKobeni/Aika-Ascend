// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'quest_model.dart';

class QuestModelAdapter extends TypeAdapter<QuestModel> {
  @override
  final int typeId = 1;

  @override
  QuestModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestModel(
      title: (fields[0] as String?) ?? '',
      target: (fields[1] as int?) ?? 0,
      progress: (fields[2] as int?) ?? 0,
      completed: (fields[3] as bool?) ?? false,
      isPunishment: (fields[4] as bool?) ?? false,
      category: (fields[5] as String?) ?? 'strength',
      difficulty: (fields[6] as String?) ?? 'normal',
      isTimedQuest: (fields[7] as bool?) ?? false,
      isBossQuest: (fields[8] as bool?) ?? false,
      isRandomEvent: (fields[9] as bool?) ?? false,
      eventType: (fields[10] as String?) ?? '',
      expReward: (fields[11] as int?) ?? AppConstants.baseExpPerQuest,
    );
  }

  @override
  void write(BinaryWriter writer, QuestModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)..write(obj.title)
      ..writeByte(1)..write(obj.target)
      ..writeByte(2)..write(obj.progress)
      ..writeByte(3)..write(obj.completed)
      ..writeByte(4)..write(obj.isPunishment)
      ..writeByte(5)..write(obj.category)
      ..writeByte(6)..write(obj.difficulty)
      ..writeByte(7)..write(obj.isTimedQuest)
      ..writeByte(8)..write(obj.isBossQuest)
      ..writeByte(9)..write(obj.isRandomEvent)
      ..writeByte(10)..write(obj.eventType)
      ..writeByte(11)..write(obj.expReward);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
