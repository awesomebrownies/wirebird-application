import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';

class AnimationSyncManager {
  static final AnimationSyncManager _instance = AnimationSyncManager._internal();
  final List<VoidCallback> _listeners = [];
  double _progress = 0.0;
  Timer? _timer;

  AnimationSyncManager._internal() {
    _startAnimation();
  }

  factory AnimationSyncManager() => _instance;

  double get progress => _progress;

  void _startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _progress = (_progress + 0.33) % 1.0;
      for (final listener in _listeners) {
        listener();
      }
    });
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
}

class OptimizedDottedLinePainter extends CustomPainter {
  final double distance;
  final double angle;
  final double spacing;
  final double dotSize;
  final Color color;
  final double progress;
  final double shift;

  OptimizedDottedLinePainter({
    required this.distance,
    required this.angle,
    required this.spacing,
    required this.dotSize,
    required this.color,
    required this.progress,
    required this.shift,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;

    canvas.save();

    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    canvas.translate(-size.width / 2, -size.height / 2);

    final totalDots = (distance / spacing).ceil();

    for (double i = -1; i < totalDots; i++) {
      final offset = (i * spacing + progress * spacing) + shift;
      if (offset > distance) continue;

      final startX = max(offset, shift);
      final endX = min(offset + 9, distance);

      if (startX > endX) continue;

      canvas.drawRect(Rect.fromPoints(Offset(startX, -1), Offset(endX, 1)), paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(OptimizedDottedLinePainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class AnimatedLineConnector extends StatefulWidget {
  final double distance;
  final double angle;
  final double spacing;
  final double dotSize;
  final Color color;
  final double shift;

  const AnimatedLineConnector({
    Key? key,
    required this.distance,
    required this.angle,
    this.spacing = 20.0,
    this.dotSize = 2.0,
    this.color = Colors.blue,
    this.shift = 0,
  }) : super(key: key);

  @override
  _AnimatedDottedLineState createState() => _AnimatedDottedLineState();
}

class _AnimatedDottedLineState extends State<AnimatedLineConnector> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    final manager = AnimationSyncManager();
    _progress = manager.progress;
    manager.addListener(_onFrameUpdate);
  }

  void _onFrameUpdate() {
    setState(() {
      _progress = AnimationSyncManager().progress;
    });
  }

  @override
  void dispose() {
    AnimationSyncManager().removeListener(_onFrameUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: const Size(0, 0),
        painter: OptimizedDottedLinePainter(
          distance: widget.distance,
          angle: widget.angle,
          spacing: widget.spacing,
          dotSize: widget.dotSize,
          color: widget.color,
          progress: _progress,
          shift: widget.shift,
        ),
      ),
    );
  }
}
