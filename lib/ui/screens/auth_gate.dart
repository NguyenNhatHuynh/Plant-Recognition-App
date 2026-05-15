import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    if (!authService.isConfigured) {
      return const _AuthConfigurationMissingScreen();
    }

    return StreamBuilder<Session?>(
      stream: authService.authStateChanges.map((state) => state.session),
      initialData: authService.currentSession,
      builder: (context, snapshot) {
        final session = snapshot.data ?? authService.currentSession;
        if (session == null) {
          return const AuthScreen();
        }
        return const HomeScreen();
      },
    );
  }
}

class _AuthConfigurationMissingScreen extends StatelessWidget {
  const _AuthConfigurationMissingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 56,
                  color: Color(0xFF2D6A4F),
                ),
                const SizedBox(height: 16),
                Text(
                  'Thiếu cấu hình Supabase',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Hãy thêm SUPABASE_URL và SUPABASE_PUBLISHABLE_KEY vào file .env để bật đăng nhập.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
