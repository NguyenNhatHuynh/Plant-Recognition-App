import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../state/app_state.dart';

class SyncScope extends StatefulWidget {
  final Widget child;

  const SyncScope({
    super.key,
    required this.child,
  });

  @override
  State<SyncScope> createState() => _SyncScopeState();
}

class _SyncScopeState extends State<SyncScope> {
  AppState? _appState;
  AuthService? _authService;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _debounceTimer;
  int _lastObservedSyncRevision = 0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextAppState = context.read<AppState>();
    if (!identical(_appState, nextAppState)) {
      _appState?.removeListener(_handleAppStateChanged);
      _appState = nextAppState;
      _lastObservedSyncRevision = nextAppState.syncRevision;
      nextAppState.addListener(_handleAppStateChanged);
    }

    final nextAuthService = context.read<AuthService>();
    if (!identical(_authService, nextAuthService)) {
      _authSubscription?.cancel();
      _authService = nextAuthService;
      _authSubscription = nextAuthService.authStateChanges.listen((state) {
        if (state.session != null) {
          _scheduleSync(const Duration(milliseconds: 300));
        }
      });
    }

    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (_authService?.currentSession != null) {
          _scheduleSync(const Duration(milliseconds: 300));
        }
      });
    }
  }

  void _handleAppStateChanged() {
    final appState = _appState;
    if (appState == null) {
      return;
    }

    if (appState.syncRevision == _lastObservedSyncRevision) {
      return;
    }

    _lastObservedSyncRevision = appState.syncRevision;
    _scheduleSync(const Duration(milliseconds: 900));
  }

  void _scheduleSync(Duration delay) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, _runSync);
  }

  Future<void> _runSync() async {
    if (!mounted) {
      return;
    }

    final syncService = context.read<SyncService>();
    final appState = context.read<AppState>();
    final hasRemoteUpdates = await syncService.syncInBackground();
    if (!mounted || !hasRemoteUpdates) {
      return;
    }

    appState.markChanged(scheduleSync: false);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _authSubscription?.cancel();
    _appState?.removeListener(_handleAppStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
