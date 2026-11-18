import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_motion.dart';
import 'package:pomodoro_app/core/theme/app_theme.dart';

enum FabCorner { topLeft, topRight, bottomLeft, bottomRight }

class DraggableAddTaskFab extends StatefulWidget {
  const DraggableAddTaskFab({
    required this.onPressed,
    this.bottomClearance = 84,
    this.topClearance = 16,
    super.key,
  });

  final VoidCallback onPressed;
  final double bottomClearance;
  final double topClearance;

  @override
  State<DraggableAddTaskFab> createState() => _DraggableAddTaskFabState();
}

class _DraggableAddTaskFabState extends State<DraggableAddTaskFab> {
  static const double _size = 52;
  static const double _edgePadding = 16;

  FabCorner _corner = FabCorner.bottomRight;
  Offset? _dragPosition;

  Offset _cornerOffset(Size bounds, FabCorner corner) {
    final leftX = _edgePadding;
    final rightX = (bounds.width - _size - _edgePadding).clamp(
      _edgePadding,
      double.infinity,
    );
    final topY = widget.topClearance;
    final bottomY = (bounds.height - _size - widget.bottomClearance).clamp(
      topY,
      double.infinity,
    );
    return switch (corner) {
      FabCorner.topLeft => Offset(leftX, topY),
      FabCorner.topRight => Offset(rightX, topY),
      FabCorner.bottomLeft => Offset(leftX, bottomY),
      FabCorner.bottomRight => Offset(rightX, bottomY),
    };
  }

  FabCorner _nearestCorner(Size bounds, Offset position) {
    var best = FabCorner.bottomRight;
    var bestDist = double.infinity;
    for (final corner in FabCorner.values) {
      final target = _cornerOffset(bounds, corner);
      final dist = (target - position).distanceSquared;
      if (dist < bestDist) {
        bestDist = dist;
        best = corner;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final duration = _dragPosition != null
        ? Duration.zero
        : AppMotion.duration(context, AppMotion.panel);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounds = Size(constraints.maxWidth, constraints.maxHeight);
        final target = _dragPosition ?? _cornerOffset(bounds, _corner);

        return Stack(
          children: [
            AnimatedPositioned(
              duration: duration,
              curve: AppMotion.curve,
              left: target.dx,
              top: target.dy,
              width: _size,
              height: _size,
              child: GestureDetector(
                key: const Key('compact-add-task-fab'),
                onPanStart: (_) {
                  setState(() {
                    _dragPosition = _cornerOffset(bounds, _corner);
                  });
                },
                onPanUpdate: (details) {
                  final current =
                      _dragPosition ?? _cornerOffset(bounds, _corner);
                  final maxX = (bounds.width - _size - _edgePadding).clamp(
                    _edgePadding,
                    double.infinity,
                  );
                  final maxY = (bounds.height - _size - widget.bottomClearance)
                      .clamp(widget.topClearance, double.infinity);
                  setState(() {
                    _dragPosition = Offset(
                      (current.dx + details.delta.dx).clamp(_edgePadding, maxX),
                      (current.dy + details.delta.dy).clamp(
                        widget.topClearance,
                        maxY,
                      ),
                    );
                  });
                },
                onPanEnd: (_) {
                  final current =
                      _dragPosition ?? _cornerOffset(bounds, _corner);
                  setState(() {
                    _corner = _nearestCorner(bounds, current);
                    _dragPosition = null;
                  });
                },
                child: Semantics(
                  label: 'Add task',
                  button: true,
                  child: Material(
                    color: colors.accentFill,
                    shape: const CircleBorder(),
                    elevation: 4,
                    shadowColor: const Color(0x33000000),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.onPressed,
                      child: Center(
                        child: Icon(
                          LucideIcons.plus,
                          size: 24,
                          color: colors.onAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
