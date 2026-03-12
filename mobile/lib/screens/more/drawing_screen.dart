import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import '../../theme/theme_manager.dart';

/// Result returned from the drawing canvas
class DrawingResult {
  final Uint8List? imageBytes; // PNG bytes
  DrawingResult(this.imageBytes);
}

/// Full-screen drawing canvas with pen tools
class DrawingScreen extends StatefulWidget {
  final Uint8List? existingImage;
  const DrawingScreen({super.key, this.existingImage});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  List<_Stroke> _strokes = [];
  _Stroke? _currentStroke;
  Color _penColor = Colors.white;
  double _strokeWidth = 3.0;
  bool _isEraser = false;

  static const _colors = [
    Colors.white,
    Color(0xFF4FC3F7), // light blue
    Color(0xFF81C784), // green
    Color(0xFFFFB74D), // orange
    Color(0xFFE57373), // red
    Color(0xFFBA68C8), // purple
    Color(0xFFFFD54F), // yellow
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(
        title: const Text('✏️ Drawing'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Undo
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _strokes.isNotEmpty ? () => setState(() => _strokes.removeLast()) : null,
          ),
          // Clear all
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _strokes.isNotEmpty ? () => setState(() => _strokes.clear()) : null,
          ),
          // Save
          TextButton(
            onPressed: _saveDrawing,
            child: Text('Save', style: TextStyle(color: ThemeManager.primary, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Column(children: [
        // Drawing canvas
        Expanded(
          child: GestureDetector(
            onPanStart: (d) {
              setState(() {
                _currentStroke = _Stroke(
                  points: [d.localPosition],
                  color: _isEraser ? ThemeManager.background : _penColor,
                  width: _isEraser ? 20.0 : _strokeWidth,
                );
              });
            },
            onPanUpdate: (d) {
              if (_currentStroke == null) return;
              setState(() {
                _currentStroke!.points.add(d.localPosition);
              });
            },
            onPanEnd: (_) {
              if (_currentStroke != null) {
                setState(() {
                  _strokes.add(_currentStroke!);
                  _currentStroke = null;
                });
              }
            },
            child: ClipRect(
              child: CustomPaint(
                painter: _DrawingPainter(
                  strokes: _strokes,
                  currentStroke: _currentStroke,
                  bgColor: ThemeManager.background,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),

        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: ThemeManager.card,
          child: Column(children: [
            // Color picker
            Row(children: [
              // Pen/eraser toggle
              GestureDetector(
                onTap: () => setState(() => _isEraser = false),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: !_isEraser ? ThemeManager.primary.withAlpha(40) : ThemeManager.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: !_isEraser ? ThemeManager.primary : ThemeManager.border),
                  ),
                  child: const Icon(Icons.edit, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _isEraser = true),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isEraser ? ThemeManager.primary.withAlpha(40) : ThemeManager.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isEraser ? ThemeManager.primary : ThemeManager.border),
                  ),
                  child: const Icon(Icons.auto_fix_high, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              // Colors
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _colors.map((c) => GestureDetector(
                    onTap: () => setState(() { _penColor = c; _isEraser = false; }),
                    child: Container(
                      width: 28, height: 28,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _penColor == c && !_isEraser ? ThemeManager.primary : ThemeManager.border,
                          width: _penColor == c && !_isEraser ? 3 : 1,
                        ),
                      ),
                    ),
                  )).toList()),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            // Stroke width
            Row(children: [
              Text('Stroke:', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11)),
              Expanded(
                child: Slider(
                  value: _strokeWidth,
                  min: 1, max: 12, divisions: 11,
                  activeColor: ThemeManager.primary,
                  label: _strokeWidth.toStringAsFixed(0),
                  onChanged: (v) => setState(() => _strokeWidth = v),
                ),
              ),
              Container(
                width: _strokeWidth * 2 + 4,
                height: _strokeWidth * 2 + 4,
                decoration: BoxDecoration(color: _penColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
            ]),
          ]),
        ),
      ]),
    );
  }

  Future<void> _saveDrawing() async {
    if (_strokes.isEmpty) {
      Navigator.pop(context, DrawingResult(null));
      return;
    }

    // Render to image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = MediaQuery.of(context).size;
    final painter = _DrawingPainter(
      strokes: _strokes,
      currentStroke: null,
      bgColor: ThemeManager.background,
    );
    painter.paint(canvas, Size(size.width, size.height - 200));
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), (size.height - 200).toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();

    if (mounted) {
      Navigator.pop(context, DrawingResult(pngBytes));
    }
  }
}

// ── Stroke model ───────────────────────────────────────────────────────────

class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  _Stroke({required this.points, required this.color, required this.width});
}

// ── Custom painter ─────────────────────────────────────────────────────────

class _DrawingPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final _Stroke? currentStroke;
  final Color bgColor;

  _DrawingPainter({required this.strokes, required this.currentStroke, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = bgColor);

    // Draw grid lines for guidance
    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw all strokes
    final allStrokes = [...strokes, if (currentStroke != null) currentStroke!];
    for (final stroke in allStrokes) {
      if (stroke.points.length < 2) continue;

      // Use perfect_freehand for smooth strokes
      final freehandPoints = stroke.points.map((p) => PointVector(p.dx, p.dy)).toList();
      final outlinePoints = getStroke(
        freehandPoints,
        options: StrokeOptions(
          size: stroke.width,
          thinning: 0.5,
          smoothing: 0.5,
          streamline: 0.5,
        ),
      );

      if (outlinePoints.isEmpty) continue;

      final path = Path();
      path.moveTo(outlinePoints.first.dx, outlinePoints.first.dy);
      for (int i = 1; i < outlinePoints.length - 1; i++) {
        final p0 = outlinePoints[i];
        final p1 = outlinePoints[i + 1];
        path.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
