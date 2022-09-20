

import 'package:flutter/material.dart';

import '../../../customTheme.dart';
import '../../../stateManagement/ChangeNotifierWidget.dart';
import '../../../stateManagement/openFilesManager.dart';
import '../../../stateManagement/xmlProps/xmlActionProp.dart';
import '../../../utils.dart';
import '../../misc/Selectable.dart';
import '../simpleProps/TextProp.dart';
import '../simpleProps/XmlPropEditorFactory.dart';

final Map<int, GlobalKey<XmlActionEditorState>> _actionKeys = {};

GlobalKey<XmlActionEditorState>? getActionKey(int id) {
  return _actionKeys[id];
}
GlobalKey<XmlActionEditorState> _getOrMakeKey(int id) {
  if (_actionKeys.containsKey(id))
    return _actionKeys[id]!;
  else {
    var key = GlobalKey<XmlActionEditorState>();
    _actionKeys[id] = key;
    return key;
  }
}

final Set<String> ignoreTagNames = {
  "code",
  "name",
  "id",
  "attribute",
};

final Set<int> spawningActionCodes = {
  crc32("EntityLayoutAction"),
  crc32("EntityLayoutArea"),
  crc32("AreaEntityAction"),
  crc32("EnemySetAction"),
  crc32("EnemySetArea"),
  crc32("EnemyGenerator"),
};

class XmlActionEditor extends ChangeNotifierWidget {
  final XmlActionProp action;

  XmlActionEditor({required this.action})
    : super(key: _getOrMakeKey(action.id.value), notifiers: [action, action.attribute]);

  @override
  State<XmlActionEditor> createState() => XmlActionEditorState();
}

class XmlActionEditorState extends ChangeNotifierState<XmlActionEditor> {
  @override
  Widget build(BuildContext context) {
    return SelectableWidget<XmlActionProp>(
      area: areasManager.getAreaOfFile(widget.action.file!),
      data: widget.action,
      color: getActionPrimaryColor().withOpacity(0.5),
      child: SizedBox(
        width: 450,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            makeActionHeader(),
            makeActionBody(),
          ],
        ),
      ),
    );
  }

  Color getActionPrimaryColor() {
    Color color;
    if (widget.action.attribute.value & 0x8 != 0)
      color = Color.fromARGB(255, 223, 134, 0);
    else if (spawningActionCodes.contains(widget.action.code.value))
      color = Color.fromARGB(255, 62, 145, 65);
    else
      color =Color.fromARGB(255, 30, 129, 209);
    
    if (widget.action.attribute.value & 0x2 != 0)
      color = Color.fromRGBO(color.red ~/ 2, color.green ~/ 2, color.blue ~/ 2, 1);
    
    return color;
  }

  Widget makeActionHeader() {
    return Container(
      decoration: BoxDecoration(
        color: getActionPrimaryColor(),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(getTheme(context).actionBorderRadius!), topRight: Radius.circular(getTheme(context).actionBorderRadius!)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16
                ),
                text: widget.action.code.strVal ?? "UNKNOWN ${widget.action.code.value}"
              )
            ),
            SizedBox(height: 5),
            TextProp(prop: widget.action.name, overflow: TextOverflow.ellipsis,),
          ],
        ),
      ),
    );
  }

  Widget makeActionBody() {
    return Container(
      decoration: BoxDecoration(
        color: getTheme(context).actionBgColor,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(getTheme(context).actionBorderRadius!), bottomRight: Radius.circular(getTheme(context).actionBorderRadius!)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: makeInnerActionBody(),
      ),
    );
  }

  Widget makeInnerActionBody() {
    return Column(
      children: widget.action
        .where((prop) => !ignoreTagNames.contains(prop.tagName))
        .map((prop) => makeXmlPropEditor(prop))
        .toList(),
    );
  }
}
