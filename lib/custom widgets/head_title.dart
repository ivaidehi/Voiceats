import 'package:flutter/cupertino.dart';

class HeadTitle extends StatelessWidget {
  final String title;
  const HeadTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22, // Slightly smaller font
        fontWeight: FontWeight.bold,
        color: Color(0xFFA61617),
      ),
    );
  }
}
