import 'package:bluebubbles/helpers/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Adds an iOS-style "swipe from the left edge to go back" interaction on top
/// of an already-built page. This intentionally does not touch the page
/// route's own transition animation (that would require private Flutter
/// APIs) - instead it drives a small local [AnimationController] that
/// translates [child] as the user drags, and commits the pop via
/// [Navigator.pop] once a distance/velocity threshold is crossed. The hit
/// area is a narrow strip pinned to the leading edge, so it never competes
/// with gestures (e.g. swipe-to-reply, swipeable list tiles) that start
/// anywhere else on the page.
class CupertinoEdgeBackGestureDetector extends StatefulWidget {
  const CupertinoEdgeBackGestureDetector({
    super.key,
    required this.child,
    this.edgeWidth = 24.0,
  });

  final Widget child;
  final double edgeWidth;

  @override
  State<CupertinoEdgeBackGestureDetector> createState() => _CupertinoEdgeBackGestureDetectorState();
}

class _CupertinoEdgeBackGestureDetectorState extends State<CupertinoEdgeBackGestureDetector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  bool _dragging = false;
  double _width = 0.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (!Navigator.canPop(context)) return;
    _dragging = true;
    _controller.stop();
    Navigator.of(context).didStartUserGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details, bool ltr) {
    if (!_dragging || _width <= 0) return;
    final delta = (ltr ? details.delta.dx : -details.delta.dx) / _width;
    _controller.value = (_controller.value + delta).clamp(0.0, 1.0);
  }

  void _handleDragEnd(DragEndDetails details, bool ltr) {
    if (!_dragging) return;
    _dragging = false;
    Navigator.of(context).didStopUserGesture();
    final velocityFraction = _width <= 0
        ? 0.0
        : (ltr ? details.velocity.pixelsPerSecond.dx : -details.velocity.pixelsPerSecond.dx) / _width;
    final shouldPop = velocityFraction > 1.0 || _controller.value > 0.5;
    if (shouldPop && Navigator.canPop(context)) {
      HapticFeedback.lightImpact();
      Navigator.pop(context);
    } else {
      _controller.animateTo(0.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  void _handleDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    Navigator.of(context).didStopUserGesture();
    _controller.animateTo(0.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    // Mouse-driven desktop/web builds don't get the touch edge-swipe - avoid
    // stealing horizontal drags from things like window/text interactions.
    if (kIsDesktop || kIsWeb) return widget.child;

    final ltr = Directionality.of(context) == TextDirection.ltr;
    final canPop = Navigator.canPop(context);

    return LayoutBuilder(builder: (context, constraints) {
      _width = constraints.maxWidth;
      return Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final dx = (ltr ? _controller.value : -_controller.value) * _width;
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: widget.child,
          ),
          if (canPop)
            Positioned(
              left: ltr ? 0 : null,
              right: ltr ? null : 0,
              top: 0,
              bottom: 0,
              width: widget.edgeWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: _handleDragStart,
                onHorizontalDragUpdate: (details) => _handleDragUpdate(details, ltr),
                onHorizontalDragEnd: (details) => _handleDragEnd(details, ltr),
                onHorizontalDragCancel: _handleDragCancel,
              ),
            ),
        ],
      );
    });
  }
}
