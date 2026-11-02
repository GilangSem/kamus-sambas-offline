import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'presentation/pages/app_shell.dart';
import 'presentation/theme/app_theme.dart';
import 'utils/constants.dart';

class KamusApp extends StatelessWidget {
  const KamusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppShell(),
    );
  }
}
