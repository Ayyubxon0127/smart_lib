import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kutubxona/widgets/app_logo.dart';

void main() {
  test('generate app icon PNG', () async {
    const sz = 1024.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, sz, sz),
    );

    LogoPainter().paint(canvas, const Size(sz, sz));

    final picture = recorder.endRecording();
    final image = await picture.toImage(sz.toInt(), sz.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    Directory('assets').createSync(recursive: true);
    File('assets/app_icon.png').writeAsBytesSync(bytes);

    print('✅ Saved assets/app_icon.png (${bytes.length} bytes)');
    expect(bytes.length, greaterThan(0));
  });
}
