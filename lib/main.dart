// lib/main.dart
// ignore_for_file: unused_local_variable, unnecessary_null_comparison, unused_field

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SketchpadApp());
}

class SketchpadApp extends StatelessWidget {
  const SketchpadApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sketchpad Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// --------------------------
/// HomeScreen: hosts canvas + toolbar + navigation to gallery
/// Displays the canvas where the user draws.

//Shows toolbar buttons for brush size, colors, eraser, undo/redo, background, save, and clear.
//Wraps the canvas in a RepaintBoundary so it can be exported as a PNG.
/// --------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final DrawingController _controller = DrawingController();

  // Background options
  ui.Image? _bgImage;
  Color _bgColor = Colors.white;

  // For picking images
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickBackgroundImage() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        _bgImage = frame.image;
      });
    } catch (e) {
      debugPrint('Error picking background image: $e');
    }
  }

  void _clearBackgroundImage() {
    setState(() => _bgImage = null);
  }

  void _setBackgroundColor(Color c) {
    setState(() {
      _bgColor = c;
      _bgImage = null; // color overrides image for clarity
    });
  }

  Future<bool> _ensureStoragePermission() async {
    if (Platform.isAndroid) {
      final st = await Permission.storage.status;
      if (st.isGranted) return true;
      final req = await Permission.storage.request();
      return req.isGranted;
    }
    // iOS: no runtime permission required for saving to gallery via plugin
    return true;
  }

  Future<String?> _saveToGalleryAndAppFolder() async {
    try {
      final ok = await _ensureStoragePermission();
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
        return null;
      }

      RenderRepaintBoundary boundary =
          _canvasKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final pixelRatio = ui.window.devicePixelRatio;
      ui.Image image = await boundary.toImage(
        pixelRatio: pixelRatio * 3,
      ); // high-res
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final bytes = byteData!.buffer.asUint8List();

      // Save to gallery (Android)
      final galleryResult = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: 'sketch_${DateTime.now().millisecondsSinceEpoch}',
      );
      debugPrint('Gallery save result: $galleryResult');

      // Also save to app documents folder so gallery screen can load it easily
      final docs = await getApplicationDocumentsDirectory();
      final file = File(
        '${docs.path}/sketch_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved image successfully')));
      return file.path;
    } catch (e) {
      debugPrint('Save error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      return null;
    }
  }

  Future<void> _shareCanvas() async {
    try {
      final filePath = await _saveToGalleryAndAppFolder();
      if (filePath == null) return;
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'My sketch from Sketchpad Pro');
    } catch (e) {
      debugPrint('Share error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }

  void _openGalleryScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => GalleryScreen()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Shortcut: long press Save to share (example)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sketchpad Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _openGalleryScreen,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveToGalleryAndAppFolder(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Canvas area with background
          RepaintBoundary(
            key: _canvasKey,
            child: GestureDetector(
              onPanStart: (details) {
                final box =
                    _canvasKey.currentContext!.findRenderObject() as RenderBox;
                final local = box.globalToLocal(details.globalPosition);
                _controller.startStroke(local);
              },
              onPanUpdate: (details) {
                final box =
                    _canvasKey.currentContext!.findRenderObject() as RenderBox;
                final local = box.globalToLocal(details.globalPosition);
                _controller.appendPoint(local);
              },
              onPanEnd: (details) {
                _controller.endStroke();
              },
              child: CustomPaint(
                painter: _CanvasPainter(
                  controller: _controller,
                  backgroundImage: _bgImage,
                  backgroundColor: _bgColor,
                ),
                size: Size.infinite,
              ),
            ),
          ),

          // Floating toolbar
          Positioned(
            right: 12,
            bottom: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToolButton(
                  icon: Icons.undo,
                  label: 'Undo',
                  onTap: () => setState(() => _controller.undo()),
                ),
                const SizedBox(height: 8),
                _ToolButton(
                  icon: Icons.redo,
                  label: 'Redo',
                  onTap: () => setState(() => _controller.redo()),
                ),
                const SizedBox(height: 8),
                _ToolButton(
                  icon: Icons.delete,
                  label: 'Clear',
                  onTap: () => setState(() => _controller.clear()),
                ),
                const SizedBox(height: 8),
                _ToolButton(
                  icon: Icons.image,
                  label: 'BG Image',
                  onTap: _pickBackgroundImage,
                ),
                const SizedBox(height: 8),
                _ToolButton(
                  icon: Icons.format_color_fill,
                  label: 'BG Color',
                  onTap: () => _openBgColorPicker(),
                ),
                const SizedBox(height: 8),
                _ToolButton(
                  icon: Icons.save_alt,
                  label: 'Save',
                  onTap: () => _saveToGalleryAndAppFolder(),
                ),
                const SizedBox(height: 8),
                _ToolButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: _shareCanvas,
                ),
              ],
            ),
          ),

          // Bottom panel: brush controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomControls(
              controller: _controller,
              onPickColor: (c) => setState(() => _controller.setColor(c)),
              onStrokeWidthChanged: (w) =>
                  setState(() => _controller.setStrokeWidth(w)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBgColorPicker() async {
    final Color? picked = await showDialog<Color>(
      context: context,
      builder: (ctx) {
        Color temp = _bgColor;
        return AlertDialog(
          title: const Text('Pick background color'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  [
                    Colors.white,
                    Colors.black,
                    Colors.grey,
                    Colors.blue,
                    Colors.green,
                    Colors.yellow,
                    Colors.orange,
                    Colors.pink,
                    Colors.brown,
                    Colors.purple,
                  ].map((c) {
                    return GestureDetector(
                      onTap: () {
                        temp = c;
                        Navigator.of(ctx).pop(c);
                      },
                      child: CircleAvatar(backgroundColor: c, radius: 20),
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      _setBackgroundColor(picked);
    }
  }
}

/// ------------------------------------------------------------
/// DrawingController: manages strokes, undo/redo, tool state
/// Stores all strokes drawn by the user.

//Each stroke contains:

//Points (Offset)

//Color
// //Brush size
// //Whether it's erasing
//Handles undo/redo by keeping two stacks:

//strokes

//undoneStrokes

//Notifies the painter whenever something changes.
/// -------------------------------------------------------------
class DrawingController with ChangeNotifier {
  final List<Stroke> _strokes = [];
  final List<Stroke> _undone = [];

  // Current tool state (default black brush)
  Color color = Colors.black;
  double strokeWidth = 4.0;
  bool isEraser = false;

  // Public read
  List<Stroke> get strokes => List.unmodifiable(_strokes);

  void startStroke(Offset pos) {
    _strokes.add(
      Stroke(
        points: [pos],
        color: color,
        strokeWidth: strokeWidth,
        isEraser: isEraser,
      ),
    );
    notifyListeners();
  }

  void appendPoint(Offset pos) {
    if (_strokes.isEmpty) return;
    _strokes.last.points.add(pos);
    notifyListeners();
  }

  void endStroke() {
    _undone.clear();
    notifyListeners();
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _undone.add(_strokes.removeLast());
      notifyListeners();
    }
  }

  void redo() {
    if (_undone.isNotEmpty) {
      _strokes.add(_undone.removeLast());
      notifyListeners();
    }
  }

  void clear() {
    _strokes.clear();
    _undone.clear();
    notifyListeners();
  }

  void setColor(Color c) {
    color = c;
    isEraser = false;
    notifyListeners();
  }

  void setStrokeWidth(double w) {
    strokeWidth = w;
    notifyListeners();
  }

  void setEraser(bool v) {
    isEraser = v;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Simple Stroke model
class Stroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;
  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });
}

/// --------------------------
/// Painter: draws strokes + background
/// --------------------------
class _CanvasPainter extends CustomPainter {
  final DrawingController controller;
  final ui.Image? backgroundImage;
  final Color backgroundColor;
  _CanvasPainter({
    required this.controller,
    required this.backgroundImage,
    required this.backgroundColor,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background color
    final bg = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bg);

    // Draw background image if present (fit box)
    if (backgroundImage != null) {
      final img = backgroundImage!;
      final src = Rect.fromLTWH(
        0,
        0,
        img.width.toDouble(),
        img.height.toDouble(),
      );
      final dst = Rect.fromLTWH(0, 0, size.width, size.height);
      paintImage(canvas: canvas, rect: dst, image: img, fit: BoxFit.cover);
    }

    // Draw strokes
    for (final s in controller.strokes) {
      final paint = Paint()
        ..color = s.isEraser ? backgroundColor : s.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s.strokeWidth
        ..isAntiAlias = true;

      if (s.points.length < 2) {
        if (s.points.isNotEmpty) {
          canvas.drawPoints(ui.PointMode.points, s.points, paint);
        }
        continue;
      }

      for (int i = 0; i < s.points.length - 1; i++) {
        final p1 = s.points[i];
        final p2 = s.points[i + 1];
        if (p2 != null) canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}

/// --------------------------
/// Small UI widgets
/// --------------------------
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    heroTag: label,
    onPressed: onTap,
    mini: true,
    tooltip: label,
    child: Icon(icon),
  );
}

class _BottomControls extends StatefulWidget {
  final DrawingController controller;
  final ValueChanged<Color> onPickColor;
  final ValueChanged<double> onStrokeWidthChanged;

  const _BottomControls({
    required this.controller,
    required this.onPickColor,
    required this.onStrokeWidthChanged,
  });

  @override
  State<_BottomControls> createState() => _BottomControlsState();
}

class _BottomControlsState extends State<_BottomControls> {
  double _currentWidth = 4.0;

  @override
  void initState() {
    super.initState();
    _currentWidth = widget.controller.strokeWidth;
  }

  void _openColorPicker() async {
    final Color? picked = await showDialog<Color>(
      context: context,
      builder: (ctx) {
        Color temp = widget.controller.color;
        return AlertDialog(
          title: const Text('Pick brush color'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  [
                    Colors.black,
                    Colors.white,
                    Colors.red,
                    Colors.green,
                    Colors.blue,
                    Colors.orange,
                    Colors.purple,
                    Colors.yellow,
                    Colors.brown,
                    Colors.pink,
                  ].map((c) {
                    return GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(c),
                      child: CircleAvatar(backgroundColor: c, radius: 18),
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      widget.controller.setColor(picked);
      widget.onPickColor(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openColorPicker,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: widget.controller.color,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Brush'),
          Expanded(
            child: Slider(
              min: 1,
              max: 40,
              value: widget.controller.strokeWidth,
              onChanged: (v) {
                setState(() {
                  _currentWidth = v;
                });
                widget.controller.setStrokeWidth(v);
                widget.onStrokeWidthChanged(v);
              },
            ),
          ),
          IconButton(
            onPressed: () {
              widget.controller.setEraser(false);
            },
            icon: const Icon(Icons.brush),
            tooltip: 'Brush',
          ),
          IconButton(
            onPressed: () {
              widget.controller.setEraser(true);
            },
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Eraser',
          ),
          const SizedBox(width: 8),
          // Brush preview
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.black12),
            ),
            child: Center(
              child: Container(
                width: widget.controller.strokeWidth / 2,
                height: widget.controller.strokeWidth / 2,
                decoration: BoxDecoration(
                  color: widget.controller.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// --------------------------
/// Gallery Screen: reads saved images from app document folder
/// --------------------------
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<FileSystemEntity> _files = [];

  Future<void> _loadFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final l = dir.listSync().where((f) => f.path.endsWith('.png')).toList();
    l.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    setState(() => _files = l);
  }

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _shareFile(String path) async {
    await Share.shareXFiles([XFile(path)], text: 'My sketch');
  }

  Future<void> _deleteFile(String path) async {
    try {
      await File(path).delete();
      await _loadFiles();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFiles),
        ],
      ),
      body: _files.isEmpty
          ? const Center(child: Text('No saved sketches yet'))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _files.length,
              itemBuilder: (_, idx) {
                final f = _files[idx];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FullscreenImage(path: f.path),
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(f.path), fit: BoxFit.cover),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.share,
                                color: Colors.white,
                              ),
                              onPressed: () => _shareFile(f.path),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              onPressed: () => _deleteFile(f.path),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class FullscreenImage extends StatelessWidget {
  final String path;
  const FullscreenImage({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () =>
                Share.shareXFiles([XFile(path)], text: 'My sketch'),
          ),
        ],
      ),
      body: Center(child: Image.file(File(path))),
    );
  }
}
