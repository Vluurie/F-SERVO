
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';

import '../../../fileTypeUtils/dat/datExtractor.dart';
import '../../../utils/utils.dart';
import '../../../widgets/filesView/FileType.dart';
import '../../undoable.dart';
import '../openFileTypes.dart';

class WmbFileData extends OpenFileData {
  WmbFileData(super.name, super.path, { super.secondaryName })
      : super(type: FileType.wmb, icon: Icons.view_in_ar);

  @override
  Future<void> load() async {
    if (loadingState.value != LoadingState.notLoaded)
      return;
    loadingState.value = LoadingState.loading;

    var parent = dirname(path);
    var datDir = "${withoutExtension(parent)}.dat";
    var dttDir = "${withoutExtension(parent)}.dtt";
    if (!await Directory(datDir).exists()) {
      await _tryExtract(datDir);
    }
    if (!await Directory(dttDir).exists()) {
      await _tryExtract(dttDir);
    }

    loadingState.value = LoadingState.loaded;
    setHasUnsavedChanges(false);
    onUndoableEvent(immediate: true);
  }

  Future<void> _tryExtract(String datDir) async {
    var baseName = basename(datDir);
    var datOrigDir = dirname(dirname(datDir));
    var origDat = join(datOrigDir, baseName);
    if (await File(origDat).exists()) {
      if (await File(origDat).length() > 0) {
        try {
          await extractDatFiles(origDat);
        } on Exception catch (e) {
          showToast("Failed to extract $baseName");
        }
      }
    }
  }

  @override
  Future<void> save() async {
    setHasUnsavedChanges(false);
  }

  @override
  Undoable takeSnapshot() {
    var snapshot = WmbFileData(name.value, path, secondaryName: secondaryName.value);
    snapshot.overrideUuid(uuid);
    snapshot.setHasUnsavedChanges(hasUnsavedChanges.value);
    return snapshot;
  }

  @override
  void restoreWith(Undoable snapshot) {
    // TODO: implement restoreWith
  }
}
