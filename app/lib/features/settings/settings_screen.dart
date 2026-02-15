import 'package:flutter/material.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BauColours.cream,
      appBar: AppBar(
        title: const Text('Settings', style: BauTypography.headline3),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BauSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: BauTypography.headline2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
