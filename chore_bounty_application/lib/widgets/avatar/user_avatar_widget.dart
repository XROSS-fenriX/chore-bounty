import 'package:flutter/material.dart';
import '../../core/constants/avatar_constants.dart';

class UserAvatarWidget extends StatelessWidget {
  const UserAvatarWidget({
    super.key,
    this.avatarId,
    this.userName,
    this.size = 46.0,
    this.onTap,
    this.showEditBadge = false,
    this.borderColor,
    this.borderWidth = 1.8,
  });

  final String? avatarId;
  final String? userName;
  final double size;
  final VoidCallback? onTap;
  final bool showEditBadge;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final avatar = AvatarConstants.findById(avatarId) ?? AvatarConstants.allAvatars.first;
    final effectiveBorderColor = borderColor ?? const Color(0xFF1B8354);

    Widget avatarImage = ClipOval(
      child: Image.asset(
        avatar.assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to initials or default profile
          return Container(
            width: size,
            height: size,
            color: const Color(0xFFDCFCE7),
            alignment: Alignment.center,
            child: Text(
              userName != null && userName!.trim().isNotEmpty
                  ? userName!.trim()[0].toUpperCase()
                  : 'R',
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1B8354),
              ),
            ),
          );
        },
      ),
    );

    Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: avatarImage,
    );

    if (showEditBadge) {
      final badgeSize = size * 0.32;
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: const Color(0xFF1B8354),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: badgeSize * 0.58,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: const Color(0xFF1B8354).withAlpha(30),
        child: content,
      );
    }

    return content;
  }
}
