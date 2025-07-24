import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StandardTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted; // ✅ ADDED: Missing parameter
  final GestureTapCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction; // ✅ ADDED: Missing parameter
  final FocusNode? focusNode;
  final double? height;

  const StandardTextField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted, // ✅ ADDED: Missing parameter
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction, // ✅ ADDED: Missing parameter
    this.focusNode,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget textField = TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        helperText: helperText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted, // ✅ ADDED: Missing parameter
      onTap: onTap,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction, // ✅ ADDED: Missing parameter
      focusNode: focusNode,
    );

    return height != null ? SizedBox(height: height, child: textField) : textField;
  }
}