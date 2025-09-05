// lib/shared/widgets/app_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Standardized text field component for the GeoAsist application
/// Provides consistent styling, validation, and accessibility features
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onEditingComplete;
  final void Function(String)? onFieldSubmitted;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool required;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? semanticLabel;
  final AppTextFieldType type;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.validator,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.semanticLabel,
    this.type = AppTextFieldType.standard,
    this.focusNode,
  });

  /// Email text field constructor
  const AppTextField.email({
    Key? key,
    required String label,
    String? hint,
    String? helperText,
    String? errorText,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function()? onEditingComplete,
    void Function(String)? onFieldSubmitted,
    bool enabled = true,
    bool readOnly = false,
    bool required = false,
    String? semanticLabel,
    FocusNode? focusNode,
  }) : this(
         key: key,
         label: label,
         hint: hint ?? 'ejemplo@correo.com',
         helperText: helperText,
         errorText: errorText,
         controller: controller,
         validator: validator,
         onChanged: onChanged,
         onEditingComplete: onEditingComplete,
         onFieldSubmitted: onFieldSubmitted,
         enabled: enabled,
         readOnly: readOnly,
         required: required,
         keyboardType: TextInputType.emailAddress,
         textInputAction: TextInputAction.next,
         prefixIcon: Icons.email_outlined,
         semanticLabel: semanticLabel,
         type: AppTextFieldType.email,
         focusNode: focusNode,
       );

  /// Password text field constructor
  const AppTextField.password({
    Key? key,
    required String label,
    String? hint,
    String? helperText,
    String? errorText,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function()? onEditingComplete,
    void Function(String)? onFieldSubmitted,
    bool enabled = true,
    bool readOnly = false,
    bool required = false,
    String? semanticLabel,
    FocusNode? focusNode,
  }) : this(
         key: key,
         label: label,
         hint: hint ?? 'Ingresa tu contraseña',
         helperText: helperText,
         errorText: errorText,
         controller: controller,
         validator: validator,
         onChanged: onChanged,
         onEditingComplete: onEditingComplete,
         onFieldSubmitted: onFieldSubmitted,
         obscureText: true,
         enabled: enabled,
         readOnly: readOnly,
         required: required,
         keyboardType: TextInputType.visiblePassword,
         textInputAction: TextInputAction.done,
         prefixIcon: Icons.lock_outlined,
         semanticLabel: semanticLabel,
         type: AppTextFieldType.password,
         focusNode: focusNode,
       );

  /// Search text field constructor
  const AppTextField.search({
    Key? key,
    required String label,
    String? hint,
    TextEditingController? controller,
    void Function(String)? onChanged,
    void Function(String)? onFieldSubmitted,
    bool enabled = true,
    String? semanticLabel,
    FocusNode? focusNode,
  }) : this(
         key: key,
         label: label,
         hint: hint ?? 'Buscar...',
         controller: controller,
         onChanged: onChanged,
         onFieldSubmitted: onFieldSubmitted,
         enabled: enabled,
         keyboardType: TextInputType.text,
         textInputAction: TextInputAction.search,
         prefixIcon: Icons.search_outlined,
         semanticLabel: semanticLabel,
         type: AppTextFieldType.search,
         focusNode: focusNode,
       );

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _obscureText = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;
    _errorText = widget.errorText;
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorText != widget.errorText) {
      setState(() {
        _errorText = widget.errorText;
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _validateInput(String value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (error != _errorText) {
        setState(() {
          _errorText = error;
        });
        
        // Announce validation errors to screen readers
        if (error != null) {
          _announceError(error);
        }
      }
    }
  }

  void _announceError(String error) {
    SemanticsService.announce(
      'Error de validación: $error',
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldProperties = _getFieldProperties();
    
    Widget textField = TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: _obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      onChanged: (value) {
        widget.onChanged?.call(value);
        if (widget.validator != null) {
          _validateInput(value);
        }
      },
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted,
      style: fieldProperties.textStyle,
      decoration: InputDecoration(
        labelText: widget.required ? '${widget.label} *' : widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: _errorText,
        prefixIcon: widget.prefixIcon != null 
            ? Icon(widget.prefixIcon, color: fieldProperties.iconColor)
            : null,
        suffixIcon: _buildSuffixIcon(fieldProperties),
        border: fieldProperties.border,
        enabledBorder: fieldProperties.enabledBorder,
        focusedBorder: fieldProperties.focusedBorder,
        errorBorder: fieldProperties.errorBorder,
        focusedErrorBorder: fieldProperties.focusedErrorBorder,
        disabledBorder: fieldProperties.disabledBorder,
        filled: fieldProperties.filled,
        fillColor: fieldProperties.fillColor,
        contentPadding: fieldProperties.contentPadding,
        labelStyle: fieldProperties.labelStyle,
        hintStyle: fieldProperties.hintStyle,
        helperStyle: fieldProperties.helperStyle,
        errorStyle: fieldProperties.errorStyle,
        counterStyle: fieldProperties.counterStyle,
      ),
    );

    // Wrap with column to add label if needed
    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textField,
      ],
    );

    // Add semantics
    if (widget.semanticLabel != null) {
      field = Semantics(
        label: _buildSemanticLabel(),
        textField: true,
        child: field,
      );
    }

    return field;
  }

  Widget? _buildSuffixIcon(_FieldProperties properties) {
    if (widget.type == AppTextFieldType.password) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: properties.iconColor,
        ),
        onPressed: _togglePasswordVisibility,
        tooltip: _obscureText ? 'Mostrar contraseña' : 'Ocultar contraseña',
      );
    }
    
    return widget.suffixIcon;
  }

  String _buildSemanticLabel() {
    String label = widget.semanticLabel ?? widget.label;
    if (widget.required) {
      label += ', campo requerido';
    }
    if (widget.hint != null) {
      label += ', sugerencia: ${widget.hint}';
    }
    if (_errorText != null) {
      label += ', error: $_errorText';
    }
    if (widget.helperText != null) {
      label += ', ayuda: ${widget.helperText}';
    }
    return label;
  }

  _FieldProperties _getFieldProperties() {
    switch (widget.type) {
      case AppTextFieldType.standard:
        return _FieldProperties(
          textStyle: AppTextStyles.bodyLarge,
          labelStyle: AppTextStyles.labelLarge,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          helperStyle: AppTextStyles.bodySmall,
          errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          counterStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.outline),
          ),
          filled: false,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          iconColor: AppColors.onSurfaceVariant,
        );
      case AppTextFieldType.email:
      case AppTextFieldType.password:
        return _FieldProperties(
          textStyle: AppTextStyles.bodyLarge,
          labelStyle: AppTextStyles.labelLarge,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          helperStyle: AppTextStyles.bodySmall,
          errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          counterStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.outline, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.outline, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error, width: 2.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.outline, width: 1.5),
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          iconColor: AppColors.primary,
        );
      case AppTextFieldType.search:
        return _FieldProperties(
          textStyle: AppTextStyles.bodyLarge,
          labelStyle: AppTextStyles.labelLarge,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          helperStyle: AppTextStyles.bodySmall,
          errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          counterStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.outline),
          ),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          iconColor: AppColors.onSurfaceVariant,
        );
    }
  }
}

/// Text field type enumeration
enum AppTextFieldType {
  standard,
  email,
  password,
  search,
}

/// Internal class for field properties
class _FieldProperties {
  final TextStyle textStyle;
  final TextStyle labelStyle;
  final TextStyle hintStyle;
  final TextStyle helperStyle;
  final TextStyle errorStyle;
  final TextStyle counterStyle;
  final InputBorder border;
  final InputBorder enabledBorder;
  final InputBorder focusedBorder;
  final InputBorder errorBorder;
  final InputBorder focusedErrorBorder;
  final InputBorder disabledBorder;
  final bool filled;
  final Color fillColor;
  final EdgeInsetsGeometry contentPadding;
  final Color iconColor;

  const _FieldProperties({
    required this.textStyle,
    required this.labelStyle,
    required this.hintStyle,
    required this.helperStyle,
    required this.errorStyle,
    required this.counterStyle,
    required this.border,
    required this.enabledBorder,
    required this.focusedBorder,
    required this.errorBorder,
    required this.focusedErrorBorder,
    required this.disabledBorder,
    required this.filled,
    required this.fillColor,
    required this.contentPadding,
    required this.iconColor,
  });
}