import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/stroke.dart';

class DrawingCanvas extends StatefulWidget {
  final GlobalKey repaintKey;

  const DrawingCanvas({super.key, required this.repaintKey});

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final List<Stroke> _strokes = [];
  final List<Stroke> _undone = [];
  Color currentColor = Colors.black;
  double strokeWidth = 4.0;
  bool isEraser = false;

  void startStroke(Offset localPos) {
    setState(() {
      _strokes.add(
        Stroke(
          points: [localPos],
          color: currentColor,
          strokeWidth: strokeWidth,
          isEraser: isEraser,
        ),
      );
    });
  }

  void appendPoint(Offset localPos) {
    setState(() {
      if (_strokes.isNotEmpty) _strokes.last.points.add(localPos);
    });
  }

  void endStroke() {
    setState(() => _undone.clear()); // new action clears redo stack
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _undone.add(_strokes.removeLast());
      });
    }
  }

  void redo() {
    if (_undone.isNotEmpty) {
      setState(() {
        _strokes.add(_undone.removeLast());
      });
    }
  }

  void clearCanvas() {
    setState(() {
      _strokes.clear();
      _undone.clear();
    });
  }

  // Public helpers for parent widget to change tools
  void setColor(Color c) => setState(() {
    currentColor = c;
    isEraser = false;
  });
  void setStrokeWidth(double w) => setState(() => strokeWidth = w);
  void setEraser(bool v) => setState(() => isEraser = v);

  // Expose strokes for saving (or you could capture RepaintBoundary)
  List<Stroke> get strokes => _strokes;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.repaintKey,
      child: GestureDetector(
        onPanStart: (details) => startStroke(details.localPosition),
        onPanUpdate: (details) => appendPoint(details.localPosition),
        onPanEnd: (_) => endStroke(),
        child: CustomPaint(
          painter: _Sketcher(strokes: _strokes),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Sketcher extends CustomPainter {
  final List<Stroke> strokes;
  _Sketcher({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    // white background
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bg);

    for (final s in strokes) {
      final paint = Paint()
        ..color = s.isEraser ? Colors.white : s.color
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..strokeWidth = s.strokeWidth;

      if (s.points.length < 2) {
        if (s.points.isNotEmpty) {
          canvas.drawPoints(ui.PointMode.points, s.points, paint);
        }
        continue;
      }

      for (int i = 0; i < s.points.length - 1; i++) {
        final p1 = s.points[i];
        final p2 = s.points[i + 1];
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Sketcher oldDelegate) => true;
}
