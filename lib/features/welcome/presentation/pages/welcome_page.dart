import 'package:flutter/material.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../room/presentation/pages/create_join_room_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _currentIndex = 0;

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
                const AppLogo(size: 56),
                const SizedBox(height: 28),
                Text(
                  'Estimate with precision',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Collaboratively estimate project tasks with your team using a fun, interactive approach.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),
                // Buttons with consistent shadow
                Container(
                  decoration: BoxDecoration(boxShadow: AppShadow.soft),
                  child: AppButton(label: 'Create Room', onPressed: () {
                    Navigator.pushNamed(
                      context,
                      Routes.createJoin,
                      arguments: const CreateJoinRoomArgs(focus: CreateJoinFocus.create),
                    );
                  },),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(boxShadow: AppShadow.soft),
                  child: AppButton(
                    label: 'Join Room',
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        Routes.createJoin,
                        arguments: const CreateJoinRoomArgs(focus: CreateJoinFocus.join),
                      );
                    },
                    variant: AppButtonVariant.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
              ],
            ),
          ),
        ),
      ),
    );

    return AppScaffold(
      title: 'Scrum Poker',
      body: body,
      currentIndex: _currentIndex,
      onNavSelected: (i) => setState(() => _currentIndex = i),
    );
  }
}
