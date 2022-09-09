
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../customTheme.dart';
import '../stateManagement/FileHierarchy.dart';
import '../stateManagement/nestedNotifier.dart';
import 'HierarchyEntryWidget.dart';

class FileExplorer extends ChangeNotifierWidget {
  FileExplorer({super.key}) : super(notifier: openHierarchyManager);

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends ChangeNotifierState<FileExplorer> {
  bool isDroppingFile = false;

  void openFile(DropDoneDetails details) {
    for (var file in details.files) {
      if (file.path.endsWith(".pak")) {
        if (File(file.path).existsSync())
          openHierarchyManager.openPak(file.path);
        else if (Directory(file.path).existsSync())
          openHierarchyManager.openExtractedPak(file.path);
        else
          throw Exception("File not found: ${file.path}");
      }
      else if (file.path.endsWith(".dat")) {
        if (File(file.path).existsSync())
          openHierarchyManager.openDat(file.path);
        else if (Directory(file.path).existsSync())
          openHierarchyManager.openExtractedDat(file.path);
        else
          throw Exception("File not found: ${file.path}");
      }
      else if (file.path.endsWith(".xml")) {
        openHierarchyManager.openXmlScript(file.path);
      }
      else {
        print("Unsupported file type: ${file.path}");  // TODO show error message
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) => setState(() => isDroppingFile = true),
      onDragExited: (details) => setState(() => isDroppingFile = false),
      onDragDone: (details) {
        isDroppingFile = false;
        openFile(details);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Text("FILE EXPLORER", 
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.all(5),
                    constraints: BoxConstraints(),
                    iconSize: 20,
                    splashRadius: 20,
                    icon: Icon(Icons.unfold_more),
                    onPressed: openHierarchyManager.expandAll,
                  ),
                  IconButton(
                    padding: EdgeInsets.all(5),
                    constraints: BoxConstraints(),
                    iconSize: 20,
                    splashRadius: 20,
                    icon: Icon(Icons.unfold_less),
                    onPressed: openHierarchyManager.collapseAll,
                  ),
                ],
              ),
            ],
          ),
          Divider(height: 1),
          Expanded(
            child: Stack(
              children: [
                ListView(
                  children: openHierarchyManager
                    .map((element) => HierarchyEntryWidget(element))
                    .toList(),
                ),
                if (isDroppingFile)
                  Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: getTheme(context).dropTargetColor,
                    child: Center(
                      child: Text(
                        'Drop file here',
                        style: TextStyle(
                          color: getTheme(context).dropTargetTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
