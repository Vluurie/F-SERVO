import '../../../../../stateManagement/openFiles/types/xml/ipc/messageContext.dart';
import '../../../../../stateManagement/openFiles/types/xml/ipc/messageResponse.dart';
import '../../../../../stateManagement/openFiles/types/xml/ipc/messageSender.dart';
import '../../../../../stateManagement/openFiles/types/xml/ipc/messageTypes.dart';
import '../../../../../stateManagement/openFiles/types/xml/ipc/namedPipeHandler.dart';
import '../../../../../stateManagement/openFiles/types/xml/sync/syncActionCreator.dart';
import '../../../../../stateManagement/openFiles/types/xml/sync/syncServer.dart';
import '../../../../../stateManagement/openFiles/types/xml/xmlProps/xmlActionProp.dart';
import '../../../../../stateManagement/openFiles/types/xml/xmlProps/xmlProp.dart';
import '../../../../../utils/utils.dart';

abstract class XmlActionIngameCreator
    with MessageSender, MessageResponseHandler {
  final XmlActionProp action;

  XmlActionIngameCreator(this.action);

  void create();

  /// When a user syncs an action from a file, we first check if he (ingame) is located at the same room (or close to it)
  /// If the played char is not in same room, the HAP he works with is not loaded ingame probably.
  Future<bool> savetyCheck(XmlActionProp action) async {
    if (action.datFileName != null) {
      int? roomNo = roomNumberByDatName(action.datFileName!);
      if (roomNo != null) {
        await sendUintMessage(
          context: MessageContext.none(),
          messageType: CheckMessages.isInSameRoom.type,
          value: roomNo,
        );

        final isSameRoom =
            await waitForCheckResponse(CheckMessages.isInSameRoom.type);
        if (!isSameRoom) {
          print("Warning: Action is in a different room. Ensure you are located on the same place as this Action is located ingame.");
          return false;
        } else {
          return true;
        }
      }
      return false;
    }
    return false;
  }

  int? extractActionId() {
    var prop = action.get("id");
    String? idStr = prop?.value.toString();
    return idStr != null
        ? int.tryParse(idStr.replaceAll("0x", ""), radix: 16)
        : null;
  }

  int? extractIdFromProp(XmlProp? prop, String tagName) {
    var idProp = prop?.get(tagName);
    String? idStr = idProp?.value.toString();
    return idStr != null
        ? int.tryParse(idStr.replaceAll("0x", ""), radix: 16)
        : null;
  }
}

class XmlActionIngameCreatorFactory {
  static XmlActionIngameCreator? createHandler(XmlActionProp action) {
    String? code = action.code.strVal;
    if (code == null || code.isEmpty) return null;

    final syncAction = ActionSyncCreator.getSyncAction(code);
    return syncAction?.createIngame(action);
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

class LayoutActionIngameCreator extends XmlActionIngameCreator {
  final int typeId;

  LayoutActionIngameCreator(super.action, this.typeId);

  @override
  void create() async {
    if (action.hapId == null) {
      return;
    }

    int? hapId = int.tryParse(action.hapId!);
    if (hapId == null) {
      return;
    }

    int? actionId = extractActionId();
    if (actionId == null) {
      return;
    }

    int? entityId = _extractEntityId();
    if (entityId == null) {
      return;
    }

    String? objId = _extractObjId();
    if (objId == null) {
      return;
    }

    bool isSafe = await savetyCheck(action);
    if (!isSafe) {
      return;
    }
    final context = MessageContext(
      id: entityId,
      typeId: typeId,
      actionId: actionId,
      hapId: hapId,
      objId: objId
    );

    await sendCheckActionExistOrCreate(
      context: context,
      messageType: LayoutMessages.checkExistOrCreate.type,
    );
  }

  int? _extractEntityId() {
    var layouts = action.get("layouts");
    var normal = layouts?.get("normal");
    var inner = normal?.get("layouts");
    var val = inner?.get("value");
    return extractIdFromProp(val, "id");
  }

  String? _extractObjId() {
    var layouts = action.get("layouts");
    var normal = layouts?.get("normal");
    var inner = normal?.get("layouts");
    var val = inner?.get("value");
    var prop = val?.get("objId");

    return prop?.value.toString();
  }
}
