import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colours.dart';
import '../../../core/theme/typography.dart';
import '../../../core/theme/spacing.dart';
import 'parcel_painter.dart';
import 'parcel_provider.dart';

/// Widget that renders and handles interaction for a PARCEL puzzle.
///
/// Supports drag-to-create-rectangle and tap-to-remove-region.
class ParcelPuzzleWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic> gridData;
  final VoidCallback? onSolved;

  const ParcelPuzzleWidget({
    super.key,
    required this.gridData,
    this.onSolved,
  });

  @override
  ConsumerState<ParcelPuzzleWidget> createState() => _ParcelPuzzleWidgetState();
}

class _ParcelPuzzleWidgetState extends ConsumerState<ParcelPuzzleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _solvedAnimController;
  bool _hasNotifiedSolved = false;

  // Drag tracking
  int? _dragStartRow;
  int? _dragStartCol;

  @override
  void initState() {
    super.initState();
    _solvedAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parcelProvider.notifier).initialize(widget.gridData);
    });
  }

  @override
  void dispose() {
    _solvedAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puzzleState = ref.watch(parcelProvider);
    final engine = puzzleState.engine;

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
              const SizedBox(width: BauSpacing.md),
              Text(
                '${engine.regions.length}/${engine.givens.length} parcels',
                style: BauTypography.bodySmall,
              ),
              if (puzzleState.isSolved) ...[
                const SizedBox(width: BauSpacing.md),
                Text(
                  'Divided!',
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
                    onPanUpdate: (details) => _handleDragUpdate(
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
                            painter: ParcelPainter(
                              width: engine.width,
                              height: engine.height,
                              givens: engine.givens,
                              regions: engine.regions,
                              dragPreview: puzzleState.dragPreview,
                              isSolved: puzzleState.isSolved,
                              validateRegion: engine.validateRegion,
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
              ref.read(parcelProvider.notifier).resetPuzzle();
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
    double gridSize,
    int gridWidth,
    int gridHeight,
  ) {
    final padding = BauSpacing.sm;
    final effectiveSize = gridSize - padding * 2;
    final cellSize = math.min(
      effectiveSize / gridWidth,
      effectiveSize / gridHeight,
    );

    final totalGridW = cellSize * gridWidth;
    final totalGridH = cellSize * gridHeight;
    final offsetX = (effectiveSize - totalGridW) / 2 + padding;
    final offsetY = (effectiveSize - totalGridH) / 2 + padding;

    final localX = localPosition.dx - offsetX;
    final localY = localPosition.dy - offsetY;

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
    double gridSize,
    int gridWidth,
    int gridHeight,
  ) {
    final cell = _hitTest(details.localPosition, gridSize, gridWidth, gridHeight);
    if (cell != null) {
      ref.read(parcelProvider.notifier).tapCell(cell.$1, cell.$2);
    }
  }

  void _handleDragStart(
    DragStartDetails details,
    double gridSize,
    int gridWidth,
    int gridHeight,
  ) {
    final cell = _hitTest(details.localPosition, gridSize, gridWidth, gridHeight);
    if (cell != null) {
      _dragStartRow = cell.$1;
      _dragStartCol = cell.$2;
    }
  }

  void _handleDragUpdate(
    DragUpdateDetails details,
    double gridSize,
    int gridWidth,
    int gridHeight,
  ) {
    if (_dragStartRow == null || _dragStartCol == null) return;
    final cell = _hitTest(details.localPosition, gridSize, gridWidth, gridHeight);
    if (cell != null) {
      ref.read(parcelProvider.notifier).updateDragPreview(
            _dragStartRow!,
            _dragStartCol!,
            cell.$1,
            cell.$2,
          );
    }
  }

  void _handleDragEnd(int gridWidth, int gridHeight) {
    if (_dragStartRow == null || _dragStartCol == null) {
      ref.read(parcelProvider.notifier).cancelDrag();
      return;
    }

    final preview = ref.read(parcelProvider).dragPreview;
    if (preview != null) {
      ref.read(parcelProvider.notifier).finishDrag(
            preview.row,
            preview.col,
            preview.row + preview.height - 1,
            preview.col + preview.width - 1,
          );
    }

    _dragStartRow = null;
    _dragStartCol = null;
  }
}
