import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart' show AppButton, AppButtonVariant, AppButtonSize;
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_logo.dart';
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

class _NicknamePageState extends State<NicknamePage> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

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
      if (kDebugMode) {
        print(e);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in failed: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated logo with theme
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 200,
                                height: 200,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  shape: BoxShape.circle,
                                  boxShadow: AppShadow.soft,
                                ),
                                child: const AppLogo(size: 80),
                              ),
                            );
                          },
                        ),

                        // Title with red color
                        const Text(
                          'EstiMate',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text(
                          'Choose a nickname to get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Modern text field
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

                        // Red gradient button
                        AppButton(
                          label: _loading ? 'Connecting...' : 'Continue',
                          onPressed: _loading ? null : _continue,
                          variant: AppButtonVariant.gradient,
                          size: AppButtonSize.lg,
                          expand: true,
                          trailing: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: body,
    );
  }
}
