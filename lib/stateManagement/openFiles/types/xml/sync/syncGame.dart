import 'package:xml/xml.dart';

import '../ipc/messageContext.dart';
import '../ipc/messageSender.dart';
import '../ipc/messageTypes.dart';
import 'syncMessageExtractor.dart';

abstract class SyncGameBase with SyncMessageDocExtractor, MessageSender  {
  void syncFromXml(XmlDocument document);
}


/// uses flat double fields instead of Vector3/List<double> for performance.
/// avoids boxing, reduces GC pressure, and improves memory access speed.
class LayoutData {
  double posX, posY, posZ;
  double rotX, rotY, rotZ;
  double scaleX, scaleY, scaleZ;

  LayoutData({
    required this.posX,
    required this.posY,
    required this.posZ,
    required this.rotX,
    required this.rotY,
    required this.rotZ,
    required this.scaleX,
    required this.scaleY,
    required this.scaleZ,
  });

  bool vectorChanged(double x1, double y1, double z1, double x2, double y2, double z2) {
    return x1 != x2 || y1 != y2 || z1 != z2;
  }

  void updatePosition(double x, double y, double z) {
    posX = x;
    posY = y;
    posZ = z;
  }

  void updateRotation(double x, double y, double z) {
    rotX = x;
    rotY = y;
    rotZ = z;
  }

  void updateScale(double x, double y, double z) {
    scaleX = x;
    scaleY = y;
    scaleZ = z;
  }
}

class SyncGameEntityLayout extends SyncGameBase {
  final int typeId;

  SyncGameEntityLayout({required this.typeId});

  @override
  void syncFromXml(XmlDocument document) {
    int? id = extractInt(document, "id");
    int? newSetType = extractInt(document, "setType");
    int? newSetFlag = extractInt(document, "setFlag");
    int? newSetRtn = extractInt(document, "setRtn");
    String? objId = extractString(document, "objId");

    if (id == null) return;

    final context = MessageContext(id: id, typeId: typeId);

      sendObjectIdMessage(
        context: context.copyWith(objId: objId),
        messageType: LayoutMessages.setObjId.type,
      );

    _sendMessageWithType(context, LayoutMessages.setType.type, newSetType);
    _sendMessageWithType(context, LayoutMessages.setFlag.type, newSetFlag,
        isUint: true);
    _sendMessageWithType(context, LayoutMessages.setRtn.type, newSetRtn);
  }

  void _sendMessageWithType(
    MessageContext context,
    int messageType,
    int? value, {
    bool isUint = false,
  }) {
    if (value == null) return;

    if (isUint) {
      sendUintMessage(
        context: context,
        value: value,
        messageType: messageType,
      );
    } else {
      sendIntMessage(
        context: context,
        value: value,
        messageType: messageType,
      );
    }
  }
}

class SyncGameLayout extends SyncGameBase {
  final Map<int, LayoutData> layoutCache;
  final Map<String, int> messageTypeMap;
  final int typeId;

  SyncGameLayout(
    this.typeId, {
    required this.layoutCache,
    required this.messageTypeMap,
  });

  @override
  void syncFromXml(XmlDocument document) {
    int id = extractInt(document, "id") ?? -1;
    if (id == -1) return;

    final context = MessageContext(id: id, typeId: typeId);

    final position = extractVector(document, "position");
    final rotation = extractVector(document, "rotation");
    final scale = extractVector(document, "scale");

    final data = layoutCache[id] ??
        LayoutData(
          posX: 0.0,
          posY: 0.0,
          posZ: 0.0,
          rotX: 0.0,
          rotY: 0.0,
          rotZ: 0.0,
          scaleX: 1.0,
          scaleY: 1.0,
          scaleZ: 1.0,
        );

    if (position != null &&
        data.vectorChanged(position[0], position[1], position[2], data.posX, data.posY, data.posZ)) {
      _sendVectorMessage(context, position, "position");
      data.updatePosition(position[0], position[1], position[2]);
    }

    if (rotation != null &&
        data.vectorChanged(rotation[0], rotation[1], rotation[2], data.rotX, data.rotY, data.rotZ)) {
      _sendVectorMessage(context, rotation, "rotation");
      data.updateRotation(rotation[0], rotation[1], rotation[2]);
    }

    if (scale != null &&
        data.vectorChanged(scale[0], scale[1], scale[2], data.scaleX, data.scaleY, data.scaleZ)) {
      _sendVectorMessage(context, scale, "scale");
      data.updateScale(scale[0], scale[1], scale[2]);
    }

    layoutCache[id] = data;
  }

  void _sendVectorMessage(MessageContext context, List<double> values, String propertyName) {
    final messageType = messageTypeMap[propertyName];
    if (messageType == null) {
      print("Warning: No message type defined for $propertyName");
      return;
    }

    sendVectorMessage(
      context: context,
      values: values,
      messageType: messageType,
    );
  }

  bool hasData(XmlDocument document) {
    return document.findAllElements("position").isNotEmpty ||
        document.findAllElements("rotation").isNotEmpty ||
        document.findAllElements("scale").isNotEmpty;
  }
}
