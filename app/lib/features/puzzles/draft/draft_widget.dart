import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colours.dart';
import '../../../core/theme/typography.dart';
import '../../../core/theme/spacing.dart';
import 'draft_painter.dart';
import 'draft_provider.dart';

/// Widget that renders and handles interaction for a DRAFT (Nonogram) puzzle.
class DraftPuzzleWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic> gridData;
  final VoidCallback? onSolved;

  const DraftPuzzleWidget({
    super.key,
    required this.gridData,
    this.onSolved,
  });

  @override
  ConsumerState<DraftPuzzleWidget> createState() => _DraftPuzzleWidgetState();
}

class _DraftPuzzleWidgetState extends ConsumerState<DraftPuzzleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _solvedAnimController;
  bool _hasNotifiedSolved = false;

  // Drag tracking for line fills (reserved for future line-fill enhancement)

  @override
  void initState() {
    super.initState();
    _solvedAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(draftProvider.notifier).initialize(widget.gridData);
    });
  }

  @override
  void dispose() {
    _solvedAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puzzleState = ref.watch(draftProvider);
    final engine = puzzleState.engine;

    if (puzzleState.isSolved && !_hasNotifiedSolved) {
      _hasNotifiedSolved = true;
      _solvedAnimController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.onSolved?.call();
      });
    }

    final totalSatisfied =
        puzzleState.satisfiedRows.length + puzzleState.satisfiedCols.length;
    final totalLines = engine.height + engine.width;

    return Column(
      children: [
        // Status bar
        Padding(
          padding: const EdgeInsets.symmetric(vertical: BauSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Moves: ${puzzleState.moveCount}',
                style: BauTypography.bodySmall,
              ),
              const SizedBox(width: BauSpacing.md),
              Text(
                '$totalSatisfied/$totalLines lines',
                style: BauTypography.bodySmall,
              ),
              if (puzzleState.isSolved) ...[
                const SizedBox(width: BauSpacing.md),
                Text(
                  'Revealed!',
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
                    onPanStart: (details) => _handleDragStart(
                      details,
                      gridSize,
                      engine.width,
                      engine.height,
                    ),
                    onPanEnd: (_) => _handleDragEnd(
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
                            painter: DraftPainter(
                              width: engine.width,
                              height: engine.height,
                              rowClues: engine.rowClues,
                              colClues: engine.colClues,
                              cells: engine.cells,
                              satisfiedRows: puzzleState.satisfiedRows,
                              satisfiedCols: puzzleState.satisfiedCols,
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
              ref.read(draftProvider.notifier).resetPuzzle();
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

  (int row, int col)? _hitTest(
    Offset localPosition,
    double totalSize,
    int gridWidth,
    int gridHeight,
  ) {
    final padding = BauSpacing.sm;
    final effectiveSize = totalSize - padding * 2;
    final clueSize = effectiveSize * DraftPainter.clueRatio;
    final gridSize = effectiveSize - clueSize;
    final cellSize = math.min(gridSize / gridWidth, gridSize / gridHeight);

    final localX = localPosition.dx - padding - clueSize;
    final localY = localPosition.dy - padding - clueSize;

    if (localX < 0 || localY < 0) return null;

    final col = (localX / cellSize).floor();
    final row = (localY / cellSize).floor();

    if (row >= 0 && row < gridHeight && col >= 0 && col < gridWidth) {
      return (row, col);
    }
    return null;
  }

  void _handleTap(
    TapUpDetails details,
    double totalSize,
    int gridWidth,
    int gridHeight,
  ) {
    final cell = _hitTest(details.localPosition, totalSize, gridWidth, gridHeight);
    if (cell != null) {
      ref.read(draftProvider.notifier).tapCell(cell.$1, cell.$2);
    }
  }

  void _handleDragStart(
    DragStartDetails details,
    double totalSize,
    int gridWidth,
    int gridHeight,
  ) {
    // Reserved for future line-fill drag enhancement
    _hitTest(details.localPosition, totalSize, gridWidth, gridHeight);
  }

  void _handleDragEnd(int gridWidth, int gridHeight) {
    // Currently drags are completed as tap sequences on the provider.
    // A future enhancement could implement line-fill drags here.
  }
}
