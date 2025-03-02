import 'package:xml/xml.dart';

import '../ipc/messageSender.dart';
import '../ipc/messageTypes.dart';
import 'syncMessageExtractor.dart';

abstract class SyncGameBase with SyncMessageDocExtractor, MessageSender {
  void syncFromXml(XmlDocument document);
}

class LayoutData {
  List<double> position;
  List<double> rotation;
  List<double> scale;

  LayoutData({
    required this.position,
    required this.rotation,
    required this.scale,
  });

  bool hasChanged(List<double> newValues, List<double> oldValues) {
    for (int i = 0; i < newValues.length; i++) {
      if (newValues[i] != oldValues[i]) return true;
    }
    return false;
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

    if (objId != null && objId.length == 6) {
      sendObjectIdMessage(
        id: id,
        objId: objId,
        messageType: LayoutMessages.setObjId.type,
        typeId: typeId,
      );
    }

    _sendMessageWithType(id, typeId, LayoutMessages.setType.type, newSetType);
    _sendMessageWithType(id, typeId, LayoutMessages.setFlag.type, newSetFlag, isUint: true);
    _sendMessageWithType(id, typeId, LayoutMessages.setRtn.type, newSetRtn);
  }

  void _sendMessageWithType(int id, int typeId, int messageType, int? value,
      {bool isUint = false}) {
    if (value == null) return;

    if (isUint) {
      sendUintMessage(id: id, value: value, messageType: messageType, typeId: typeId);
    } else {
      sendIntMessage(id: id, value: value, messageType: messageType, typeId: typeId);
    }
  }
}


class SyncGameLayout extends SyncGameBase {
  final Map<int, LayoutData> layoutCache;
  final Map<String, int> messageTypeMap;
    final int typeId;

  SyncGameLayout(this.typeId, {
    required this.layoutCache,
    required this.messageTypeMap,
  });

  @override
  void syncFromXml(XmlDocument document) {
    int? id = extractInt(document, "id") ?? -1;

    if (id == -1) return;

    final List<double>? newPosition = extractVector(document, "position");
    final List<double>? newRotation = extractVector(document, "rotation");
    final List<double>? newScale = extractVector(document, "scale");

    LayoutData lastData = layoutCache[id] ??
        LayoutData(
          position: [0.0, 0.0, 0.0],
          rotation: [0.0, 0.0, 0.0],
          scale: [1.0, 1.0, 1.0],
        );

    if (newPosition != null &&
        lastData.hasChanged(newPosition, lastData.position)) {
      _sendVectorMessage(id, newPosition, "position");
      lastData.position = newPosition;
    }

    if (newRotation != null &&
        lastData.hasChanged(newRotation, lastData.rotation)) {
      _sendVectorMessage(id, newRotation, "rotation");
      lastData.rotation = newRotation;
    }

    if (newScale != null && lastData.hasChanged(newScale, lastData.scale)) {
      _sendVectorMessage(id, newScale, "scale");
      lastData.scale = newScale;
    }

    layoutCache[id] = lastData;
  }

  void _sendVectorMessage(int id, List<double> values, String propertyName) {
    int? messageType = messageTypeMap[propertyName];
    if (messageType == null) {
      print("Warning: No message type defined for $propertyName");
      return;
    }

    sendVectorMessage(
      id: id,
      typeId: typeId,
      values: values,
      messageType: messageType,
      logLabel:
          "Set${propertyName[0].toUpperCase()}${propertyName.substring(1)}",
    );
  }

  bool hasData(XmlDocument document) {
    return document.findAllElements("position").isNotEmpty ||
        document.findAllElements("rotation").isNotEmpty ||
        document.findAllElements("scale").isNotEmpty;
  }
}
