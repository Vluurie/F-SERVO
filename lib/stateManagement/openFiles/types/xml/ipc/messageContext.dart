import 'dart:typed_data';

import '../../../../../fileTypeUtils/utils/ByteDataWrapper.dart';

class MessageContext {
  final int? id;
  final int? typeId;
  final String? objId;
  final int? actionId;
  final int? hapId;

  const MessageContext({
    this.id,
    this.typeId,
    this.objId,
    this.actionId,
    this.hapId,
  });

  factory MessageContext.none() => const MessageContext();

  bool get isEmpty =>
      id == null &&
      typeId == null &&
      objId == null &&
      actionId == null &&
      hapId == null;

  bool get isNotEmpty => !isEmpty;

   Uint8List toBytes() {
    if (isEmpty) return Uint8List(0);
    // id: 1 byte + (if Some then 4)
    // typeId: 1 + (if Some then 4)
    // objId: 1 + (if Some then 6)
    // actionId: 1 + (if Some then 4)
    // hapId: 1 + (if Some then 4)
    int size = 0;
    size += 1 + (id != null ? 4 : 0);
    size += 1 + (typeId != null ? 4 : 0);
    size += 1 + (objId != null ? 6 : 0);
    size += 1 + (actionId != null ? 4 : 0);
    size += 1 + (hapId != null ? 4 : 0);

    final wrapper = ByteDataWrapper.allocate(size);
    
    void writeOptionUint32(int? value) {
      if (value == null) {
        wrapper.writeUint8(0);
      } else {
        wrapper.writeUint8(1);
        wrapper.writeUint32(value);
      }
    }
    
    void writeOptionObjId(String? value) {
      if (value == null) {
        wrapper.writeUint8(0);
      } else {
        wrapper.writeUint8(1);
        final objBytes = Uint8List.fromList(value.codeUnits);
        final fixed = Uint8List(6);
        for (int i = 0; i < 6; i++) {
          fixed[i] = (i < objBytes.length) ? objBytes[i] : 0;
        }
        wrapper.writeBytes(fixed);
      }
    }
    
    writeOptionUint32(id);
    writeOptionUint32(typeId);
    writeOptionObjId(objId);
    writeOptionUint32(actionId);
    writeOptionUint32(hapId);
    
    return wrapper.buffer.asUint8List(0, wrapper.position);
  }

  MessageContext copyWith({
    int? id,
    int? typeId,
    String? objId,
    int? actionId,
    int? hapId,
  }) {
    return MessageContext(
      id: id ?? this.id,
      typeId: typeId ?? this.typeId,
      objId: objId ?? this.objId,
      actionId: actionId ?? this.actionId,
      hapId: hapId ?? this.hapId,
    );
  }

    Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (typeId != null) map['typeId'] = typeId;
    if (objId != null) map['objId'] = objId;
    if (actionId != null) map['actionId'] = actionId;
    if (hapId != null) map['hapId'] = hapId;
    return map;
  }


  @override
  String toString() => 'MessageContext(${toMap()})';

  @override
  bool operator ==(Object other) =>
      other is MessageContext &&
      other.id == id &&
      other.typeId == typeId &&
      other.objId == objId &&
      other.actionId == actionId &&
      other.hapId == hapId;

  @override
  int get hashCode =>
      id.hashCode ^
      typeId.hashCode ^
      objId.hashCode ^
      actionId.hashCode ^
      hapId.hashCode;
}
