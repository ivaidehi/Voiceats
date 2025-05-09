import 'package:flutter/material.dart';
import 'head_title.dart';

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String appbarTitle;
  final void Function(BuildContext context)? onBackPressed;
  final List<Widget>? actions;
  final String? profileImagePath; // ✅ New parameter
  final bool showProfileImage;    // ✅ New flag

  const CustomAppbar({
    super.key,
    required this.appbarTitle,
    this.onBackPressed,
    this.actions,
    this.profileImagePath,
    this.showProfileImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      title: HeadTitle(title: appbarTitle),
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFA61617), size: 24),
          onPressed: () {
            if (onBackPressed != null) {
              onBackPressed!(context);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      actions: [
        if (showProfileImage && profileImagePath != null)
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(profileImagePath!),
            ),
          ),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
