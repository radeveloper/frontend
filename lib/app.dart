import 'package:flutter/material.dart';
import 'core/routing/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/room/presentation/pages/create_join_room_page.dart';
import 'features/auth/presentation/pages/nickname_page.dart';

/// Root of the Scrum Poker application.
///
/// The app starts by showing [NicknamePage] to prompt the user
/// for their display name before proceeding to room creation/join flows.
class ScrumPokerApp extends StatelessWidget {
  const ScrumPokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scrum Poker',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Start the app with the nickname selection screen.
      home: const NicknamePage(),
      routes: {
        Routes.createJoin: (_) => const CreateJoinRoomPage(),
      },
    );
  }
}