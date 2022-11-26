
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../../stateManagement/ChangeNotifierWidget.dart';
import '../../../stateManagement/Property.dart';
import '../../../stateManagement/nestedNotifier.dart';
import '../../../stateManagement/openFileTypes.dart';
import '../../../stateManagement/otherFileTypes/McdData.dart';
import '../../../utils/utils.dart';
import '../simpleProps/boolPropIcon.dart';
import 'FontsManager.dart';
import 'McdFontDebugger.dart';
import '../../misc/RowSeparated.dart';
import '../../misc/SmoothScrollBuilder.dart';
import '../../theme/customTheme.dart';
import '../simpleProps/UnderlinePropTextField.dart';
import '../simpleProps/propEditorFactory.dart';
import '../simpleProps/propTextField.dart';
import 'fontOverridesApply.dart';

const _itemsPerPage = 400;

class McdEditor extends ChangeNotifierWidget {
  final McdFileData file;

  McdEditor ({super.key, required this.file }) : super(notifier: file);

  @override
  State<McdEditor> createState() => _McdEditorState();
}

class _McdEditorState extends ChangeNotifierState<McdEditor> {
  int activeTab = 0;

  @override
  void initState() {
    widget.file.load()
      .then((value) {
        setState(() {});
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var loadingIndicator = const SizedBox(
      height: 2,
      child: LinearProgressIndicator(backgroundColor: Colors.transparent,)
    );
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          const SizedBox(height: 35),
          Row(
            children: [
              _makeTabButton(0, "MCD Events"),
              _makeTabButton(1, "Font overrides"),
              _makeTabButton(2, "Font debugger"),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 20,
                decoration: BoxDecoration(
                  color: getTheme(context).textColor!.withOpacity(0.25),
                ),
              ),
              const FontOverridesApplyButton(),
            ]
          ),
          const Divider(height: 1,),
          Expanded(
            child: IndexedStack(
              index: activeTab,
              children: widget.file.loadingState == LoadingState.loaded ? [
                _McdEditorBody(file: widget.file, mcd: widget.file.mcdData!),
                FontsManager(mcd: widget.file.mcdData!),
                if (widget.file.mcdData!.textureWtpPath != null)
                  McdFontDebugger(
                    texturePath: widget.file.mcdData!.textureWtpPath!.value,
                    fonts: widget.file.mcdData!.usedFonts.values.toList(),
                  ),
              ] : List.filled(3, loadingIndicator),
            ),
          ),
        ],
      ),
    );
  }

  Widget _makeTabButton(int index, String text) {
    return Flexible(
      child: SizedBox(
        width: 150,
        height: 40,
        child: TextButton(
            onPressed: () {
              if (activeTab == index)
                return;
              setState(() => activeTab = index);
            },
            style: ButtonStyle(
              backgroundColor: activeTab == index
                ? MaterialStateProperty.all(getTheme(context).textColor!.withOpacity(0.1))
                : MaterialStateProperty.all(Colors.transparent),
              foregroundColor: activeTab == index
                ? MaterialStateProperty.all(getTheme(context).textColor)
                : MaterialStateProperty.all(getTheme(context).textColor!.withOpacity(0.5)),
            ),
            child: Text(
              text,
              textScaleFactor: 1.25,
            ),
          ),
      ),
    );
  }
}

class _MovingEvent {
  final NestedNotifier<McdEvent> src;
  final McdEvent event;
  final int index;

  const _MovingEvent(this.src, this.event, this.index);
}

class _McdEditorBody extends ChangeNotifierWidget {
  final McdFileData file;
  final McdData mcd;
  static final ValueNotifier<_MovingEvent?> movingEvent = ValueNotifier(null);

  _McdEditorBody({ required this.file, required this.mcd })
    : super(notifiers: [mcd.events, movingEvent]);

  @override
  State<_McdEditorBody> createState() => _McdEditorBodyState();
}

typedef _EventWithIndex = Tuple2<int, McdEvent>;
class _McdEditorBodyState extends ChangeNotifierState<_McdEditorBody> {
  final scrollController = ScrollController();
  List<List<_EventWithIndex>> eventPages = [];
  StringProp search = StringProp("");
  BoolProp isRegex = BoolProp(false);
  int currentPage = 0;

  @override
  void initState() {
    search.changesUndoable = false;
    isRegex.changesUndoable = false;
    search.addListener(() {
      setState(() {});
      currentPage = 0;
    });
    super.initState();
  }

  @override
  void dispose() {
    search.dispose();
    isRegex.dispose();
    super.dispose();
  }

  void updateEvents() {
    RegExp searchMatcher;
    try {
      searchMatcher = isRegex.value ? RegExp(search.value, caseSensitive: false) : RegExp(RegExp.escape(search.value), caseSensitive: false);
    } catch (e) {
      return;
    }
    var allEvents = List.generate(
      widget.mcd.events.length,
      (index) => Tuple2(index, widget.mcd.events[index])
    );

    var filteredEvents = allEvents.where((e) {
      var event = e.item2;
      return searchMatcher.hasMatch(event.name.value) ||
        event.paragraphs.any((p) => p.lines.any((l) => searchMatcher.hasMatch(l.text.value)));
    });

    eventPages = List.generate(
      max((filteredEvents.length / _itemsPerPage).ceil(), 1),
      (index) => filteredEvents.skip(index * _itemsPerPage).take(_itemsPerPage).toList()
    );
  }

  @override
  Widget build(BuildContext context) {
    updateEvents();
    
    return Column(
      children: [
        _makeHeader(context),
        Expanded(
          child: Stack(
            children: [
              SmoothScrollBuilder(
                controller: scrollController,
                builder: (context, controller, physics) {
                  return ListView.builder(
                    key: ValueKey(currentPage),
                    controller: controller,
                    physics: physics,
                    itemCount: eventPages[currentPage].length,
                    itemBuilder: (context, i) {
                      return _McdEventEditor(
                        file: widget.file,
                        event: eventPages[currentPage][i].item2,
                        events: widget.mcd.events,
                        altColor: i % 2 == 1,
                        index: eventPages[currentPage][i].item1,
                      );
                    }
                  );
                },
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    onPressed: _McdEditorBody.movingEvent.value == null
                      ? () {
                        widget.mcd.addEvent(search.value);
                        _setPage(eventPages.length - 1);
                        waitForNextFrame().then((_) {
                          scrollController.jumpTo(scrollController.position.maxScrollExtent);
                        });
                      }
                      : () => _McdEditorBody.movingEvent.value = null,
                    foregroundColor: getTheme(context).textColor,
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _McdEditorBody.movingEvent.value == null ? 0 : 0.125,
                      child: const Icon(Icons.add),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _makeHeader(BuildContext context) {
    return Material(
      color: getTheme(context).tableBgColor,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, right: 8, left: 8, bottom: 8),
        child: Row(
          children: [
            Flexible(
              flex: 2,
              child: SizedBox(
                width: 300,
                child: UnderlinePropTextField(
                  prop: search,
                  options: const PropTFOptions(
                    hintText: "Search",
                    useIntrinsicWidth: false,
                  ),
                ),
              ),
            ),
            BoolPropIconButton(
              prop: isRegex,
              icon: Icons.auto_awesome,
              tooltip: "Regex"
            ),
            const SizedBox(width: 8),
            const Flexible(fit: FlexFit.tight, flex: 3, child: Text("")),
            if (eventPages.length > 1) ...[
              TextButton.icon(
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(EdgeInsets.zero),
                ),
                onPressed: currentPage > 0 ? () => _setPage(currentPage - 1) : null,
                icon: const Icon(Icons.arrow_left, size: 20,),
                label: const Text(""),
              ),
              for (var i = 0; i < eventPages.length; i++)
                TextButton(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.zero),
                    foregroundColor: MaterialStateProperty.resolveWith((states) =>
                      states.contains(MaterialState.disabled)
                        ? Theme.of(context).colorScheme.primary
                        : getTheme(context).textColor
                    ),
                  ),
                  onPressed: currentPage != i ? () => _setPage(i) : null,
                  child: Text("${i + 1}"),
                ),
              TextButton.icon(
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(EdgeInsets.zero),
                ),
                onPressed: currentPage < eventPages.length - 1 ? () => _setPage(currentPage + 1) : null,
                icon: const Icon(Icons.arrow_right, size: 20,),
                label: const Text(""),
              ),
            ].map((w) => ConstrainedBox(
              constraints: BoxConstraints.tight(const Size(30, 40)),
              child: w,
            )).toList(),
          ],
        ),
      ),
    );
  }

  void _setPage(int page) {
    currentPage = page;
    scrollController.jumpTo(0);
    setState(() {});
  }
}

class _McdEventEditor extends ChangeNotifierWidget {
  final McdFileData file;
  final McdEvent event;
  final NestedNotifier<McdEvent> events;
  final bool altColor;
  final int index;

  _McdEventEditor({ required this.file, required this.event, required this.events, required this.altColor, required this.index })
    : super(notifiers: [event.paragraphs, event.name]);

  @override
  State<_McdEventEditor> createState() => _McdEventEditorState();
}

class _McdEventEditorState extends ChangeNotifierState<_McdEventEditor> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.altColor ? getTheme(context).tableBgAltColor : getTheme(context).tableBgColor,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RowSeparated(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: makePropEditor(
                      widget.event.name, const PropTFOptions(
                        useIntrinsicWidth: false,
                        constraints: BoxConstraints.tightFor(height: 35),
                      )
                    )),
                    IconButton(
                      onPressed: () {
                        if (_McdEditorBody.movingEvent.value?.event != widget.event) {
                          _McdEditorBody.movingEvent.value = _MovingEvent(
                            widget.events,
                            widget.event,
                            widget.index,
                          );
                        } else {
                          _McdEditorBody.movingEvent.value = null;
                        }
                      },
                      iconSize: 20,
                      splashRadius: 20,
                      icon: const Icon(Icons.swap_vert),
                    ),
                    IconButton(
                      onPressed: () {
                        var mcd = widget.file.mcdData!;
                        mcd.removeEvent(mcd.events.indexOf(widget.event));
                      },
                      iconSize: 20,
                      splashRadius: 20,
                      icon: const Icon(Icons.delete),
                    ),
                  ]
                ),
                const SizedBox(height: 5,),
                for (int i = 0; i < widget.event.paragraphs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: _McdParagraphEditor(
                      paragraph: widget.event.paragraphs[i],
                      event: widget.event,
                    ),
                  ),
                const SizedBox(height: 5,),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Tooltip(
                    message: "Add Paragraph",
                    waitDuration: const Duration(milliseconds: 500),
                    child: IconButton(
                      onPressed: () => widget.event.addParagraph(widget.file.mcdData!.usedFonts.keys.firstWhere((id) => id != 0)),
                      constraints: BoxConstraints.tight(const Size(30, 30)),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add),
                      splashRadius: 20,
                    ),
                  ),
                ),
              ],
            ),
            if (_McdEditorBody.movingEvent.value != null)
              Positioned(
                right: 0,
                left: 0,
                top: 40,
                bottom: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: _McdEventInsertionMarker(
                    events: widget.file.mcdData!.events,
                    index: widget.index,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _McdEventInsertionMarker extends StatefulWidget {
  final NestedNotifier<McdEvent> events;
  final int index;

  const _McdEventInsertionMarker({ required this.events, required this.index });

  @override
  State<_McdEventInsertionMarker> createState() => _McdEventInsertionMarkerState();
}

class _McdEventInsertionMarkerState extends State<_McdEventInsertionMarker> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    bool isEventTarget = _McdEditorBody.movingEvent.value!.event != widget.events[widget.index];
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: isHovering && isEventTarget ? 1.2 : 1,
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            if (!isEventTarget) {
              _McdEditorBody.movingEvent.value = null;
              return;
            }
            var curIndex = _McdEditorBody.movingEvent.value!.index;
            if (curIndex != widget.index && _McdEditorBody.movingEvent.value!.src == widget.events) {
              var newIndex = widget.index;
              widget.events.move(curIndex, newIndex);
            } else if (_McdEditorBody.movingEvent.value!.src != widget.events) {
              _McdEditorBody.movingEvent.value!.event.file = widget.events[widget.index].file;
              widget.events.insert(widget.index, _McdEditorBody.movingEvent.value!.event);
              _McdEditorBody.movingEvent.value!.src.remove(_McdEditorBody.movingEvent.value!.event);
            }
            _McdEditorBody.movingEvent.value = null;
          },
          iconSize: 100,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          icon: Icon(
            isEventTarget ? Icons.start_rounded : Icons.expand_less_rounded,
            shadows: const [
              Shadow(
                blurRadius: 10,
                color: Colors.black,
              ),
              Shadow(
                blurRadius: 20,
                color: Colors.black,
              ),
              Shadow(
                blurRadius: 40,
                color: Colors.black,
              ),
              Shadow(
                blurRadius: 80,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _McdParagraphEditor extends ChangeNotifierWidget {
  final McdParagraph paragraph;
  final McdEvent event;

  _McdParagraphEditor({ required this.paragraph, required this.event }) : super(notifier: paragraph.lines);

  @override
  State<_McdParagraphEditor> createState() => __McdParagraphEditorState();
}

class __McdParagraphEditorState extends ChangeNotifierState<_McdParagraphEditor> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // info
        Row(
          children: [
            const Expanded(
              child: Text(
                "Paragraph:",
                textScaleFactor: 1.1,
              ),
            ),
            const SizedBox(width: 10,),
            const Text("fontID "),
            makePropEditor<UnderlinePropTextField>(widget.paragraph.fontId),
            const SizedBox(width: 4,),
            IconButton(
              onPressed: () {
                widget.event.removeParagraph(widget.event.paragraphs.indexOf(widget.paragraph));
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tight(const Size(30, 30)),
              splashRadius: 18,
              icon: const Icon(Icons.remove),
            ),
          ],
        ),
        const SizedBox(height: 5,),
        // paragraphs
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i <  widget.paragraph.lines.length; i++) 
              Row(
                key: Key(widget.paragraph.lines[i].uuid),
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: makePropEditor<UnderlinePropTextField>(widget.paragraph.lines[i].text),
                    ),
                  ),
                  const SizedBox(width: 10,),
                  IconButton(
                    onPressed: () => widget.paragraph.removeLine(i),
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    splashRadius: 18,
                    constraints: BoxConstraints.tight(const Size(25, 25)),
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 6,),
                ],
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: "Add Line",
                waitDuration: const Duration(milliseconds: 500),
                child: IconButton(
                  onPressed: () => widget.paragraph.addLine(),
                  constraints: BoxConstraints.tight(const Size(25, 25)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  splashRadius: 18,
                  iconSize: 18,
                  icon: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10,),
      ],
    );
  }
}
