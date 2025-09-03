import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_divider_text.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_text_field.dart';

enum CreateJoinFocus { create, join }
class CreateJoinRoomArgs {
  final CreateJoinFocus focus;
  const CreateJoinRoomArgs(this.focus);
}

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
  bool get _canJoin => (_roomIdCtrl.text.trim().isNotEmpty && AppValidators.roomId(_roomIdCtrl.text) == null);

  @override
  void initState() {
    super.initState();
    _roomNameCtrl.addListener(() => setState(() {}));
    _roomIdCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments as CreateJoinRoomArgs?;
      if (args?.focus == CreateJoinFocus.join) {
        final ctx = _joinFieldKey.currentContext;
        if (ctx != null) await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250));
        _joinFocus.requestFocus();
      } else {
        final ctx = _createFieldKey.currentContext;
        if (ctx != null) await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250));
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
                // CREATE
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

                // JOIN
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

  void _tryCreate() {
    if (_createKey.currentState?.validate() ?? false) {
      final name = _roomNameCtrl.text.trim();
      // TODO: backend entegrasyonu (HTTP / create room) → success: navigate
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Room "$name" created')));
    }
  }

  void _tryJoin() {
    if (_joinKey.currentState?.validate() ?? false) {
      final id = _roomIdCtrl.text.trim();
      // TODO: backend entegrasyonu (HTTP/WS join) → success: navigate
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Joined room $id')));
    }
  }
}
