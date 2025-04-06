import 'package:path/path.dart';
import 'package:xml/xml.dart';

import '../../../../../fileTypeUtils/yax/hashToStringMap.dart';
import '../../../../../fileTypeUtils/yax/japToEng.dart';
import '../../../../../utils/utils.dart';
import '../../../../Property.dart';
import '../../../../listNotifier.dart';
import '../../../../undoable.dart';
import '../../../openFilesManager.dart';
import 'charNamesXmlWrapper.dart';
import 'xmlActionProp.dart';

class XmlProp extends ListNotifier<XmlProp> {
  final int tagId;
  final String tagName;
  final Prop value;
  final OpenFileId? file;
  final List<String> parentTags;
  XmlProp? rootProp;

  XmlProp({ required this.file, required this.tagId, String? tagName, Prop? value, String? strValue, List<XmlProp>? children, required this.parentTags, this.rootProp }) : 
  tagName = tagName ?? hashToStringMap[tagId] ?? "UNKNOWN",
        value = value ?? Prop.fromString(strValue ?? "", tagName: tagName, fileId: file),
        super(children ?? [], fileId: file)
         {
    this.value.addListener(_onValueChange);
  }

  XmlProp._fromXml(XmlElement root, { required this.file, required this.parentTags, this.rootProp }) :
   tagId = crc32(root.localName),
        tagName = root.localName,
        value = Prop.fromString(root.childElements.isEmpty ? root.text : "", tagName: root.localName, fileId: file),
        super([], fileId: file) {
    value.addListener(_onValueChange);
    for (var child in root.childElements) {
      add(XmlProp.fromXml(
        child,
        file: file,
        parentTags: [...parentTags, root.localName],
        rootProp: rootProp ?? this,
      ));
    }
  }

  factory XmlProp.fromXml(XmlElement root, {OpenFileId? file,required List<String> parentTags,XmlProp? rootProp,}) 
  {
    var prop = XmlProp._fromXml(root,
        file: file, parentTags: parentTags, rootProp: rootProp);
    if (root.localName == "action") {

      if (parentTags.isEmpty && rootProp == null) {
        prop.rootProp = prop;
        for (var child in prop) {
          child._setRootToSelfWith(prop);
        }
      }
      // rootProp give context of the root so we can get the HAP id the action is currently inserted ingame (or get's inserted new)
      return XmlActionProp(XmlProp(
        tagId: prop.tagId,
        tagName: prop.tagName,
        value: prop.value,
        file: prop.file,
        children: prop.toList(),
        parentTags: prop.parentTags,
        rootProp: prop.rootProp,
      ));
    }

    if (prop.get("name")?.value.toString() == "CharName" && prop.get("text") != null)
      return CharNamesXmlProp(file: file, children: prop.toList());
    // if this is root node, update recursiv.
    if (parentTags.isEmpty && prop.rootProp == null) {
      prop._setRootToSelf();
    }
    return prop;
  }

  void _setRootToSelf() {
    rootProp = this;
    for (var child in this) {
      child._setRootToSelfWith(this);
    }
  }

  void _setRootToSelfWith(XmlProp newRoot) {
    rootProp = newRoot;
    for (var child in this) {
      child._setRootToSelfWith(newRoot);
    }
  }

  XmlProp? get(String tag) {
    var child = where((child) => child.tagName == tag);
    return child.isEmpty ? null : child.first;
  }

  List<XmlProp> getAll(String tag) =>
      where((child) => child.tagName == tag).toList();

  List<String> nextParents([String? next]) => [
    ...parentTags,
   tagName,
    if (next != null)
     next
     ];

  @override
  void dispose() {
    value.dispose();
    super.dispose();
  }

  @override
  void add(XmlProp child) {
    super.add(child);
    _onValueChange();
  }

  @override
  void addAll(Iterable<XmlProp> children) {
    super.addAll(children);
    _onValueChange();
  }

  @override
  void insert(int index, XmlProp child) {
    super.insert(index, child);
    _onValueChange();
  }

  @override
  void remove(XmlProp child) {
    super.remove(child);
    _onValueChange();
  }

  @override
  XmlProp removeAt(int index) {
    var ret = super.removeAt(index);
    _onValueChange();
    return ret;
  }

  @override
  void move(int from, int to) {
    if (from == to) return;
    super.move(from, to);
    _onValueChange();
  }

  @override
  void clear() {
    super.clear();
    _onValueChange();
  }

  void _onValueChange() {
    if (file != null) {
      var file = areasManager.fromId(this.file);
      file?.setHasUnsavedChanges(true);
      file?.contentNotifier.notifyListeners();
      file?.onUndoableEvent();
    }
    notifyListeners();
  }

  XmlElement toXml() {
    var element = XmlElement(XmlName(tagName));
    if (tagName == "UNKNOWN")
      element.attributes.add(XmlAttribute(XmlName("id"), "0x${tagId.toRadixString(16)}"));

          // special attributes
    if (value is StringProp && (value as StringProp).value.isNotEmpty) {
      var translated = japToEng[(value as StringProp).value];
      if (translated != null)
       element.setAttribute("eng", translated);
    } 
    else if (value is HexProp && (value as HexProp).isHashed) {
      element.setAttribute("str", (value as HexProp).strVal);
    }
    // text
    String text;
    if (value is StringProp)
      text = (value as StringProp).toString(shouldTransform: false);
    else
      text = value.toString();
    if (text.isNotEmpty)
     element.children.add(XmlText(text));
    // children
    for (var child in this)
     element.children.add(child.toXml());

    return element;
  }

  @override
  String toString() => "<$tagName>${value.toString()}</$tagName>";

  @override
  Undoable takeSnapshot() {
    var prop = XmlProp(
      tagId: tagId,
      tagName: tagName,
      value: value.takeSnapshot() as Prop,
      file: file,
      children: map((child) => child.takeSnapshot() as XmlProp).toList(),
      parentTags: parentTags,
      rootProp: rootProp,
    );
    prop.overrideUuid(uuid);
    return prop;
  }

  @override
  void restoreWith(Undoable snapshot) {
    var xmlProp = snapshot as XmlProp;
    value.restoreWith(xmlProp.value);
    updateOrReplaceWith(xmlProp.toList(), (child) => child.takeSnapshot() as XmlProp);
  }


  /// With the datFileName we can check if the player is located in the same room as the file he is working with eg. r110.dat -> Room 0x110
  String? get datFileName {
    if (file != null) {
      final openFile = areasManager.fromId(file);
      if (openFile != null) {
        final segments = split(openFile.path);
        final datSegment = segments.firstWhere(
          (segment) => segment.toLowerCase().endsWith('.dat'),
          orElse: () => '',
        );
        return datSegment.isNotEmpty ? datSegment : null;
      }
    }
    return null;
  }
}
