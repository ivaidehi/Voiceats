import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 80); // Deeper arc start

    path.quadraticBezierTo(
      size.width / 2, size.height + 20, // Deeper curve
      size.width, size.height - 80,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class styles {
  // static ElevatedButton customButto
  static Color primary = const Color(0xFFA61617);
  static Color bgcolor = const Color(0xFFFFEBEE);
}