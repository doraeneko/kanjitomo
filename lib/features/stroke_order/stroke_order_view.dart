import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'stroke_order_painter.dart';

/// Animated reference stroke-order display: plays automatically on a loop,
/// no interaction required. Owns its own AnimationController so callers
/// just hand it a character's paths.
class StrokeOrderView extends StatefulWidget {
  final List<ui.Path> paths;
  final double displaySize;
  final Duration perStrokeDuration;

  const StrokeOrderView({
    super.key,
    required this.paths,
    this.displaySize = 200,
    this.perStrokeDuration = const Duration(milliseconds: 500),
  });

  @override
  State<StrokeOrderView> createState() => _StrokeOrderViewState();
}

class _StrokeOrderViewState extends State<StrokeOrderView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.perStrokeDuration * widget.paths.length.clamp(1, 1 << 30),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant StrokeOrderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paths != widget.paths) {
      _controller.duration =
          widget.perStrokeDuration * widget.paths.length.clamp(1, 1 << 30);
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.displaySize,
      height: widget.displaySize,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.square(widget.displaySize),
            painter: StrokeOrderPainter(
              paths: widget.paths,
              progress: _controller.value * widget.paths.length,
            ),
          );
        },
      ),
    );
  }
}
