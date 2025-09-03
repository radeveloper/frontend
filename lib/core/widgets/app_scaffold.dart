import 'package:flutter/material.dart';
import 'app_nav_bar.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final int currentIndex;
  final ValueChanged<int> onNavSelected;
  final bool showHelp;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
    required this.onNavSelected,
    this.actions,
    this.showHelp = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        actions: [
          if (showHelp) IconButton(onPressed: () {}, icon: const Icon(Icons.help_outline_rounded)),
          ...?actions,
          const SizedBox(width: 4),
        ],
      ),
      body: body,
      bottomNavigationBar: AppNavBar(currentIndex: currentIndex, onSelected: onNavSelected),
    );
  }
}
