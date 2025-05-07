import 'package:flutter/material.dart';
import 'head_title.dart';

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String appbarTitle;
  final void Function(BuildContext context)? onBackPressed;
  final List<Widget>? actions;


  const CustomAppbar({
    super.key,
    required this.appbarTitle,
    this.onBackPressed, this.actions,
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
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
