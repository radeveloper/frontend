import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart' show AppButton, AppButtonVariant, AppButtonSize;
import '../../../../core/widgets/app_text_field.dart' show AppTextField, AppTextFieldSize;
import '../../../../core/widgets/app_logo.dart';
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

class _CreateJoinRoomPageState extends State<CreateJoinRoomPage> with TickerProviderStateMixin {
  final _createName = TextEditingController();
  final _joinCode = TextEditingController();
  final _createKey = GlobalKey<FormState>();
  final _joinKey = GlobalKey<FormState>();
  bool _creating = false;
  bool _joining = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();

    try {
      if (!PokerSocket.I.connected) PokerSocket.I.connect();
    } catch (_) {}
  }

  @override
  void dispose() {
    _createName.dispose();
    _joinCode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    if (!_createKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _creating = true);
    try {
      final name = _createName.text.trim();
      final code = await RoomsApi(ApiClient()).createRoom(name);

      PokerSocket.I.joinRoom(code);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LobbyPage()),
      );
    } catch (e) {
      if (kDebugMode) print(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Create failed: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
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
        SnackBar(
          content: Text('Join failed: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                              style: IconButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.neutral500.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person, size: 16, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    Session.I.displayName ?? 'Guest',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const AppLogo(size: 64),
                        const SizedBox(height: 24),
                        const Text(
                          'Start Planning',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 36,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a new room or join an existing one',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          children: [
                            // Create Room Card with red accents
                            Form(
                              key: _createKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppTextField(
                                    controller: _createName,
                                    hint: 'Enter room name',
                                    textInputAction: TextInputAction.done,
                                    borderRadius: 10.0,
                                    size: AppTextFieldSize.md,
                                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Room name is required' : null,
                                    onSubmitted: (_) => _onCreate(),
                                  ),
                                  const SizedBox(height: 20),
                                  AppButton(
                                    label: _creating ? 'Creating...' : 'Create Room',
                                    onPressed: _creating ? null : _onCreate,
                                    size: AppButtonSize.md,
                                    expand: true,
                                    borderRadius: 10.0,
                                    trailing: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Divider with red accent
                            Row(
                              children: [
                                Expanded(child: Container(height: 1, color: AppColors.divider)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: AppColors.primary.withValues(alpha: 0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(child: Container(height: 1, color: AppColors.divider)),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // Join Room Card
                            Form(
                              key: _joinKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppTextField(
                                    controller: _joinCode,
                                    hint: 'XXXXXX',
                                    textInputAction: TextInputAction.done,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                    textCapitalization: TextCapitalization.characters,
                                    validator: (v) {
                                      final s = (v ?? '').trim().toUpperCase();
                                      if (s.isEmpty) return 'Room code is required';
                                      if (s.length != 6) return 'Room code must be 6 characters';
                                      if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(s)) return 'Invalid format';
                                      return null;
                                    },
                                    onSubmitted: (_) => _onJoin(),
                                  ),
                                  const SizedBox(height: 20),
                                  AppButton(
                                    label: _joining ? 'Joining...' : 'Join Room',
                                    onPressed: _joining ? null : _onJoin,
                                    variant: AppButtonVariant.secondary,
                                    size: AppButtonSize.md,
                                    borderRadius: 10.0,
                                    expand: true,
                                    trailing: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
