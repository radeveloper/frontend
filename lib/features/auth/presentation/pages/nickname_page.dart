import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/routing/routes.dart';
import '../../../room/presentation/pages/create_join_room_page.dart';

/// The first screen of the app where users pick a nickname.
///
/// This page prompts the user for a nickname and, once provided,
/// navigates to the create/join room screen. It leverages the
/// design system components such as [AppButton], [AppTextField],
/// and [AppScaffold] to ensure a consistent look and feel across
/// platforms.
class NicknamePage extends StatefulWidget {
  const NicknamePage({super.key});

  @override
  State<NicknamePage> createState() => _NicknamePageState();
}

class _NicknamePageState extends State<NicknamePage> {
  final _nicknameCtrl = TextEditingController();

  bool get _canContinue => _nicknameCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    // Once a nickname is entered, navigate to the create/join page.
    // Passing a default focus of create keeps the UX simple; users can still
    // switch to "Join" on the next screen if they prefer.
    Navigator.pushReplacementNamed(
      context,
      Routes.createJoin,
      arguments: const CreateJoinRoomArgs(CreateJoinFocus.create),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.xl),
                // Large badge-like icon to represent the user.
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary, width: 6),
                  ),
                  child: const Icon(
                    Icons.badge_rounded,
                    color: AppColors.primary,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'What should we call you?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose a nickname to use in the room.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),
                // Nickname input field with pill-shaped border.
                AppTextField(
                  controller: _nicknameCtrl,
                  hint: 'Enter your nickname',
                  borderRadius: 28,
                  prefixIcon: const Icon(Icons.person, color: AppColors.textSecondary),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nickname is required' : null,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _canContinue ? _continue() : null,
                ),
                const SizedBox(height: AppSpacing.m),
                // Continue button with a subtle shadow.
                Container(
                  decoration: BoxDecoration(boxShadow: AppShadow.soft),
                  child: AppButton(
                    label: 'Continue',
                    onPressed: _canContinue ? _continue : null,
                    variant: AppButtonVariant.primary,
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
      // Hide the bottom navigation bar on the nickname screen.
      showNav: false,
    );
  }
}