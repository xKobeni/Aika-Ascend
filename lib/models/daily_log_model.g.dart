// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'daily_log_model.dart';

class DailyLogModelAdapter extends TypeAdapter<DailyLogModel> {
  @override
  final int typeId = 3;

  @override
  DailyLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyLogModel(
      date: (fields[0] as String?) ?? '',
      expGained: (fields[1] as int?) ?? 0,
      completedCount: (fields[2] as int?) ?? 0,
      totalCount: (fields[3] as int?) ?? 0,
      completionRate: (fields[4] as double?) ?? 0.0,
      steps: (fields[5] as int?) ?? 0,
      distanceMeters: (fields[6] as double?) ?? 0.0,
      activeMinutes: (fields[7] as double?) ?? 0.0,
      elevationGainMeters: (fields[8] as double?) ?? 0.0,
      activityType: (fields[9] as String?) ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, DailyLogModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)..write(obj.date)
      ..writeByte(1)..write(obj.expGained)
      ..writeByte(2)..write(obj.completedCount)
      ..writeByte(3)..write(obj.totalCount)
      ..writeByte(4)..write(obj.completionRate)
      ..writeByte(5)..write(obj.steps)
      ..writeByte(6)..write(obj.distanceMeters)
      ..writeByte(7)..write(obj.activeMinutes)
      ..writeByte(8)..write(obj.elevationGainMeters)
      ..writeByte(9)..write(obj.activityType);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
