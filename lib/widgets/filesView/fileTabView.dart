import 'dart:math';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'FileTabEntry.dart';
import 'TextFileEditor.dart';
import 'package:window_manager/window_manager.dart';

import '../../stateManagement/openFilesManager.dart';
import '../../stateManagement/nestedNotifier.dart';
import '../../customTheme.dart';
import '../../stateManagement/openFileContents.dart';
import '../../utils.dart';


class FileTabView extends ChangeNotifierWidget {
  final FilesAreaManager viewArea;
  
  const FileTabView(this.viewArea, {Key? key}) : 
    super(key: key, notifier: viewArea);

  @override
  State<FileTabView> createState() => _FileTabViewState();
}

class _FileTabViewState extends ChangeNotifierState<FileTabView> {
  ScrollController tabBarScrollController = ScrollController();
  String? prevActiveUuid;
  bool isDroppingFile = false;
  Map<OpenFileData, Widget> cachedEditors = {};

  @override
  void onNotified() {
    var newActiveUuid = widget.viewArea.currentFile?.uuid;
    if (prevActiveUuid != newActiveUuid && newActiveUuid != null)
      scrollTabIntoView(newActiveUuid);
    prevActiveUuid = newActiveUuid;

    super.onNotified();
  }

  void scrollTabIntoView(String uuid) {
    var viewWidth = (context.findRenderObject() as RenderBox).size.width;
    
    var fileData = widget.viewArea.firstWhere((f) => f.uuid == uuid);
    var index = widget.viewArea.indexOf(fileData);
    var tabPos = max(0.0, index * 150.0 - 15);
    var tabEnd = tabPos + 150.0 + 30;

    var scrollAreaStart = tabBarScrollController.offset;
    var scrollAreaEnd = tabBarScrollController.offset + viewWidth;

    if (tabPos < scrollAreaStart)
      tabBarScrollController.animateTo(tabPos, duration: Duration(milliseconds: 250), curve: Curves.ease);
    else if (tabEnd > scrollAreaEnd)
      tabBarScrollController.animateTo(tabEnd - viewWidth, duration: Duration(milliseconds: 250), curve: Curves.ease);
  }

  void openFiles(List<XFile> files) async {
    if (files.isEmpty)
      return;
    OpenFileData? firstFile;
    for (var file in files) {
      var newFileData = areasManager.openFile(file.path, toArea: widget.viewArea);
      firstFile ??= newFileData;
    }
    if (firstFile != null)
      widget.viewArea.currentFile = firstFile;
    windowManager.focus();
    setState(() {});
  }

  void pruneCachedWidgets() {
    var toRemove = <OpenFileData>[];
    for (var entry in cachedEditors.entries) {
      if (entry.key != widget.viewArea.currentFile && !widget.viewArea.contains(entry.key)) {
        toRemove.add(entry.key);
      }
    }
   
    for (var key in toRemove)
      cachedEditors.remove(key);
  }

  Widget getOrMakeFileEditor(OpenFileData file) {
    if (cachedEditors.containsKey(file))
      return cachedEditors[file]!;
    var fileContent = fileContentsManager.getContent(file) as FileTextContent;
    Widget newEntry = TextFileEditor(
      file: fileContent
    );
    newEntry = SingleChildScrollView(
      key: fileContent.key,
      controller: fileContent.scrollController,
      child: newEntry,
    );
    cachedEditors[file] = newEntry;
    return newEntry;
  }

  @override
  Widget build(BuildContext context) {
    pruneCachedWidgets();

    return DropTarget(
      onDragEntered: (details) => setState(() => isDroppingFile = true),
      onDragExited: (details) => setState(() => isDroppingFile = false),
      onDragDone: (details) {
        isDroppingFile = false;
        openFiles(details.files);
      },
      child: setupShortcuts(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 30,
              child: Listener(
                onPointerSignal: (event) {
                  if (event is! PointerScrollEvent)
                    return;
                  PointerScrollEvent scrollEvent = event;
                  var delta = scrollEvent.scrollDelta.dy != 0 ? scrollEvent.scrollDelta.dy : scrollEvent.scrollDelta.dx;
                  var newOffset = tabBarScrollController.offset + delta;
                  newOffset = clamp(newOffset, 0, tabBarScrollController.position.maxScrollExtent);
                  tabBarScrollController.jumpTo(
                    newOffset,
                    // duration: Duration(milliseconds: 3000 ~/ 60),
                    // curve: Curves.linear
                  );
                },
                child: ReorderableListView(
                  scrollController: tabBarScrollController,
                  scrollDirection: Axis.horizontal,
                  onReorder: (int oldIndex, int newIndex) => widget.viewArea.move(oldIndex, newIndex),
                  buildDefaultDragHandles: false,
                  physics: const NeverScrollableScrollPhysics(),
                  children: widget.viewArea
                    .map((file,) => ReorderableDragStartListener(
                      key: Key(file.uuid),
                      index: widget.viewArea.indexOf(file),
                      child: FileTabEntry(
                        file: file,
                        area: widget.viewArea
                      ),
                    )
                    )
                    .toList(),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  widget.viewArea.currentFile != null
                    ? getOrMakeFileEditor(widget.viewArea.currentFile!)
                    : Center(child: Text('No file open')),
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
            ),
          ]
        ),
      ),
    );
  }

  Widget setupShortcuts({ required Widget child }) {
    return GestureDetector(
      onTap: () => areasManager.activeArea = widget.viewArea,
      child: child,
    );
  }
}

/// An ActionDispatcher that logs all the actions that it invokes.
class LoggingActionDispatcher extends ActionDispatcher {
  @override
  Object? invokeAction(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    print('Action invoked: $action($intent) from $context');
    super.invokeAction(action, intent, context);

    return null;
  }
}
