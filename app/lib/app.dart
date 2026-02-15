import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/bau_theme.dart';

class BauHouseApp extends ConsumerWidget {
  const BauHouseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'BauHouse',
      theme: BauTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
