import 'dart:typed_data';

class MessageFrame {
  final int messageType;
  final Uint8List payload;

  MessageFrame({required this.messageType, required this.payload});

  Uint8List toBytes() {
    final ByteData header = ByteData(8);
    header.setUint32(0, messageType, Endian.little);
    header.setUint32(4, payload.length, Endian.little);

    return Uint8List.fromList([...header.buffer.asUint8List(), ...payload]);
  }

static MessageFrame fromBytes(Uint8List data) {
  print("Received Raw Data: ${data.toList()}");

  if (data.length < 8) {
    throw FormatException("Invalid message format: Header too short.");
  }

  final ByteData byteData = ByteData.sublistView(data);
  final int messageType = byteData.getUint32(0, Endian.little);
  final int payloadSize = byteData.getUint32(4, Endian.little);

  if (data.length < 8 + payloadSize) {
    throw FormatException(
      "Payload size mismatch. Expected $payloadSize bytes, but got ${data.length - 8} bytes.");
  }

  final Uint8List payload = data.sublist(8, 8 + payloadSize);

  return MessageFrame(
    messageType: messageType,
    payload: payload,
  );
}

  @override
  String toString() {
    return "MessageFrame(type: $messageType, payloadSize: ${payload.length})";
  }
}
