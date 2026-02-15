import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/supabase/auth_service.dart';
import '../../shared/models/player.dart';

/// Provider that fetches the current player's profile.
final playerProvider = FutureProvider<Player?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  try {
    final response = await SupabaseClientManager.client
        .from('players')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Player.fromJson(response);
  } catch (_) {
    return null;
  }
});

/// Creates a new player record during onboarding.
Future<Player> createPlayer({
  required String userId,
  required String houseStyle,
  required String accentColour,
}) async {
  // Find a street with available plots
  final streets = await SupabaseClientManager.client
      .from('streets')
      .select('id, name, max_plots')
      .eq('district', 'elmfield')
      .order('name');

  String? streetId;
  int plotNumber = 1;

  for (final street in streets) {
    final count = await SupabaseClientManager.client
        .from('players')
        .select('id')
        .eq('street_id', street['id'] as String);

    if ((count as List).length < (street['max_plots'] as int)) {
      streetId = street['id'] as String;
      plotNumber = count.length + 1;
      break;
    }
  }

  // Fallback to first street if all full
  streetId ??= streets.first['id'] as String;

  final playerData = {
    'id': userId,
    'house_style': houseStyle,
    'accent_colour': accentColour,
    'street_id': streetId,
    'plot_number': plotNumber,
  };

  final response = await SupabaseClientManager.client
      .from('players')
      .insert(playerData)
      .select()
      .single();

  return Player.fromJson(response);
}
