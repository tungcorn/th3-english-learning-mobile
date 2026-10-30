import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/theme.dart';

class SpeakDailyApp extends StatelessWidget {
  const SpeakDailyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<AppState, bool>((app) => app.user != null);
    return MaterialApp(
      title: 'Speak Daily',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: signedIn ? const HomeShell() : const ProfileScreen(),
    );
  }
}
