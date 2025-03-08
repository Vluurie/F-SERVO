import 'dart:typed_data';

import '../../../../../fileTypeUtils/utils/ByteDataWrapper.dart';
import 'messageFrame.dart';
import 'messageTypes.dart';
import 'namedPipeHandler.dart';


class MessageReceiver {
  final NamedPipeHandler pipeHandler;

  MessageReceiver(this.pipeHandler) {
    pipeHandler.onMessageReceived.listen(_handleMessage);
  }

  void _handleMessage(MessageFrame frame) {
    Uint8List payload = frame.payload;
    int messageType = frame.messageType;

    if (!MessageType.types.contains(messageType)) {
      print("Unknown Message Type: 0x${messageType.toRadixString(16)}");
      return;
    }

    if (messageType == PlayerMessages.getPosition.type) {
      _processGetPosition(payload);
    } else {
      print("Received Message Type: 0x${messageType.toRadixString(16)}, Payload: $payload");
    }
  }

  void _processGetPosition(Uint8List payload) {
  if (payload.length < 12) {
    print("Invalid payload length for GetPosition");
    return;
  }

  final wrapper = ByteDataWrapper(payload.buffer);
  double x = wrapper.readFloat32();
  double y = wrapper.readFloat32();
  double z = wrapper.readFloat32();

  print("Received GetPosition: X=$x, Y=$y, Z=$z");
}
}
