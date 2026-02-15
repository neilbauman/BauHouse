import 'package:flutter/material.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';

class BriefScreen extends StatelessWidget {
  final String date;

  const BriefScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BauColours.cream,
      appBar: AppBar(
        title: const Text('Build Brief', style: BauTypography.headline3),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BauSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Build Brief',
                style: BauTypography.headline2,
              ),
              const SizedBox(height: BauSpacing.sm),
              Text(
                date,
                style: BauTypography.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
