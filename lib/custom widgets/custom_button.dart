import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String buttonText;
  final String? navigateToPage;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? child; // New parameter for custom child widget
  final bool isLoading; // New parameter for loading state

  CustomButton({
    super.key,
    required this.buttonText,
    this.navigateToPage,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.child,
    this.isLoading = false,
  }) : assert(navigateToPage != null || onPressed != null || child != null,
  'Either navigateToPage, onPressed, or child must be provided');

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.isLoading ? null : _handlePress,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor ?? const Color(0xFFA61617),
        foregroundColor: widget.textColor ?? Colors.white,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
      ),
      child: _buildChild(),
    );
  }

  Widget _buildChild() {
    if (widget.isLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      );
    }
    return widget.child ?? Text(
      widget.buttonText,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _handlePress() {
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else if (widget.navigateToPage != null) {
      Navigator.pushNamed(context, widget.navigateToPage!);
    }
  }
}