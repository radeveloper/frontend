import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_nav_bar.dart';

/// Uygulama genel iskeleti: üst AppBar + (opsiyonel) alt NavigationBar.
class AppScaffold extends StatelessWidget {
  final String title;
  /// Sağ üstte gösterilecek (kopyalanabilir) oda kodu. Opsiyoneldir.
  final String? roomCode;

  final Widget body;
  final List<Widget>? actions;
  final int currentIndex;
  final ValueChanged<int> onNavSelected;
  final bool showHelp;

  /// Alt gezinme çubuğunu göstermek için.
  final bool showNav;

  const AppScaffold({
    super.key,
    required this.title,
    this.roomCode,
    required this.body,
    required this.currentIndex,
    required this.onNavSelected,
    this.actions,
    this.showHelp = false,
    this.showNav = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          if (roomCode != null) _RoomCodeAction(code: roomCode!),
          if (showHelp)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.help_outline_rounded),
            ),
          ...?actions,
          const SizedBox(width: 4),
        ],
      ),
      body: body,
      bottomNavigationBar:
      showNav ? AppNavBar(currentIndex: currentIndex, onSelected: onNavSelected) : null,
    );
  }
}

class _RoomCodeAction extends StatelessWidget {
  final String code;
  const _RoomCodeAction({required this.code});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          // ❗ async gap sonrasında context kullanmamak için messenger'ı önce alıyoruz
          final messenger = ScaffoldMessenger.of(context);
          await Clipboard.setData(ClipboardData(text: code));
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(content: Text('Oda kodu kopyalandı: $code')),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.copy, size: 16),
              const SizedBox(width: 6),
              Text(code),
            ],
          ),
        ),
      ),
    );
  }
}
