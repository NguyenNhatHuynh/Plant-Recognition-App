import 'dart:ui';

import 'package:flutter/material.dart';

enum AppSideMenuAction {
  profile,
  library,
  history,
  settings,
  careGuide,
  about,
  feedback,
  signOut,
}

Future<AppSideMenuAction?> showAppSideMenu({
  required BuildContext context,
  required String displayName,
  required String email,
  required AppSideMenuAction selectedAction,
  Set<AppSideMenuAction> visibleActions = const <AppSideMenuAction>{
    AppSideMenuAction.profile,
    AppSideMenuAction.library,
    AppSideMenuAction.history,
    AppSideMenuAction.settings,
    AppSideMenuAction.careGuide,
    AppSideMenuAction.about,
    AppSideMenuAction.feedback,
    AppSideMenuAction.signOut,
  },
}) {
  return showGeneralDialog<AppSideMenuAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Đóng menu',
    barrierColor: Colors.black.withValues(alpha: 0.20),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, __) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: AppSideMenu(
            displayName: displayName,
            email: email,
            selectedAction: selectedAction,
            visibleActions: visibleActions,
            onSelected: (value) => Navigator.of(context).pop(value),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8 * curved.value,
            sigmaY: 8 * curved.value,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.10, 0),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
              alignment: Alignment.topLeft,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

class AppSideMenu extends StatelessWidget {
  final String displayName;
  final String email;
  final AppSideMenuAction selectedAction;
  final Set<AppSideMenuAction> visibleActions;
  final ValueChanged<AppSideMenuAction> onSelected;

  const AppSideMenu({
    super.key,
    required this.displayName,
    required this.email,
    required this.selectedAction,
    required this.visibleActions,
    required this.onSelected,
  });

  String _avatarInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'P';
    }
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final items = _allItems
        .where((item) => visibleActions.contains(item.action))
        .toList(growable: false);
    final size = MediaQuery.sizeOf(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: size.width * 0.78,
        constraints: BoxConstraints(
          maxHeight: size.height * 0.90,
          minHeight: size.height * 0.55,
        ),
        margin: const EdgeInsets.only(left: 4, top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AppSideMenuAvatar(initial: _avatarInitial(displayName)),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF1E2722),
                          fontWeight: FontWeight.w800,
                          fontSize: 17.5,
                          height: 1.18,
                          letterSpacing: -0.15,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6A756F),
                          fontSize: 14,
                          height: 1.25,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    for (final item in items)
                      _AppSideMenuTile(
                        icon: item.icon,
                        label: item.label,
                        selected: item.action == selectedAction,
                        onTap: () => onSelected(item.action),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(
              height: 1,
              indent: 12,
              endIndent: 12,
              color: Color(0xFFE4E9E6),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: InkWell(
                onTap: () => onSelected(AppSideMenuAction.signOut),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFE1332D),
                        size: 21,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Đăng xuất',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: const Color(0xFFE1332D),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppSideMenuItemData {
  final AppSideMenuAction action;
  final IconData icon;
  final String label;

  const _AppSideMenuItemData({
    required this.action,
    required this.icon,
    required this.label,
  });
}

const List<_AppSideMenuItemData> _allItems = <_AppSideMenuItemData>[
  _AppSideMenuItemData(
    action: AppSideMenuAction.profile,
    icon: Icons.person_rounded,
    label: 'Thông tin cá nhân',
  ),
  _AppSideMenuItemData(
    action: AppSideMenuAction.library,
    icon: Icons.menu_book_rounded,
    label: 'Thư viện',
  ),
  _AppSideMenuItemData(
    action: AppSideMenuAction.history,
    icon: Icons.history_toggle_off_rounded,
    label: 'Lịch sử nhận diện',
  ),
  _AppSideMenuItemData(
    action: AppSideMenuAction.settings,
    icon: Icons.settings_outlined,
    label: 'Cài đặt',
  ),
  _AppSideMenuItemData(
    action: AppSideMenuAction.careGuide,
    icon: Icons.spa_outlined,
    label: 'Hướng dẫn chăm sóc',
  ),
  _AppSideMenuItemData(
    action: AppSideMenuAction.about,
    icon: Icons.info_outline_rounded,
    label: 'Về chúng tôi',
  ),
  _AppSideMenuItemData(
    action: AppSideMenuAction.feedback,
    icon: Icons.chat_bubble_outline_rounded,
    label: 'Phản hồi',
  ),
];

class _AppSideMenuAvatar extends StatelessWidget {
  final String initial;

  const _AppSideMenuAvatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 68,
          height: 68,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE3ECE5)),
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
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                    ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF1B6B4B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.eco_rounded,
              size: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _AppSideMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AppSideMenuTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFFD6F2DD) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: const Color(0xFF4D5A53),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF33413B),
                          fontSize: 16,
                          height: 1.2,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
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
