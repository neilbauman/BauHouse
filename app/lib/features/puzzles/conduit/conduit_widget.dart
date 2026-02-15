import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colours.dart';
import '../../../core/theme/typography.dart';
import '../../../core/theme/spacing.dart';
import 'conduit_painter.dart';
import 'conduit_provider.dart';

/// Widget that renders and handles interaction for a CONDUIT puzzle.
class ConduitPuzzleWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic> gridData;
  final VoidCallback? onSolved;

  const ConduitPuzzleWidget({
    super.key,
    required this.gridData,
    this.onSolved,
  });

  @override
  ConsumerState<ConduitPuzzleWidget> createState() =>
      _ConduitPuzzleWidgetState();
}

class _ConduitPuzzleWidgetState extends ConsumerState<ConduitPuzzleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _solvedAnimController;
  bool _hasNotifiedSolved = false;

  @override
  void initState() {
    super.initState();
    _solvedAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Initialize the puzzle engine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conduitProvider.notifier).initialize(widget.gridData);
    });
  }

  @override
  void dispose() {
    _solvedAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puzzleState = ref.watch(conduitProvider);
    final engine = puzzleState.engine;

    // Trigger solved animation and callback
    if (puzzleState.isSolved && !_hasNotifiedSolved) {
      _hasNotifiedSolved = true;
      _solvedAnimController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.onSolved?.call();
      });
    }

    return Column(
      children: [
        // Move counter
        Padding(
          padding: const EdgeInsets.symmetric(vertical: BauSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Moves: ${puzzleState.moveCount}',
                style: BauTypography.bodySmall,
              ),
              if (puzzleState.isSolved) ...[
                const SizedBox(width: BauSpacing.md),
                Text(
                  'Connected!',
                  style: BauTypography.headline3.copyWith(
                    color: BauColours.sage,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Puzzle grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gridSize = math.min(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              return Center(
                child: SizedBox(
                  width: gridSize,
                  height: gridSize,
                  child: GestureDetector(
                    onTapUp: (details) => _handleTap(
                      details,
                      gridSize,
                      engine.width,
                      engine.height,
                    ),
                    child: AnimatedBuilder(
                      animation: _solvedAnimController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: BauColours.surface,
                            borderRadius: BorderRadius.circular(
                              BauSpacing.borderRadius,
                            ),
                            border: Border.all(
                              color: puzzleState.isSolved
                                  ? BauColours.sage.withValues(
                                      alpha: 0.5 +
                                          0.5 * _solvedAnimController.value,
                                    )
                                  : BauColours.gridLine,
                              width: puzzleState.isSolved ? 2 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(BauSpacing.sm),
                          child: CustomPaint(
                            painter: ConduitPainter(
                              width: engine.width,
                              height: engine.height,
                              cells: engine.cells,
                              connectedCells: puzzleState.connectedCells,
                              isSolved: puzzleState.isSolved,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Reset button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: BauSpacing.md),
          child: TextButton.icon(
            onPressed: () {
              ref.read(conduitProvider.notifier).resetPuzzle();
              _hasNotifiedSolved = false;
              _solvedAnimController.reset();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reset'),
          ),
        ),
      ],
    );
  }

  void _handleTap(
    TapUpDetails details,
    double gridSize,
    int gridWidth,
    int gridHeight,
  ) {
    final padding = BauSpacing.sm;
    final effectiveSize = gridSize - padding * 2;
    final cellSize = effectiveSize / math.max(gridWidth, gridHeight);

    final offsetX = (effectiveSize - cellSize * gridWidth) / 2 + padding;
    final offsetY = (effectiveSize - cellSize * gridHeight) / 2 + padding;

    final localX = details.localPosition.dx - offsetX;
    final localY = details.localPosition.dy - offsetY;

    if (localX < 0 || localY < 0) return;

    final col = (localX / cellSize).floor();
    final row = (localY / cellSize).floor();

    if (row >= 0 && row < gridHeight && col >= 0 && col < gridWidth) {
      ref.read(conduitProvider.notifier).tapCell(row, col);
    }
  }
}
