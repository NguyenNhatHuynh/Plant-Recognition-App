import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/recognition_record.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../state/app_state.dart';
import '../widgets/app_side_menu.dart';
import 'about_screen.dart';
import 'feedback_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const ProfileScreen(),
    );
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _primaryGreen = Color(0xFF185B43);
  static const _darkGreen = Color(0xFF226346);
  static const _pageBackground = Color(0xFFF7F9F6);
  static const _softMint = Color(0xFFCFEFD8);
  static const _softGold = Color(0xFFFFDABB);

  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isUpdatingDisplayName = false;
  bool _isUpdatingPassword = false;
  bool _isSigningOut = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = context.read<AuthService>();
    final currentName = _displayNameFor(authService.currentUser);
    if (_displayNameController.text.trim().isEmpty) {
      _displayNameController.text = currentName;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateDisplayName() async {
    final nextValue = _displayNameController.text.trim();
    if (nextValue.isEmpty || _isUpdatingDisplayName) {
      return;
    }

    setState(() {
      _isUpdatingDisplayName = true;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.updateDisplayName(displayName: nextValue);
      if (!mounted) {
        return;
      }
      setState(() {});
      Navigator.of(context).pop();
      _showSnackBar('Đã cập nhật tên hiển thị.', isError: false);
    } on AuthException catch (error) {
      _showSnackBar(error.message, isError: true);
    } catch (error) {
      _showSnackBar(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingDisplayName = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    if (_isUpdatingPassword) {
      return;
    }
    if (password.isEmpty || confirm.isEmpty) {
      _showSnackBar('Vui lòng nhập đầy đủ mật khẩu mới.', isError: true);
      return;
    }
    if (password.length < 8) {
      _showSnackBar('Mật khẩu cần ít nhất 8 ký tự.', isError: true);
      return;
    }
    if (password != confirm) {
      _showSnackBar('Mật khẩu nhập lại chưa khớp.', isError: true);
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.updatePassword(newPassword: password);
      if (!mounted) {
        return;
      }
      _passwordController.clear();
      _confirmPasswordController.clear();
      Navigator.of(context).pop();
      _showSnackBar('Đổi mật khẩu thành công.', isError: false);
    } on AuthException catch (error) {
      _showSnackBar(error.message, isError: true);
    } catch (error) {
      _showSnackBar(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
        });
      }
    }
  }

  Future<void> _confirmAndSignOut() async {
    if (_isSigningOut) {
      return;
    }

    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text(
          'Bạn có chắc muốn đăng xuất khỏi tài khoản này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ở lại'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF2E2E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true || !mounted) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).maybePop();
    } on AuthException catch (error) {
      _showSnackBar(error.message, isError: true);
    } catch (error) {
      _showSnackBar(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : _primaryGreen,
      ),
    );
  }

  void _showEditDisplayNameSheet() {
    _displayNameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _displayNameController.text.length,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _ProfileBottomSheet(
            title: 'Chỉnh sửa tên hiển thị',
            description:
                'Tên này sẽ xuất hiện trong trang hồ sơ của bạn.',
            child: Column(
              children: [
                TextField(
                  controller: _displayNameController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _updateDisplayName(),
                  decoration: _inputDecoration(
                    label: 'Tên hiển thị',
                    icon: Icons.edit_outlined,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isUpdatingDisplayName ? null : _updateDisplayName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _isUpdatingDisplayName ? 'Đang lưu...' : 'Lưu thay đổi',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordSheet() {
    _passwordController.clear();
    _confirmPasswordController.clear();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _ProfileBottomSheet(
            title: 'Đổi mật khẩu',
            description:
                'Nhập mật khẩu mới để bảo vệ tài khoản tốt hơn.',
            child: Column(
              children: [
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'Mật khẩu mới',
                    icon: Icons.lock_outline_rounded,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _changePassword(),
                  decoration: _inputDecoration(
                    label: 'Nhập lại mật khẩu mới',
                    icon: Icons.verified_user_outlined,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUpdatingPassword ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _isUpdatingPassword
                          ? 'Đang cập nhật...'
                          : 'Cập nhật mật khẩu',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSideMenu({
    required String displayName,
    required String email,
  }) async {
    final action = await showAppSideMenu(
      context: context,
      displayName: displayName,
      email: email,
      selectedAction: AppSideMenuAction.profile,
      visibleActions: const <AppSideMenuAction>{
        AppSideMenuAction.profile,
        AppSideMenuAction.settings,
        AppSideMenuAction.careGuide,
        AppSideMenuAction.about,
        AppSideMenuAction.feedback,
        AppSideMenuAction.signOut,
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case AppSideMenuAction.profile:
        _showEditDisplayNameSheet();
      case AppSideMenuAction.settings:
        Navigator.push(context, SettingsScreen.route());
      case AppSideMenuAction.careGuide:
        _showSnackBar(
          'Hướng dẫn chăm sóc sẽ sớm được hoàn thiện.',
          isError: false,
        );
      case AppSideMenuAction.about:
        Navigator.push(context, AboutScreen.route());
      case AppSideMenuAction.feedback:
        Navigator.push(context, FeedbackScreen.route());
      case AppSideMenuAction.signOut:
        _confirmAndSignOut();
      case AppSideMenuAction.library:
      case AppSideMenuAction.history:
        break;
    }
  }

  String _displayNameFor(User? user) {
    if (user == null) {
      return 'Người dùng';
    }

    final metadata = user.userMetadata;
    final candidates = <Object?>[
      metadata?['display_name'],
      metadata?['full_name'],
      metadata?['name'],
      user.email?.split('@').first,
    ];

    for (final candidate in candidates) {
      final text = candidate?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }

    return 'Người dùng';
  }

  String _avatarInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'P';
    }
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>().revision;
    final authService = context.read<AuthService>();
    final dbService = context.read<DatabaseService>();
    final user = authService.currentUser;
    final displayName = _displayNameFor(user);
    final email = user?.email?.trim().isNotEmpty == true
        ? user!.email!.trim()
        : 'Chưa có email';

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: FutureBuilder<List<RecognitionRecord>>(
          future: dbService.getHistory(),
          builder: (context, snapshot) {
            final records = snapshot.data ?? const <RecognitionRecord>[];
            final uniqueSpecies = records
                .map((record) => record.plant.scientificName.trim())
                .where((name) => name.isNotEmpty)
                .toSet()
                .length;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                children: [
                  _ProfileTopBar(
                    onOpenMenu: () => _openSideMenu(
                      displayName: displayName,
                      email: email,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ProfileAvatar(
                    initial: _avatarInitial(displayName),
                    onEditTap: _showEditDisplayNameSheet,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF1E2722),
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF606B66),
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ProfileBadge(
                        label: uniqueSpecies >= 10
                            ? 'Chuyên gia thực vật'
                            : 'Người yêu cây',
                        icon: Icons.eco_outlined,
                        backgroundColor: _softMint,
                        foregroundColor: _darkGreen,
                      ),
                      const _ProfileBadge(
                        label: 'Hội viên Vàng',
                        icon: Icons.workspace_premium_outlined,
                        backgroundColor: _softGold,
                        foregroundColor: Color(0xFF6A4621),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _RecognitionSummaryCard(
                    uniqueSpecies: uniqueSpecies,
                    onDetailsTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _ProfileMenuCard(
                    items: [
                      _ProfileMenuItemData(
                        title: 'Thông tin cá nhân',
                        icon: Icons.person_rounded,
                        isHighlighted: true,
                        onTap: _showEditDisplayNameSheet,
                      ),
                      _ProfileMenuItemData(
                        title: 'Thông báo',
                        icon: Icons.notifications_none_rounded,
                        onTap: () {
                          Navigator.push(context, SettingsScreen.route());
                        },
                      ),
                      _ProfileMenuItemData(
                        title: 'Bảo mật & Quyền riêng tư',
                        icon: Icons.lock_outline_rounded,
                        onTap: _showChangePasswordSheet,
                      ),
                      _ProfileMenuItemData(
                        title: 'Lịch sử nhận diện',
                        icon: Icons.history_toggle_off_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showChangePasswordSheet,
                      icon: const Icon(Icons.key_rounded),
                      label: const Text('Đổi mật khẩu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSigningOut ? null : _confirmAndSignOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        _isSigningOut ? 'Đang đăng xuất...' : 'Đăng xuất',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE1302A),
                        side: const BorderSide(
                          color: Color(0xFFE1302A),
                          width: 1.6,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF7F9F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFDDE6E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: _primaryGreen,
          width: 1.4,
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  final VoidCallback onOpenMenu;

  const _ProfileTopBar({required this.onOpenMenu});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF2D6A4F),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.spa_rounded,
            size: 17,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Nhận Diện Cây Cối',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF185B43),
                fontWeight: FontWeight.w800,
              ),
        ),
        const Spacer(),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onOpenMenu,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4ECE6)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: Color(0xFF185B43),
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String initial;
  final VoidCallback onEditTap;

  const _ProfileAvatar({
    required this.initial,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 118,
          height: 118,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF4A7C5B), Color(0xFF244F3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: const Color(0xFF1B6B4B),
            shape: const CircleBorder(),
            elevation: 6,
            child: InkWell(
              onTap: onEditTap,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const _ProfileBadge({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecognitionSummaryCard extends StatelessWidget {
  final int uniqueSpecies;
  final VoidCallback onDetailsTap;

  const _RecognitionSummaryCard({
    required this.uniqueSpecies,
    required this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2D7854),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn đã nhận diện thành công',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                    children: [
                      TextSpan(
                        text: '$uniqueSpecies',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const TextSpan(text: ' '),
                      const TextSpan(text: 'loài cây khác nhau'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: onDetailsTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem chi tiết',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_outline_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItemData {
  final String title;
  final IconData icon;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _ProfileMenuItemData({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isHighlighted = false,
  });
}

class _ProfileMenuCard extends StatelessWidget {
  final List<_ProfileMenuItemData> items;

  const _ProfileMenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6ECE7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _ProfileMenuTile(
              item: items[index],
              isFirst: index == 0,
            ),
            if (index != items.length - 1)
              const Divider(height: 1, color: Color(0xFFEEF2EF)),
          ],
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final _ProfileMenuItemData item;
  final bool isFirst;

  const _ProfileMenuTile({
    required this.item,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final topRadius = item.isHighlighted && isFirst
        ? const Radius.circular(22)
        : Radius.zero;

    return Material(
      color: item.isHighlighted ? const Color(0xFFD7F3DE) : Colors.white,
      borderRadius: BorderRadius.vertical(
        top: topRadius,
      ),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.vertical(
          top: topRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: const Color(0xFF496157),
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF3C4742),
                        fontSize: 17,
                        fontWeight:
                            item.isHighlighted ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF54635B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBottomSheet extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _ProfileBottomSheet({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD9E2DC),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF1D2A22),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64716A),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
