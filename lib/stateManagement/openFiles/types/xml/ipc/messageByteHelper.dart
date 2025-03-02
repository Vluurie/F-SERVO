import 'dart:typed_data';

class MessageByteHelper {
  static const Endian _endian = Endian.little;
  static final ByteData _floatBuffer = ByteData(4);
  static final ByteData _vectorBuffer = ByteData(12);

  static Uint8List _toBytes(int value, bool signed, {bool unsafe = false}) {
    if (unsafe) {
      return Uint8List(4)
        ..[0] = value & 0xFF
        ..[1] = (value >> 8) & 0xFF
        ..[2] = (value >> 16) & 0xFF
        ..[3] = (value >> 24) & 0xFF;
    } else {
      final bytes = Uint8List(4);
      final buffer = bytes.buffer.asByteData();
      signed
          ? buffer.setInt32(0, value, _endian)
          : buffer.setUint32(0, value, _endian);
      return bytes;
    }
  }

  static int _fromBytes(Uint8List bytes, bool signed, {bool unsafe = false}) {
    if (unsafe) {
      return (bytes[0]) |
          (bytes[1] << 8) |
          (bytes[2] << 16) |
          (bytes[3] << 24);
    } else {
      final buffer = ByteData.sublistView(bytes);
      return signed ? buffer.getInt32(0, _endian) : buffer.getUint32(0, _endian);
    }
  }

  static Uint8List intToBytes(int value, {bool unsafe = false}) =>
      _toBytes(value, true, unsafe: unsafe);

  static int bytesToInt(Uint8List bytes, {bool unsafe = false}) =>
      _fromBytes(bytes, true, unsafe: unsafe);

  static Uint8List uintToBytes(int value, {bool unsafe = false}) =>
      _toBytes(value, false, unsafe: unsafe);

  static int bytesToUint(Uint8List bytes, {bool unsafe = false}) =>
      _fromBytes(bytes, false, unsafe: unsafe);

  static Uint8List floatToBytes(double value) {
    _floatBuffer.setFloat32(0, value, _endian);
    return _floatBuffer.buffer.asUint8List(0, 4);
  }

  static double bytesToFloat(Uint8List bytes) {
    return ByteData.sublistView(bytes).getFloat32(0, _endian);
  }

  static Uint8List vector3ToBytes(double x, double y, double z) {
    _vectorBuffer.setFloat32(0, x, _endian);
    _vectorBuffer.setFloat32(4, y, _endian);
    _vectorBuffer.setFloat32(8, z, _endian);
    return _vectorBuffer.buffer.asUint8List(0, 12);
  }

  static List<double> bytesToVector3(Uint8List bytes) {
    final buffer = bytes.buffer.asByteData();
    return [
      buffer.getFloat32(0, _endian),
      buffer.getFloat32(4, _endian),
      buffer.getFloat32(8, _endian),
    ];
  }

  static Uint8List stringToBytes(String value, int length) {
    final bytes = Uint8List(length);
    final len = value.length < length ? value.length : length;
    
    for (int i = 0; i < len; i++) {
      bytes[i] = value.codeUnitAt(i);
    }
    
    return bytes;
  }

  static String bytesToString(Uint8List bytes) =>
      String.fromCharCodes(bytes.where((byte) => byte != 0));

  static Uint8List mergeBytes(List<Uint8List> byteLists) =>
      Uint8List.fromList(byteLists.expand((b) => b).toList());
}
