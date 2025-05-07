import 'package:flutter/material.dart';
import 'package:voiceats/custom%20widgets/styles.dart';

class CustomInputField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final bool isHide;
  final bool showEye; // 👁️ NEW
  final String warning;
  final TextInputType? keyboardType;
  final bool isWarning;
  final bool isSuccess;
  final Widget? prefix;
  final Widget? prefixIcon;
  final int? maxlines;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.labelText,
    this.isHide = false,
    this.showEye = false, // 👁️ NEW DEFAULT
    required this.warning,
    this.keyboardType,
    this.isWarning = false,
    this.isSuccess = false,
    this.prefix,
    this.prefixIcon, this.maxlines,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isHide;
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxlines,
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(
          color: widget.isWarning ? Color(0xFFA61617) : styles.primary,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.isSuccess
                ? Colors.green
                : const Color(0xFFA61617),
            width: widget.isWarning ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.isSuccess
                ? Colors.green
                : const Color(0xFFA61617),
            width: widget.isWarning ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.isSuccess
                ? Colors.green
                : const Color(0xFFA61617),
            width: widget.isWarning ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color(0xFFA61617),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color(0xFFA61617),
            width: 2.5,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        prefix: widget.prefix,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.showEye
            ? IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: styles.primary,
          ),
          onPressed: _toggleVisibility,
        )
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return widget.warning;
        }
        return null;
      },
    );
  }
}
