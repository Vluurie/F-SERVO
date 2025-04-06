
import 'dart:typed_data';

import '../../../../../fileTypeUtils/utils/ByteDataWrapper.dart';
import 'messageContext.dart';
import 'messageFrame.dart';
import 'namedPipeHandler.dart';

mixin MessageSender {
  final NamedPipeHandler _pipeHandler = globalPipeHandler;

  Future<void> sendIntMessage({
    required MessageContext context,
    required int value,
    required int messageType,
  }) async {
    final contextBytes = context.toBytes();
    final totalSize = contextBytes.length + 4; // 4 bytes for int32
    final wrapper = ByteDataWrapper.allocate(totalSize);
    wrapper.writeBytes(contextBytes);
    wrapper.writeInt32(value);
    await _sendMessage(messageType, wrapper.buffer.asUint8List(0, wrapper.position));
  }

  Future<void> sendUintMessage({
    required MessageContext context,
    required int value,
    required int messageType,
  }) async {
    final contextBytes = context.toBytes();
    final totalSize = contextBytes.length + 4;
    final wrapper = ByteDataWrapper.allocate(totalSize);
    wrapper.writeBytes(contextBytes);
    wrapper.writeUint32(value);
    await _sendMessage(messageType, wrapper.buffer.asUint8List(0, wrapper.position));
  }

Future<void> sendObjectIdMessage({
  required MessageContext context,
  required int messageType,
}) async {
    // objID expected to be 6 bytes
  if (context.objId != null && context.objId?.length == 6) {
  final contextBytes = context.toBytes();
  final totalSize = contextBytes.length + 6;
  final wrapper = ByteDataWrapper.allocate(totalSize);
  wrapper.writeBytes(contextBytes);
  wrapper.writeString(context.objId!, StringEncoding.utf8);

  await _sendMessage(messageType, wrapper.buffer.asUint8List(0, wrapper.position));
}
else {
  print("Invalid ObjID");
}
}

Future<void> sendVectorMessage({
  required MessageContext context,
  required double x,
  required double y,
  required double z,
  required int messageType,
}) async {
  final contextBytes = context.toBytes();
  final totalSize = contextBytes.length + 12; // 3 floats (4 bytes each)
  final wrapper = ByteDataWrapper.allocate(totalSize);
  wrapper.writeBytes(contextBytes);
  wrapper.writeFloat32(x);
  wrapper.writeFloat32(y);
  wrapper.writeFloat32(z);
  await _sendMessage(messageType, wrapper.buffer.asUint8List(0, totalSize));
}

  /// First it checks if the Action exists in a HAP ingame,
  /// if it does not exist it will create the Action in the same HAP send by the context
  Future<void> sendCheckActionExistOrCreate({
    required MessageContext context,
    required int messageType,
  }) async {
    final contextBytes = context.toBytes();
    final wrapper = ByteDataWrapper.allocate(contextBytes.length);
    wrapper.writeBytes(contextBytes);
    await _sendMessage(messageType, wrapper.buffer.asUint8List(0, wrapper.position));
  }

  Future<void> _sendMessage(int messageType, Uint8List payload) async {
    await _pipeHandler.sendBinaryMessage(MessageFrame(
      messageType: messageType,
      payload: payload,
    ));
  }
}
