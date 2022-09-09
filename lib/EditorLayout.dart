import 'package:flutter/material.dart';
import 'package:nier_scripts_editor/FileHierarchyExplorer/FileExplorer.dart';
import 'package:nier_scripts_editor/ResizableWidget.dart';

import 'customTheme.dart';
import 'filesView/OpenFilesAreas.dart';

class EditorLayout extends StatelessWidget {
  const EditorLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return ResizableWidget(
        axis: Axis.horizontal,
        percentages: [0.175, 0.65, 0.175],
        draggableThickness: 4,
        lineThickness: 4,
        children: [
          ResizableWidget(
            axis: Axis.vertical,
            percentages: [0.55, 0.45],
            draggableThickness: 5,
            children: [
              FileExplorer(),
              Center(child: Text("Group Editor"))
            ],
          ),
          OpenFilesAreas(),
          Center(child: Text("right")),
        ],
      );
    });
  }
}
