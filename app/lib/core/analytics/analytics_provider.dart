import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_service.dart';

/// Provider for the analytics service singleton.
///
/// Usage: ref.read(analyticsProvider).puzzleCompleted(...)
final analyticsProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.instance;
});
