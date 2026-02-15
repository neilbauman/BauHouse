import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseClientManager {
  SupabaseClientManager._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
}
