import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/bau_theme.dart';

class BauHouseApp extends StatelessWidget {
  const BauHouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BauHouse',
      theme: BauTheme.light,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
