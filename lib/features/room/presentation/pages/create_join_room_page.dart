// lib/features/room/presentation/pages/create_join_room_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_divider_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/session/session.dart';
import '../../../room/data/rooms_api.dart';
import '../../../../core/network/api_client.dart';
import '../../../../poker_socket.dart';
import 'lobby_page.dart';

enum CreateJoinFocus { create, join }

class CreateJoinRoomArgs {
  final CreateJoinFocus focus;
  const CreateJoinRoomArgs({this.focus = CreateJoinFocus.create});
}

class CreateJoinRoomPage extends StatefulWidget {
  const CreateJoinRoomPage({super.key, this.args = const CreateJoinRoomArgs()});
  final CreateJoinRoomArgs args;

  @override
  State<CreateJoinRoomPage> createState() => _CreateJoinRoomPageState();
}

class _CreateJoinRoomPageState extends State<CreateJoinRoomPage> {
  final _createName = TextEditingController();
  final _joinCode = TextEditingController();
  final _createKey = GlobalKey<FormState>();
  final _joinKey = GlobalKey<FormState>();
  bool _creating = false;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    // Token varsa ve WS bağlı değilse bağlan.
    try {
      if (!PokerSocket.I.connected) PokerSocket.I.connect();
    } catch (_) {}
  }

  @override
  void dispose() {
    _createName.dispose();
    _joinCode.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    if (!_createKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _creating = true);
    try {
      final name = _createName.text.trim();
      final code = await RoomsApi(ApiClient()).createRoom(name);

      // Odaya WS ile katıl ve Lobby'e geç
      PokerSocket.I.joinRoom(code);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LobbyPage()),
      );
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _onJoin() async {
    if (!_joinKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _joining = true);
    try {
      final code = _joinCode.text.trim().toUpperCase();
      final displayName = (Session.I.displayName ?? 'Guest').trim();

      await RoomsApi(ApiClient()).joinRoom(code, displayName);
      PokerSocket.I.joinRoom(code);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LobbyPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Join failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final createForm = Form(
      key: _createKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Create a Room'),
          const SizedBox(height: 12),
          AppTextField(
            controller: _createName,
            hint: 'Room Name',
            textInputAction: TextInputAction.done,
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Room name is required' : null,
            onSubmitted: (_) => _onCreate(),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: _creating ? 'Creating…' : 'Create Room',
            onPressed: _creating ? null : _onCreate,
            variant: AppButtonVariant.primary,
            // Web’de dar alan overflow’u önlemek ve dizayna uymak için:
            expand: true,
          ),
        ],
      ),
    );

    final joinForm = Form(
      key: _joinKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Join a Room'),
          const SizedBox(height: 12),
          AppTextField(
            controller: _joinCode,
            hint: 'Room ID',
            textInputAction: TextInputAction.done,
            // NOT: const yok!
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(6),
            ],
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              final s = (v ?? '').trim().toUpperCase();
              if (s.isEmpty) return 'Room code is required';
              if (s.length != 6) return 'Room code has 6 chars';
              if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(s)) return 'Use 0-9 A-F only';
              return null;
            },
            onSubmitted: (_) => _onJoin(),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: _joining ? 'Joining…' : 'Join Room',
            onPressed: _joining ? null : _onJoin,
            variant: AppButtonVariant.secondary,
            expand: true,
          ),
        ],
      ),
    );

    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              createForm,
              const SizedBox(height: 20),
              const AppDividerText(text: 'OR'),
              const SizedBox(height: 20),
              joinForm,
            ],
          ),
        ),
      ),
    );

    return AppScaffold(
      title: 'Scrum Poker',
      body: body,
      currentIndex: 0,
      onNavSelected: (_) {},
      showNav: true,
    );
  }
}
