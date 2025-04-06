import 'package:xml/xml.dart';

import '../xmlProps/xmlActionProp.dart';
import 'syncGame.dart';




enum ActionTypeId {
  entityLayoutAction(0x6e, "EntityLayoutAction", true),
  enemySetAction(0x6b, "EnemySetAction", true),
  enemySetArea(0x6c, "EnemySetArea", true),
  entityLayoutArea(0x6f, "EntityLayoutArea", true),
  enemySupplyAction(0x6d, "EnemySupplyAction", true);
  //enemyGenerator(0x29, "EnemyGenerator", false);

  final int id;
  final String logLabel;
  final bool isLayoutAction;

  const ActionTypeId(this.id, this.logLabel, this.isLayoutAction);

  static ActionTypeId? fromName(String name) {
    for (var type in ActionTypeId.values) {
      if (type.name == name) return type;
    }
    return null;
  }

  static ActionTypeId? fromId(int id) {
    for (var type in ActionTypeId.values) {
      if (type.id == id) return type;
    }
    return null;
  }
}


class ActionTypeHandler {
  static final Map<String, ActionTypeId> _actionTypeMap = {
    "EntityLayoutAction": ActionTypeId.entityLayoutAction,
    "EnemySetAction": ActionTypeId.enemySetAction,
    "EnemySetArea": ActionTypeId.enemySetArea,
    "EntityLayoutArea": ActionTypeId.entityLayoutArea,
    "EnemySupplyAction": ActionTypeId.enemySupplyAction,
    //"EnemyGenerator": ActionTypeId.enemyGenerator,
    // ...
  };

  static ActionTypeId? getTypeId(String actionName) {
    return _actionTypeMap[actionName];
  }

  static void syncAction(XmlActionProp action, XmlDocument document) {
    if(action.code.strVal != null) {
    final typeId = getTypeId(action.code.strVal!)?.id;
    if (typeId != null) {
      _syncLayoutAction(typeId, document);
    } else {
      print("Action type '$action' is not supported.");
    }
  }
  }

  static void _syncLayoutAction(int typeId, XmlDocument document) {
    final SyncGameEntityLayout layObj = SyncGameEntityLayout(typeId: typeId);
    layObj.syncFromXml(document);
  }
}