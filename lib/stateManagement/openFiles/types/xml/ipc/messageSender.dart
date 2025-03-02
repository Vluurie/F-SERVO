import 'dart:developer'; // Import for debug logging
import 'dart:typed_data';

import 'messageByteHelper.dart';
import 'messageFrame.dart';
import 'namedPipeHandler.dart';

mixin MessageSender {
  final NamedPipeHandler _pipeHandler = globalPipeHandler;

  Future<void> sendIntMessage({required int id, required int typeId, required int value, required int messageType}) async {
    Uint8List payload = MessageByteHelper.mergeBytes([
      MessageByteHelper.intToBytes(id, unsafe: true),
      MessageByteHelper.uintToBytes(typeId, unsafe: true),
      MessageByteHelper.intToBytes(value, unsafe: true),
    ]);

    await _sendMessage(messageType, payload);
    log("Sent IntMessage: ID=0x${id.toRadixString(16)}, Value=$value (0x${value.toRadixString(16)})", name: "MessageSender");
  }

  Future<void> sendUintMessage({required int id, required int typeId, required int value, required int messageType}) async {
    Uint8List payload = MessageByteHelper.mergeBytes([
      MessageByteHelper.intToBytes(id, unsafe: true),
      MessageByteHelper.uintToBytes(typeId, unsafe: true),
      MessageByteHelper.uintToBytes(value, unsafe: true),
    ]);

    await _sendMessage(messageType, payload);
    log("Sent UintMessage: ID=0x${id.toRadixString(16)}, Value=$value (0x${value.toRadixString(16)})", name: "MessageSender");
  }

  Future<void> sendObjectIdMessage({required int id, required int typeId, required String objId, required int messageType}) async {
    Uint8List objBytes = MessageByteHelper.stringToBytes(objId, 6);
    Uint8List idBytes = MessageByteHelper.intToBytes(id, unsafe: true);
    Uint8List typeIdBytes = MessageByteHelper.intToBytes(typeId, unsafe: true);

    Uint8List payload = MessageByteHelper.mergeBytes([idBytes, typeIdBytes, objBytes]);

    await _sendMessage(messageType, payload);
    log("Sent ObjectIdMessage: ID=0x${id.toRadixString(16)}, ObjID=${String.fromCharCodes(objBytes)}", name: "MessageSender");
  }

  Future<void> sendVectorMessage({required int id, required int typeId, required List<double> values, required int messageType, required String logLabel}) async {
    Uint8List payload = MessageByteHelper.mergeBytes([
      MessageByteHelper.intToBytes(id, unsafe: true),
      MessageByteHelper.uintToBytes(typeId, unsafe: true),
      MessageByteHelper.vector3ToBytes(values[0], values[1], values[2]),
    ]);

    await _sendMessage(messageType, payload);
    log("Sent $logLabel: ID=0x${id.toRadixString(16)}, Values: (${values[0]}, ${values[1]}, ${values[2]})", name: "MessageSender");
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
  Future<void> sendCheckActionExistOrCreate({required int id, required int typeId, required int actionId, required int messageType, required String logLabel}) async {
    Uint8List payload = MessageByteHelper.mergeBytes([
      MessageByteHelper.uintToBytes(actionId),
      MessageByteHelper.uintToBytes(id),
      MessageByteHelper.uintToBytes(typeId),
    ]);

    await _sendMessage(messageType, payload);
    log("Sending sceneId for $logLabel to Pipe: ID: 0x${id.toRadixString(16)}, actionID = $actionId (0x${actionId.toRadixString(16)})", name: "MessageSender");
  }

  Future<void> _sendMessage(int messageType, Uint8List payload) async {
    log("Sending message: Type=$messageType, Payload Length=${payload.length}", name: "MessageSender");

    MessageFrame frame = MessageFrame(
      messageType: messageType,
      payload: payload,
    );

    await _pipeHandler.sendBinaryMessage(frame);
  }

  // Utility function to convert bytes to a readable hex string
  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }
}
