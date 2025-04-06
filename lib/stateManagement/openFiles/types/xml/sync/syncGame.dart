import 'package:xml/xml.dart';

import '../ipc/messageContext.dart';
import '../ipc/messageSender.dart';
import '../ipc/messageTypes.dart';
import 'syncMessageExtractor.dart';

abstract class SyncGameBase with SyncMessageDocExtractor, MessageSender  {
  void syncFromXml(XmlDocument document);
}


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

    if (newSetType != null) {
      sendUintMessage(
        context: context,
        value: newSetType,
        messageType: LayoutMessages.setType.type,
      );
    }
    if (newSetFlag != null) {
      sendUintMessage(
        context: context,
        value: newSetFlag,
        messageType: LayoutMessages.setFlag.type,
      );
    }
    if (newSetRtn != null) {
      sendUintMessage(
        context: context,
        value: newSetRtn,
        messageType: LayoutMessages.setRtn.type,
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

    _syncVector(
      document,
      "position",
      data.posX,
      data.posY,
      data.posZ,
      data.updatePosition,
      context,
      defaultValue: 0.0,
    );
    _syncVector(
      document,
      "rotation",
      data.rotX,
      data.rotY,
      data.rotZ,
      data.updateRotation,
      context,
      defaultValue: 0.0,
    );
    _syncVector(
      document,
      "scale",
      data.scaleX,
      data.scaleY,
      data.scaleZ,
      data.updateScale,
      context,
      defaultValue: 1.0,
    );

    layoutCache[id] = data;
  }

  void _syncVector(
    XmlDocument document,
    String section,
    double currentX,
    double currentY,
    double currentZ,
    void Function(double, double, double) updateFunc,
    MessageContext context, {
    required double defaultValue,
  }) {
    final element = document.findAllElements(section).firstOrNull;
    if (element == null) return;
    final parts = element.innerText.trim().split(" ");
    if (parts.length != 3) return;
    final x = double.tryParse(parts[0]) ?? defaultValue;
    final y = double.tryParse(parts[1]) ?? defaultValue;
    final z = double.tryParse(parts[2]) ?? defaultValue;
    if (x != currentX || y != currentY || z != currentZ) {
      final int? messageType = messageTypeMap[section];
      if (messageType != null) {
        sendVectorMessage(
          context: context,
          x: x,
          y: y,
          z: z,
          messageType: messageType,
        );
      }
      updateFunc(x, y, z);
    }
  }

  bool hasData(XmlDocument document) {
    return document.findAllElements("position").isNotEmpty ||
        document.findAllElements("rotation").isNotEmpty ||
        document.findAllElements("scale").isNotEmpty;
  }
}
