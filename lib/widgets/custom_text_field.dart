import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final VoidCallback? onEditingComplete;
  final Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.isPassword = false,
    required this.controller,
    this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onEditingComplete,
    this.onChanged,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.isPassword ? _obscureText : false,
        keyboardType: _getKeyboardType(),
        inputFormatters: widget.inputFormatters,
        textInputAction:
            widget.isPassword ? TextInputAction.done : TextInputAction.next,
        autocorrect: !widget.isPassword,
        enableSuggestions: !widget.isPassword,
        autofillHints: _getAutofillHints(),
        onChanged: widget.onChanged,
        onEditingComplete: widget.onEditingComplete,
        decoration: InputDecoration(
          hintText: widget.hintText,
          // ignore: prefer_const_constructors
          hintStyle: TextStyle(color: AppColors.textGray, fontSize: 16),
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, color: AppColors.textGray)
              : null,
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textGray,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(
              color: AppColors.primaryOrange,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  TextInputType _getKeyboardType() {
    if (widget.keyboardType != null) {
      return widget.keyboardType!;
    }

    if (widget.isPassword) {
      return TextInputType.visiblePassword;
    }

    // Check hint text to determine appropriate keyboard type
    final hint = widget.hintText.toLowerCase();
    if (hint.contains('email')) {
      return TextInputType.emailAddress;
    } else if (hint.contains('phone') || hint.contains('telefono')) {
      return TextInputType.phone;
    } else if (hint.contains('number') || hint.contains('numero')) {
      return TextInputType.number;
    } else {
      return TextInputType.text;
    }
  }

  List<String>? _getAutofillHints() {
    if (widget.isPassword) {
      return [AutofillHints.password];
    }

    final hint = widget.hintText.toLowerCase();
    if (hint.contains('username') || hint.contains('usuario')) {
      return [AutofillHints.username];
    } else if (hint.contains('email')) {
      return [AutofillHints.email];
    } else if (hint.contains('name') || hint.contains('nombre')) {
      return [AutofillHints.name];
    } else if (hint.contains('phone') || hint.contains('telefono')) {
      return [AutofillHints.telephoneNumber];
    }

    return null;
  }
}
