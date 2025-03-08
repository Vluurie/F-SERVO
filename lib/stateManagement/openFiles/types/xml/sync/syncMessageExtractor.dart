import 'package:xml/xml.dart';

mixin SyncMessageDocExtractor {
  
  int? extractInt(XmlDocument document, String sectionName) {
    final element = document.findAllElements(sectionName).firstOrNull;
    return element != null ? int.tryParse(element.innerText.trim()) : null;
  }

  double? extractFloat(XmlDocument document, String sectionName) {
    final element = document.findAllElements(sectionName).firstOrNull;
    return element != null ? double.tryParse(element.innerText.trim()) : null;
  }

  String? extractString(XmlDocument document, String sectionName) {
    return document.findAllElements(sectionName).firstOrNull?.innerText.trim();
  }

  List<double>? extractVector(XmlDocument document, String sectionName) {
    final element = document.findAllElements(sectionName).firstOrNull;
    if (element == null) return null;

    final values = element.innerText.trim().split(" ").map((v) => double.tryParse(v) ?? 0.0).toList();
    return values.length == 3 ? values : null;
  }
}
