import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../shared/models/puzzle.dart';
import '../brief/puzzle_set_provider.dart';
import 'conduit/conduit_widget.dart';
import 'parcel/parcel_widget.dart';
import 'setback/setback_widget.dart';
import 'draft/draft_widget.dart';
import 'lamp/lamp_widget.dart';

/// Provider that fetches a single puzzle by ID from the current brief.
final puzzleByIdProvider =
    FutureProvider.family<Puzzle?, String>((ref, puzzleId) async {
  final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  final brief = await ref.watch(briefByDateProvider(today).future);
  if (brief == null) return null;
  try {
    return brief.allPuzzles.firstWhere((p) => p.id == puzzleId);
  } catch (_) {
    return null;
  }
});

/// The puzzle screen renders the appropriate puzzle widget based on type.
///
/// After solving, it auto-advances to the next puzzle in the session's
/// construction sequence (PARCEL → SETBACK → DRAFT → CONDUIT → LAMP),
/// or shows a session completion screen.
class PuzzleScreen extends ConsumerStatefulWidget {
  final String puzzleId;

  const PuzzleScreen({super.key, required this.puzzleId});

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  bool _showingCompletion = false;

  @override
  Widget build(BuildContext context) {
    final puzzleAsync = ref.watch(puzzleByIdProvider(widget.puzzleId));

    return Scaffold(
      backgroundColor: BauColours.cream,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: puzzleAsync.when(
          data: (puzzle) {
            if (puzzle == null) return const Text('Puzzle');
            return _PuzzleAppBarTitle(puzzle: puzzle);
          },
          loading: () => const Text('Loading...', style: BauTypography.headline3),
          error: (_, _) => const Text('Error', style: BauTypography.headline3),
        ),
      ),
      body: SafeArea(
        child: puzzleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Error loading puzzle: $e',
                style: BauTypography.body),
          ),
          data: (puzzle) {
            if (puzzle == null) {
              return const Center(
                child: Text('Puzzle not found', style: BauTypography.body),
              );
            }

            if (_showingCompletion) {
              return _SessionCompletionView(
                puzzle: puzzle,
                onContinue: () => _navigateNext(puzzle),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BauSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task description
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: BauSpacing.sm,
                    ),
                    child: Text(
                      puzzle.taskDescription,
                      style: BauTypography.body.copyWith(
                        fontStyle: FontStyle.italic,
                        color: BauColours.midGrey,
                      ),
                    ),
                  ),

                  // Puzzle widget (specific to type)
                  Expanded(
                    child: _buildPuzzleWidget(puzzle),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPuzzleWidget(Puzzle puzzle) {
    switch (puzzle.puzzleType) {
      case 'parcel':
        return ParcelPuzzleWidget(
          gridData: puzzle.gridData,
          onSolved: () => _onPuzzleSolved(puzzle),
        );
      case 'setback':
        return SetbackPuzzleWidget(
          gridData: puzzle.gridData,
          onSolved: () => _onPuzzleSolved(puzzle),
        );
      case 'draft':
        return DraftPuzzleWidget(
          gridData: puzzle.gridData,
          onSolved: () => _onPuzzleSolved(puzzle),
        );
      case 'conduit':
        return ConduitPuzzleWidget(
          gridData: puzzle.gridData,
          onSolved: () => _onPuzzleSolved(puzzle),
        );
      case 'lamp':
        return LampPuzzleWidget(
          gridData: puzzle.gridData,
          onSolved: () => _onPuzzleSolved(puzzle),
        );
      default:
        return Center(
          child: Text(
            'Unknown puzzle type: ${puzzle.puzzleType}',
            style: BauTypography.body,
          ),
        );
    }
  }

  void _onPuzzleSolved(Puzzle puzzle) {
    // TODO: Call complete-puzzle Edge Function here

    // Brief delay, then show transition
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _showingCompletion = true);
    });
  }

  void _navigateNext(Puzzle currentPuzzle) {
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final brief = ref.read(briefByDateProvider(today)).valueOrNull;
    if (brief == null) {
      context.goNamed('home');
      return;
    }

    // Find the next puzzle in the same session
    final sessionPuzzles = currentPuzzle.isSchematic
        ? brief.schematicPuzzles
        : brief.designPuzzles;

    final currentIndex = sessionPuzzles
        .indexWhere((p) => p.id == currentPuzzle.id);

    if (currentIndex >= 0 && currentIndex < sessionPuzzles.length - 1) {
      // Navigate to next puzzle in sequence
      final next = sessionPuzzles[currentIndex + 1];
      context.goNamed('puzzle', pathParameters: {'id': next.id});
    } else if (currentPuzzle.isSchematic) {
      // Schematic session complete — offer Design session
      _showSessionCompleteDialog(isSchematic: true);
    } else {
      // Design session complete — return home
      _showSessionCompleteDialog(isSchematic: false);
    }
  }

  void _showSessionCompleteDialog({required bool isSchematic}) {
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final brief = ref.read(briefByDateProvider(today)).valueOrNull;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: BauColours.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
        ),
        title: Text(
          isSchematic ? 'Schematic Complete!' : 'Design Complete!',
          style: BauTypography.headline2.copyWith(color: BauColours.sage),
        ),
        content: Text(
          isSchematic
              ? 'Great work on the schematic session. The Design Session is now available with more challenging puzzles.'
              : 'Outstanding! Both sessions are complete. Your contribution to Elmfield is noted.',
          style: BauTypography.body,
        ),
        actions: [
          if (isSchematic &&
              brief != null &&
              brief.designPuzzles.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.goNamed(
                  'puzzle',
                  pathParameters: {'id': brief.designPuzzles.first.id},
                );
              },
              child: const Text('Start Design Session'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.goNamed('home');
            },
            child: Text(isSchematic ? 'Return Home' : 'Done'),
          ),
        ],
      ),
    );
  }
}

class _PuzzleAppBarTitle extends StatelessWidget {
  final Puzzle puzzle;

  const _PuzzleAppBarTitle({required this.puzzle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _puzzleTypeName(puzzle.puzzleType),
          style: BauTypography.headline3,
        ),
        Text(
          '${puzzle.isSchematic ? 'Schematic' : 'Design'} · ${puzzle.slotNumber}/5',
          style: BauTypography.label,
        ),
      ],
    );
  }

  String _puzzleTypeName(String type) {
    switch (type) {
      case 'parcel':
        return 'PARCEL';
      case 'setback':
        return 'SETBACK';
      case 'draft':
        return 'DRAFT';
      case 'conduit':
        return 'CONDUIT';
      case 'lamp':
        return 'LAMP';
      default:
        return type.toUpperCase();
    }
  }
}

/// Transition screen shown after solving a puzzle.
class _SessionCompletionView extends StatelessWidget {
  final Puzzle puzzle;
  final VoidCallback onContinue;

  const _SessionCompletionView({
    required this.puzzle,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BauSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Completion icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: BauColours.sage.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: BauColours.sage,
              ),
            ),

            const SizedBox(height: BauSpacing.lg),

            Text(
              _completionMessage(puzzle.puzzleType),
              style: BauTypography.headline2.copyWith(
                color: BauColours.sage,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: BauSpacing.sm),

            Text(
              puzzle.taskDescription,
              style: BauTypography.body.copyWith(
                color: BauColours.midGrey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: BauSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                child: Text(
                  puzzle.slotNumber < 5 ? 'Next Puzzle' : 'Continue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _completionMessage(String type) {
    switch (type) {
      case 'parcel':
        return 'Land Divided';
      case 'setback':
        return 'Building Placed';
      case 'draft':
        return 'Blueprint Revealed';
      case 'conduit':
        return 'Services Connected';
      case 'lamp':
        return 'Lights On';
      default:
        return 'Complete';
    }
  }
}
