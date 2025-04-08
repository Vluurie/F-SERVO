import 'package:xml/xml.dart';

import '../../../../../widgets/filesView/types/xml/xmlActions/XmlActionIngameCreator.dart';
import '../xmlProps/xmlActionProp.dart';
import 'syncGame.dart';

class SyncActionMap {
  final Map<String, SyncAction Function()> _map = {
    "EntityLayoutAction": () => const EntityLayoutAction(),
    "EnemySetAction": () => const EnemySetAction(),
    "EnemySetArea": () => const EnemySetArea(),
    "EntityLayoutArea": () => const EntityLayoutArea(),
    "EnemySupplyAction": () => const EnemySupplyAction(),
    // ...
  };

  SyncAction? create(String actionName) {
    final action = _map[actionName];
    return action != null ? action() : null;
  }
}

enum ActionTypeId {
  entityLayoutAction(0x6e, "EntityLayoutAction"),
  enemySetAction(0x6b, "EnemySetAction"),
  enemySetArea(0x6c, "EnemySetArea"),
  entityLayoutArea(0x6f, "EntityLayoutArea"),
  enemySupplyAction(0x6d, "EnemySupplyAction");

  final int id;
  final String logLabel;

  const ActionTypeId(this.id, this.logLabel);

  static ActionTypeId? fromName(String name) {
    for (var type in ActionTypeId.values) {
      if (type.logLabel == name) return type;
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

abstract class SyncAction {
  final ActionTypeId type;
  const SyncAction(this.type);

  void syncFromXml(XmlDocument document);

  XmlActionIngameCreator? createIngame(XmlActionProp action) => null;
}

class EntityLayoutAction extends SyncAction {
  const EntityLayoutAction() : super(ActionTypeId.entityLayoutAction);

  @override
  void syncFromXml(XmlDocument document) {
    final layObj = SyncGameEntityLayout(typeId: type.id);
    layObj.syncFromXml(document);
  }

  @override
  XmlActionIngameCreator createIngame(XmlActionProp action) {
    return LayoutActionIngameCreator(action, type.id);
  }
}

class EnemySetAction extends SyncAction {
  const EnemySetAction() : super(ActionTypeId.enemySetAction);

  @override
  void syncFromXml(XmlDocument document) {
    final enemySetObj = SyncGameEntityLayout(typeId: type.id);
    enemySetObj.syncFromXml(document);
  }

  @override
  XmlActionIngameCreator createIngame(XmlActionProp action) {
    return LayoutActionIngameCreator(action, type.id);
  }
}

class EnemySetArea extends SyncAction {
  const EnemySetArea() : super(ActionTypeId.enemySetArea);

  @override
  void syncFromXml(XmlDocument document) {
    final areaObj = SyncGameEntityLayout(typeId: type.id);
    areaObj.syncFromXml(document);
  }

  @override
  XmlActionIngameCreator createIngame(XmlActionProp action) {
    return LayoutActionIngameCreator(action, type.id);
  }
}

class EntityLayoutArea extends SyncAction {
  const EntityLayoutArea() : super(ActionTypeId.entityLayoutArea);

  @override
  void syncFromXml(XmlDocument document) {
    final areaObj = SyncGameEntityLayout(typeId: type.id);
    areaObj.syncFromXml(document);
  }

  @override
  XmlActionIngameCreator createIngame(XmlActionProp action) {
    return LayoutActionIngameCreator(action, type.id);
  }
}

class EnemySupplyAction extends SyncAction {
  const EnemySupplyAction() : super(ActionTypeId.enemySupplyAction);

  @override
  void syncFromXml(XmlDocument document) {
    final supplyObj = SyncGameEntityLayout(typeId: type.id);
    supplyObj.syncFromXml(document);
  }

  @override
  XmlActionIngameCreator createIngame(XmlActionProp action) {
    return LayoutActionIngameCreator(action, type.id);
  }
}

class ActionSyncCreator {
  static final SyncActionMap _factory = SyncActionMap();

  static void syncAction(XmlActionProp action, XmlDocument document) {
    final actionName = action.code.strVal;
    if (actionName == null) return;

    final syncAction = _factory.create(actionName);
    if (syncAction != null) {
      syncAction.syncFromXml(document);
    } else {
      print("Action type '$actionName' is not supported.");
    }
  }

  static SyncAction? getSyncAction(String actionName) {
    return _factory.create(actionName);
  }
}
