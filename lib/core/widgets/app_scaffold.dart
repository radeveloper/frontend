import 'package:flutter/material.dart';
import 'app_nav_bar.dart';

/// A reusable scaffold that applies the app-wide navigation bar and header styling.
///
/// By default, it displays a title, an optional list of action widgets,
/// and the bottom navigation bar defined by [AppNavBar]. Passing
/// [showNav] as false hides the navigation bar, which is useful for
/// splash or entry screens such as the nickname prompt.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final int currentIndex;
  final ValueChanged<int> onNavSelected;
  final bool showHelp;
  /// Whether to show the bottom navigation bar. Defaults to true.
  final bool showNav;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
    required this.onNavSelected,
    this.actions,
    this.showHelp = true,
    this.showNav = true,
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
      // Show the bottom nav bar only when [showNav] is true.
      bottomNavigationBar:
      showNav ? AppNavBar(currentIndex: currentIndex, onSelected: onNavSelected) : null,
    );
  }
}