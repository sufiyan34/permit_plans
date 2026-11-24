import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes the Supabase client.
///
/// The defaults below are this project's *public* URL and publishable (anon)
/// key, which are designed to ship inside client apps — Row Level Security is
/// what protects the data. Override them per environment at build/run time:
///
/// flutter run \
///   --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY
///
/// Never put the Supabase service_role / secret key in a Flutter application.
class SupabaseConfig {
  SupabaseConfig._();

  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tptophkrvqvdvajfkoft.supabase.co',
  );

  static const String _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_ts0HParnsw9Gu5C96Am9Nw_XAFZ16xB',
  );

  static Future<void> initialize() async {
    if (_url.isEmpty || _anonKey.isEmpty) {
      throw StateError(
        'Missing Supabase configuration. Provide SUPABASE_URL and '
        'SUPABASE_ANON_KEY using --dart-define.',
      );
    }

    // `anonKey` accepts both legacy anon JWTs and the newer
    // `sb_publishable_...` keys, and exists in every supabase_flutter 2.x.
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }
}
