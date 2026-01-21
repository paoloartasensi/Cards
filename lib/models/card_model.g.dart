// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CardModelAdapter extends TypeAdapter<CardModel> {
  @override
  final int typeId = 0;

  @override
  CardModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardModel(
      id: fields[0] as String,
      name: fields[1] as String,
      code: fields[2] as String,
      codeType: fields[3] as String,
      category: fields[4] as String,
      colorValue: fields[5] as int,
      createdAt: fields[6] as DateTime?,
      note: fields[7] as String?,
      brandDomain: fields[8] as String?,
      flightDate: fields[9] as DateTime?,
      flightRoute: fields[10] as String?,
      flightNumber: fields[11] as String?,
      departureTime: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CardModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.code)
      ..writeByte(3)
      ..write(obj.codeType)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.colorValue)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.brandDomain)
      ..writeByte(9)
      ..write(obj.flightDate)
      ..writeByte(10)
      ..write(obj.flightRoute)
      ..writeByte(11)
      ..write(obj.flightNumber)
      ..writeByte(12)
      ..write(obj.departureTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
