import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/routing/routes.dart';
import '../../../auth/data/auth_api.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/session/session.dart';
import '../../../../poker_socket.dart';

class NicknamePage extends StatefulWidget {
  const NicknamePage({super.key});

  @override
  State<NicknamePage> createState() => _NicknamePageState();
}

class _NicknamePageState extends State<NicknamePage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _controller.text.trim();
    setState(() => _loading = true);
    try {
      await AuthApi(ApiClient()).guest(name);
      Session.I.displayName = name;

      // JWT ile WS bağlantısını aç
      PokerSocket.I.connect();

      if (!mounted) return;
      Navigator.of(context).pushNamed(Routes.createJoin);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'What should we call you?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a nickname to use in the room.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _controller,
                  hint: 'Enter your nickname',
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Please enter a nickname';
                    if (s.length < 2) return 'At least 2 characters';
                    return null;
                  },
                  onSubmitted: (_) => _continue(),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: _loading ? 'Please wait…' : 'Continue',
                  onPressed: _loading ? null : _continue,
                  variant: AppButtonVariant.primary,
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
      showNav: false,
    );
  }
}
