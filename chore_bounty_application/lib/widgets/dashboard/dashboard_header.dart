import 'package:flutter/material.dart';
import '../avatar/user_avatar_widget.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    this.userName,
    this.avatarId,
    this.householdName,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onProfileTap,
    this.onHouseholdTap,
    this.onMenuTap,
  });

  final String? userName;
  final String? avatarId;
  final String? householdName;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onHouseholdTap;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Hamburger Menu Button (Left side)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (onMenuTap != null) {
                onMenuTap!();
              } else {
                Scaffold.maybeOf(context)?.openDrawer();
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.menu_rounded,
                color: Color(0xFF1E293B),
                size: 28,
              ),
            ),
          ),
        ),

        // Notification Bell Icon Button and Profile Avatar (Right side)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onNotificationTap,
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF1E293B),
                        size: 26,
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          top: 3,
                          right: 2,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              notificationCount > 99
                                  ? '99+'
                                  : '$notificationCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            UserAvatarWidget(
              avatarId: avatarId,
              userName: userName ?? '',
              size: 46,
              onTap: onProfileTap,
            ),
          ],
        ),
      ],
    );
  }
}

