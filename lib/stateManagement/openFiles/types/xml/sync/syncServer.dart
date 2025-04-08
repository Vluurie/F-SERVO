import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../../../../utils/fileOpenCommand.dart';
import '../../../../events/statusInfo.dart';
import '../ipc/messageTypes.dart';
import '../ipc/namedPipeHandler.dart';
import 'syncGame.dart';
import 'syncObjects.dart'; 

const wsPort = 1547;

WebSocket? _activeSocket;
ValueNotifier<bool> canSync = ValueNotifier<bool>(false);
DateTime? serverStartTime;

var _wsMessageStream = StreamController<SyncMessage>.broadcast();
var wsMessageStream = _wsMessageStream.stream;
Map<int, LayoutData> _entityLayoutCache = {};

abstract class WsMessage {
  Map toJson();
}
class SyncMessage extends WsMessage {
  final String method;
  final String uuid;
  final Map args;

  SyncMessage(this.method, this.uuid, this.args);

  SyncMessage.fromJson(Map<String, dynamic> json)
      : method = json["method"],
        uuid = json["uuid"],
        args = json["args"];

  @override
  Map toJson() {
    return {
      "method": method,
      "uuid": uuid,
      "args": args
    };
  }
}
class CustomWsMessage extends WsMessage {
  final String method;
  final Map json;

  CustomWsMessage(this.method, this.json);

  CustomWsMessage.fromJson(Map<String, dynamic> json)
      : method = json["method"],
        json = {
          for (var key in json.keys)
            if (key != "method") key: json[key]
        };

  @override
  Map toJson() {
    return {
      "method": method,
      ...json,
    };
  }
}

void _handleWebSocket(WebSocket client) {
  print("New WebSocket client connected");
  _activeSocket?.close();
  _activeSocket = client;
  canSync.value = true;
  client.listen(_onClientData);
  client.done
      .then((_) => _onClientDone())
      .catchError((e) {
    print("Error in WebSocket client: $e");
    _onClientDone();
  });
  wsSend(SyncMessage("connected", "", {}));
  if (_startupCompleted())
   messageLog.add("Connected");
   if(!globalPipeHandler.isConnected)
   unawaited(globalPipeHandler.connect());
}

void _onClientData(data) {
  print("Received data: $data");
  var jsonData = jsonDecode(data);
  var method = jsonData["method"];
  if (method == "openFiles") {
    var msg = CustomWsMessage.fromJson(jsonData);
    var files = (msg.json["files"] as List).cast<String>();
    onFileOpenCommand(files);
    return;
  }

  var message = SyncMessage.fromJson(jsonData);

  if (method == "update") {
    String? propXml = message.args["propXml"];
    if (propXml == null) return;
    var syncedObject = syncedObjects[message.uuid];
    if (syncedObject == null) return;
     if(globalPipeHandler.isConnected) { 
     int actionTypeId = syncedObject.actionTypeId;
    _procLayout(propXml, actionTypeId);
     }
  }
  _wsMessageStream.add(message);
}

void _procLayout(String xml, int actionTypeId) {
  final Map<String, int> msgTypes = {
    "position": LayoutMessages.setPosition.type,
    "rotation": LayoutMessages.setRotation.type,
    "scale": LayoutMessages.setScale.type,
  };

  final document = XmlDocument.parse(xml);

  final SyncGameLayout lay = SyncGameLayout(
    actionTypeId,
    layoutCache: _entityLayoutCache,
    messageTypeMap: msgTypes,
  );

  if (lay.hasData(document)) {
    lay.syncFromXml(document); 
  }
}

void _onClientDone() {
  print("WebSocket client disconnected");
  _activeSocket = null;
  canSync.value = false;
  if (_startupCompleted()) 
  messageLog.add("Disconnected");
}

void wsSend(WsMessage data) {
  _activeSocket?.add(jsonEncode(data.toJson()));
}

bool _startupCompleted() {
  return DateTime.now().difference(serverStartTime ?? DateTime.now()).inSeconds > 5;
}

void startSyncServer() async {
  try {
    final server = await HttpServer.bind("localhost", wsPort);
    server.transform(WebSocketTransformer()).listen(_handleWebSocket);
    serverStartTime = DateTime.now();
  } catch (e) {
    print("Failed to start local server. Maybe already running");
  }
}
