import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class ZHAKASApp extends StatelessWidget {
  const ZHAKASApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZHAKAS FASHION',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.splash,
      routes: Routes.routes,
    );
  }
}
