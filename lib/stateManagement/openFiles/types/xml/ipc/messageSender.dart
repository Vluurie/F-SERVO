import 'dart:typed_data';

import '../../../../../fileTypeUtils/utils/ByteDataWrapper.dart';
import 'messageFrame.dart';
import 'namedPipeHandler.dart';

mixin MessageSender {
  final NamedPipeHandler _pipeHandler = globalPipeHandler;

  Future<void> sendIntMessage({
    required int id,
    required int typeId,
    required int value,
    required int messageType,
  }) async {
    final wrapper = ByteDataWrapper.allocate(12);
    wrapper.writeInt32(id);
    wrapper.writeUint32(typeId);
    wrapper.writeInt32(value);
    await _sendMessage(messageType, wrapper.buffer.asUint8List(0, wrapper.position));
  }

  Future<void> sendUintMessage({
    required int id,
    required int typeId,
    required int value,
    required int messageType,
  }) async {
    final wrapper = ByteDataWrapper.allocate(12);
    wrapper.writeInt32(id);
    wrapper.writeUint32(typeId);
    wrapper.writeUint32(value);
    await _sendMessage(messageType, wrapper.buffer.asUint8List(0, wrapper.position));
  }

  Future<void> sendObjectIdMessage({
    required int id,
    required int typeId,
    required String objId,
    required int messageType,
  }) async {
    final wrapper = ByteDataWrapper.allocate(14);
    wrapper.writeInt32(id);
    wrapper.writeInt32(typeId);
    wrapper.writeString(objId, StringEncoding.utf8);
    await _sendMessage(messageType, wrapper.buffer.asUint8List(0, wrapper.position));
  }

  Future<void> sendVectorMessage({
    required int id,
    required int typeId,
    required List<double> values,
    required int messageType,
  }) async {
    final wrapper = ByteDataWrapper.allocate(20);
    wrapper.writeInt32(id);
    wrapper.writeUint32(typeId);
    wrapper.writeFloat32(values[0]);
    wrapper.writeFloat32(values[1]);
    wrapper.writeFloat32(values[2]);
    await _sendMessage(messageType, wrapper.buffer.asUint8List(0, wrapper.position));
  }

  // TODO: Need to send phase, quest, or room context with the XML action
  // so we can check the current game state in the SDK and prevent creation if mismatched.
  // We don't need live preview in a place we are not even located.
  //
  // Steps:
  // 1. Extract phase, quest, or room info from the action XML.
  // 2. Include this data in the message payload to the SDK for sendCheckActionExistOrCreate.
  // 3. SDK verifies this against the current state before allowing creation.
  // 4. If mismatched, skip creation.
  //
  // Next: Define where and how to extract this info from the XML File Hierarchy.
  Future<void> sendCheckActionExistOrCreate({
    required int id,
    required int typeId,
    required int actionId,
    required int messageType,
  }) async {
    final wrapper = ByteDataWrapper.allocate(12);
    wrapper.writeUint32(actionId);
    wrapper.writeUint32(id);
    wrapper.writeUint32(typeId);
    await _sendMessage(messageType, wrapper.buffer.asUint8List(0, wrapper.position));
  }

  Future<void> _sendMessage(int messageType, Uint8List payload) async {
    await _pipeHandler.sendBinaryMessage(MessageFrame(
      messageType: messageType,
      payload: payload,
    ));
  }
}
