import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/rendering.dart';

class SaveService {
  // Capture widget by global key and save PNG to gallery (Android) or to files (iOS)
  static Future<String> saveRepaintBoundary(
    GlobalKey key, {
    int quality = 100,
  }) async {
    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) return 'Permission denied';
      }

      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final dpi = ui.window.devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: dpi);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Save to gallery
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(bytes),
        quality: quality,
        name: 'sketch_${DateTime.now().millisecondsSinceEpoch}',
      );
      return result.toString();
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Optional: save to app documents directory (returns file path)
  static Future<String> saveToDocuments(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/sketch_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
