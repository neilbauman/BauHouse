import 'package:flutter/material.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';

class PuzzleScreen extends StatelessWidget {
  final String puzzleId;

  const PuzzleScreen({super.key, required this.puzzleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BauColours.cream,
      appBar: AppBar(
        title: const Text('Puzzle', style: BauTypography.headline3),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BauSpacing.md),
          child: Center(
            child: Text(
              'Puzzle: $puzzleId',
              style: BauTypography.body,
            ),
          ),
        ),
      ),
    );
  }
}
