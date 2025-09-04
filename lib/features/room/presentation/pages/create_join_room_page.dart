import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_divider_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'lobby_page.dart';

/// Indicates which form (create or join) should be focused when the page opens.
enum CreateJoinFocus { create, join }

/// Arguments used when navigating to this page to control initial focus.
class CreateJoinRoomArgs {
  final CreateJoinFocus focus;
  const CreateJoinRoomArgs(this.focus);
}

/// A page allowing users to either create a new poker room or join an
/// existing one by ID. Once a room is successfully created or joined,
/// the user is navigated directly to the lobby.
class CreateJoinRoomPage extends StatefulWidget {
  const CreateJoinRoomPage({super.key});

  @override
  State<CreateJoinRoomPage> createState() => _CreateJoinRoomPageState();
}

class _CreateJoinRoomPageState extends State<CreateJoinRoomPage> {
  final _createFocus = FocusNode();
  final _joinFocus = FocusNode();
  final _scrollCtrl = ScrollController();
  final _createFieldKey = GlobalKey();
  final _joinFieldKey = GlobalKey();
  final _createKey = GlobalKey<FormState>();
  final _joinKey = GlobalKey<FormState>();
  final _roomNameCtrl = TextEditingController();
  final _roomIdCtrl = TextEditingController();

  bool get _canCreate => (_roomNameCtrl.text.trim().isNotEmpty);
  bool get _canJoin => (_roomIdCtrl.text.trim().isNotEmpty &&
      AppValidators.roomId(_roomIdCtrl.text) == null);

  @override
  void initState() {
    super.initState();
    _roomNameCtrl.addListener(() => setState(() {}));
    _roomIdCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments as CreateJoinRoomArgs?;
      if (args?.focus == CreateJoinFocus.join) {
        final ctx = _joinFieldKey.currentContext;
        if (ctx != null) {
          await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250));
        }
        _joinFocus.requestFocus();
      } else {
        final ctx = _createFieldKey.currentContext;
        if (ctx != null) {
          await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250));
        }
        _createFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _createFocus.dispose();
    _joinFocus.dispose();
    _scrollCtrl.dispose();
    _roomNameCtrl.dispose();
    _roomIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header for the create form
                const AppSectionHeader(title: 'Create a Room'),
                Form(
                  key: _createKey,
                  child: Column(
                    children: [
                      AppTextField(
                        key: _createFieldKey,
                        focusNode: _createFocus,
                        controller: _roomNameCtrl,
                        hint: 'Room Name',
                        borderRadius: 28,
                        prefixIcon: const Icon(Icons.group, color: AppColors.textSecondary),
                        validator: (v) => AppValidators.notEmpty(v, msg: 'Room name is required'),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _tryCreate(),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Container(
                        decoration: BoxDecoration(boxShadow: AppShadow.soft),
                        child: AppButton(
                          label: 'Create Room',
                          onPressed: _canCreate ? _tryCreate : null,
                          variant: AppButtonVariant.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                const AppDividerText(text: 'OR'),
                const SizedBox(height: AppSpacing.xl),

                // Header for the join form
                const AppSectionHeader(title: 'Join a Room', margin: EdgeInsets.only(bottom: 16)),
                Form(
                  key: _joinKey,
                  child: Column(
                    children: [
                      AppTextField(
                        key: _joinFieldKey,
                        focusNode: _joinFocus,
                        controller: _roomIdCtrl,
                        hint: 'Room ID',
                        borderRadius: 28,
                        prefixIcon: const Icon(Icons.tag, color: AppColors.textSecondary),
                        validator: AppValidators.roomId,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _tryJoin(),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Container(
                        decoration: BoxDecoration(boxShadow: AppShadow.soft),
                        child: AppButton(
                          label: 'Join Room',
                          onPressed: _canJoin ? _tryJoin : null,
                          variant: AppButtonVariant.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return AppScaffold(
      title: 'Scrum Poker',
      body: body,
      currentIndex: 0,
      onNavSelected: (_) {},
    );
  }

  /// Handles form submission for creating a room. Navigates to the lobby
  /// upon successful validation. In a real app this is where you would
  /// integrate with your backend and wait for confirmation before
  /// navigation.
  void _tryCreate() {
    if (_createKey.currentState?.validate() ?? false) {
      final name = _roomNameCtrl.text.trim();
      // Provide immediate feedback.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room "${name.isNotEmpty ? name : 'New Room'}" created')),
      );
      // Navigate directly to the lobby. Pass a dummy host participant; in a
      // real application this would come from your backend.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LobbyPage(
            roomName: name.isNotEmpty ? name : 'New Room',
            participants: const [
              Participant(name: 'Host', isHost: true, hasVoted: false),
            ],
            maxParticipants: 20,
            status: LobbyStatus.beforeVoting,
          ),
        ),
      );
    }
  }

  /// Handles form submission for joining a room. Navigates to the lobby
  /// upon successful validation. In a real app this is where you would
  /// validate the room ID against your backend and fetch the current
  /// room state.
  void _tryJoin() {
    if (_joinKey.currentState?.validate() ?? false) {
      final id = _roomIdCtrl.text.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined room $id')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LobbyPage(
            roomName: id.isNotEmpty ? id : 'Room',
            participants: const [
              Participant(name: 'You', hasVoted: false),
              Participant(name: 'Host', isHost: true, hasVoted: false),
            ],
            maxParticipants: 20,
            status: LobbyStatus.beforeVoting,
          ),
        ),
      );
    }
  }
}