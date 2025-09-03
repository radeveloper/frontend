// lib/app.dart
import 'package:flutter/material.dart';
import 'core/routing/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/room/presentation/pages/create_join_room_page.dart';
import 'features/welcome/presentation/pages/welcome_page.dart';

class ScrumPokerApp extends StatelessWidget {
  const ScrumPokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scrum Poker',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const WelcomePage(),
      routes: {
        Routes.createJoin: (_) => const CreateJoinRoomPage(),
      },
    );
  }
}