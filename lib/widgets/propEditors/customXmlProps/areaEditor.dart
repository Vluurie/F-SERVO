
import 'package:flutter/material.dart';

import '../../../customTheme.dart';
import '../../../stateManagement/ChangeNotifierWidget.dart';
import '../../../stateManagement/Property.dart';
import '../../../stateManagement/xmlProps/xmlProp.dart';
import '../../../utils.dart';
import '../../misc/CustomIcons.dart';
import '../../misc/selectionPopup.dart';
import '../simpleProps/XmlPropEditorFactory.dart';
import '../simpleProps/propEditorFactory.dart';
import 'transformsEditor.dart';

final _typeBoxArea = crc32("app::area::BoxArea");
final _typeCylinderArea = crc32("app::area::CylinderArea");
final _typeSphereArea = crc32("app::area::SphereArea");
final _areaIcons = {
  _typeBoxArea: CustomIcons.cube,
  _typeCylinderArea: CustomIcons.cylinder,
  _typeSphereArea: CustomIcons.sphere,
};

class AreaEditor extends ChangeNotifierWidget {
  final bool showDetails;
  final XmlProp prop;

  AreaEditor({super.key, required this.prop, required this.showDetails}) : super(notifier: prop);

  @override
  State<AreaEditor> createState() => _AreaEditorState();
}

class _AreaEditorState extends ChangeNotifierState<AreaEditor> {
  @override
  Widget build(BuildContext context) {
    var type = (widget.prop[0].value as HexProp).value;
    var parent = widget.prop.get("parent");
    var radius = widget.prop.get("radius");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 37,
            height: 37,
            child: OutlinedButton(
              onPressed: () async {
                var selection = await showSelectionPopup<int>(context, [
                  if (type != _typeBoxArea)
                    SelectionPopupConfig(icon: CustomIcons.cube, name: "Box", getValue: () => _typeBoxArea),
                  if (type != _typeCylinderArea)
                    SelectionPopupConfig(icon: CustomIcons.cylinder, name: "Cylinder", getValue: () => _typeCylinderArea),
                  if (type != _typeSphereArea)
                    SelectionPopupConfig(icon: CustomIcons.sphere, name: "Sphere", getValue: () => _typeSphereArea),
                ]);
                if (selection == null)
                  return;
                convertTo(selection);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: getTheme(context).textColor,
                padding: EdgeInsets.zero,
                side: BorderSide(
                  color: getTheme(context).textColor!.withOpacity(0.5),
                  width: 0.5,
                ),
              ),
              child: Icon(_areaIcons[type]!, size: 35),
            ),
          ),
          SizedBox(width: 5),
          Container(width: 4, color: getTheme(context).editorBackgroundColor,),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(
                  color: getTheme(context).formElementBgColor!,
                  width: 3,
                )),
              ),
              padding: EdgeInsets.only(left: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (parent != null)
                    makeXmlPropEditor(parent, widget.showDetails),
                  TransformsEditor(
                    parent: widget.prop,
                    canBeRotated: type != _typeSphereArea,
                    canBeScaled: type != _typeSphereArea,
                    itemsCanBeRemoved: false,
                  ),
                  if (radius != null)
                    Row(
                      children: [
                        Icon(CustomIcons.radius, size: 18),
                        SizedBox(width: 10),
                        makePropEditor(radius.value),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void convertTo(int type) {
    var prop = widget.prop;
    var curType = prop[0].value as HexProp;
    if (type == curType.value)
      return;
    
    // add rotation, scale, height
    if (type == _typeBoxArea || type == _typeCylinderArea) {
      if (curType.value == _typeSphereArea) {
        var posI = prop.indexWhere((e) => e.tagName == "position");
        prop.insert(posI + 1, XmlProp(file: prop.file, tagId: crc32("rotation"), tagName: "rotation", value: VectorProp([0, 0, 0])));
        prop.insert(posI + 1, XmlProp(file: prop.file, tagId: crc32("scale"), tagName: "scale", value: VectorProp([1, 1, 1])));
        prop.add(XmlProp(file: prop.file, tagId: crc32("height"), tagName: "height", value: NumberProp(1, false)));
      }
    }
    // remove rotation, scale, height
    else {
      prop.removeWhere((e) => e.tagName == "rotation" || e.tagName == "scale" || e.tagName == "height");
    }
    // add points
    if (type == _typeBoxArea) {
      prop.insert(prop.length - 1, XmlProp(file: prop.file, tagId: crc32("points"), tagName: "points", value: VectorProp([-1, -1, 1, -1, 1, 1, -1, 1])));
    }
    // remove points
    else {
      prop.removeWhere((e) => e.tagName == "points");
    }
    // add radius
    if (type == _typeCylinderArea || type == _typeSphereArea) {
      if (curType.value == _typeBoxArea) {
        var insertI = getNextInsertIndexAfter(prop, ["scale", "rotation", "position"]);
        prop.insert(insertI, XmlProp(file: prop.file, tagId: crc32("radius"), tagName: "radius", value: NumberProp(1, false)));
      }
    }
    // remove radius
    else {
      prop.removeWhere((e) => e.tagName == "radius");
    }

    curType.value = type;
  }
}
