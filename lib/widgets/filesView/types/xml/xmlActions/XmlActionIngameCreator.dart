import '../../../../../stateManagement/openFiles/types/xml/ipc/messageSender.dart';
import '../../../../../stateManagement/openFiles/types/xml/ipc/messageTypes.dart';
import '../../../../../stateManagement/openFiles/types/xml/ipc/namedPipeHandler.dart';
import '../../../../../stateManagement/openFiles/types/xml/sync/actionTypeHandler.dart';
import '../../../../../stateManagement/openFiles/types/xml/sync/syncServer.dart';
import '../../../../../stateManagement/openFiles/types/xml/xmlProps/xmlActionProp.dart';
import '../../../../../stateManagement/openFiles/types/xml/xmlProps/xmlProp.dart';


abstract class XmlActionIngameCreator with MessageSender {
  final XmlActionProp action;

  XmlActionIngameCreator(this.action);

  void create();
  
  int? extractActionId() {
    var prop = action.get("id");
    String? idStr = prop?.value.toString();
    return idStr != null ? int.tryParse(idStr.replaceAll("0x", ""), radix: 16) : null;
  }

  int? extractIdFromProp(XmlProp? prop, String tagName) {
    var idProp = prop?.get(tagName);
    String? idStr = idProp?.value.toString();
    return idStr != null ? int.tryParse(idStr.replaceAll("0x", ""), radix: 16) : null;
  }
}

class XmlActionIngameCreatorFactory {
  static XmlActionIngameCreator? createHandler(XmlActionProp action) {
    String? code = action.code.strVal;
    if (code == null || code.isEmpty) return null;

    final actionType = ActionTypeHandler.getTypeId(code);
    if (actionType == null) return null;

    if (actionType.isLayoutAction) {
      return LayoutActionHandler(action, actionType);
     }
     //else if {
    //   return EnemyGeneratorHandler(action, actionType);
    // }
    return null;
  }
}

class XmlActionIngameCreatorManager {
  final XmlActionProp action;

  XmlActionIngameCreatorManager({required this.action});

  void create() {
    if (!canSync.value && !globalPipeHandler.isConnected) return;
    final creator = XmlActionIngameCreatorFactory.createHandler(action);
    creator?.create();
  }
}

class LayoutActionHandler extends XmlActionIngameCreator {
  final ActionTypeId actionType;

  LayoutActionHandler(super.action, this.actionType);

  @override
  void create() {
    int? actionId = extractActionId();
    if (actionId == null) return;

    int? entityId = _extractEntityId();
    if (entityId == null) return;

    sendCheckActionExistOrCreate(
      id: entityId,
      typeId: actionType.id,
      actionId: actionId,
      messageType: LayoutMessages.checkExistOrCreate.type
    );
  }

  int? _extractEntityId() {
    var layouts = action.get("layouts");
    var normal = layouts?.get("normal");
    var inner = normal?.get("layouts");
    var val = inner?.get("value");
    return extractIdFromProp(val, "id");
  }
}