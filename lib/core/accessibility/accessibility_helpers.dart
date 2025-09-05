// lib/core/accessibility/accessibility_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'dart:math' as math;

/// Comprehensive accessibility utilities for WCAG 2.1 AA compliance
/// Provides semantic labels, focus management, and screen reader support
class AccessibilityHelpers {
  /// Announce a message to screen readers
  static void announce(String message, {
    Assertiveness assertiveness = Assertiveness.polite,
  }) {
    SemanticsService.announce(message, TextDirection.ltr, assertiveness: assertiveness);
  }

  /// Announce an error message with high priority
  static void announceError(String errorMessage) {
    announce('Error: $errorMessage', assertiveness: Assertiveness.assertive);
  }

  /// Announce success message
  static void announceSuccess(String successMessage) {
    announce('Éxito: $successMessage', assertiveness: Assertiveness.polite);
  }

  /// Check if high contrast is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Check if reduced motion is preferred
  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get appropriate font size based on accessibility preferences
  static double getAccessibleFontSize(BuildContext context, double baseFontSize) {
    final textScaler = MediaQuery.of(context).textScaler;
    final scaleFactor = textScaler.scale(baseFontSize) / baseFontSize;
    return baseFontSize * scaleFactor.clamp(0.8, 2.0);
  }

  /// Create semantic label with context
  static String buildSemanticLabel({
    required String baseLabel,
    String? hint,
    String? value,
    String? role,
    bool isRequired = false,
    bool isDisabled = false,
    String? errorMessage,
  }) {
    final List<String> parts = [];
    
    parts.add(baseLabel);
    
    if (role != null) {
      parts.add(role);
    }
    
    if (value != null && value.isNotEmpty) {
      parts.add('valor actual: $value');
    }
    
    if (isRequired) {
      parts.add('campo requerido');
    }
    
    if (isDisabled) {
      parts.add('deshabilitado');
    }
    
    if (hint != null && hint.isNotEmpty) {
      parts.add('sugerencia: $hint');
    }
    
    if (errorMessage != null && errorMessage.isNotEmpty) {
      parts.add('error: $errorMessage');
    }
    
    return parts.join(', ');
  }

  /// Check color contrast compliance
  static bool meetsContrastRequirements(Color foreground, Color background, {
    bool isLargeText = false,
  }) {
    final ratio = _calculateContrastRatio(foreground, background);
    final requiredRatio = isLargeText ? 3.0 : 4.5; // WCAG AA standards
    return ratio >= requiredRatio;
  }

  /// Calculate color contrast ratio
  static double _calculateContrastRatio(Color color1, Color color2) {
    final lum1 = _relativeLuminance(color1);
    final lum2 = _relativeLuminance(color2);
    final lighter = lum1 > lum2 ? lum1 : lum2;
    final darker = lum1 > lum2 ? lum2 : lum1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate relative luminance of a color
  static double _relativeLuminance(Color color) {
    final r = _gammaCorrect((color.r * 255.0).round() / 255.0);
    final g = _gammaCorrect((color.g * 255.0).round() / 255.0);
    final b = _gammaCorrect((color.b * 255.0).round() / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Apply gamma correction
  static double _gammaCorrect(double colorValue) {
    return colorValue <= 0.03928 
        ? colorValue / 12.92 
        : math.pow((colorValue + 0.055) / 1.055, 2.4).toDouble();
  }
}

/// Enhanced semantics wrapper for interactive elements
class AccessibleWidget extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final String? value;
  final VoidCallback? onTap;
  final bool isButton;
  final bool isTextField;
  final bool isEnabled;
  final bool isSelected;
  final bool isExpanded;
  final String? errorMessage;
  final VoidCallback? onLongPress;

  const AccessibleWidget({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.value,
    this.onTap,
    this.isButton = false,
    this.isTextField = false,
    this.isEnabled = true,
    this.isSelected = false,
    this.isExpanded = false,
    this.errorMessage,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AccessibilityHelpers.buildSemanticLabel(
        baseLabel: label,
        hint: hint,
        value: value,
        role: _getRole(),
        isDisabled: !isEnabled,
        errorMessage: errorMessage,
      ),
      button: isButton,
      textField: isTextField,
      enabled: isEnabled,
      selected: isSelected,
      expanded: isExpanded,
      onTap: onTap != null ? () {
        HapticFeedback.lightImpact();
        onTap!();
      } : null,
      onLongPress: onLongPress != null ? () {
        HapticFeedback.mediumImpact();
        onLongPress!();
      } : null,
      child: child,
    );
  }

  String? _getRole() {
    if (isButton) return 'botón';
    if (isTextField) return 'campo de texto';
    return null;
  }
}

/// Focus management helper for navigation
class FocusManager {
  static final Map<String, FocusNode> _focusNodes = {};

  /// Get or create a focus node with the given key
  static FocusNode getFocusNode(String key) {
    return _focusNodes.putIfAbsent(key, () => FocusNode());
  }

  /// Move focus to the next focusable element
  static void moveToNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Move focus to the previous focusable element
  static void moveToPrevious(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Request focus for a specific node
  static void requestFocus(String key) {
    final node = _focusNodes[key];
    node?.requestFocus();
  }

  /// Clear all stored focus nodes (call when disposing)
  static void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
  }
}

/// Screen reader announcements widget
class AnnouncementWidget extends StatefulWidget {
  final Widget child;
  final String? announceOnMount;
  final String? announceOnDispose;

  const AnnouncementWidget({
    super.key,
    required this.child,
    this.announceOnMount,
    this.announceOnDispose,
  });

  @override
  State<AnnouncementWidget> createState() => _AnnouncementWidgetState();
}

class _AnnouncementWidgetState extends State<AnnouncementWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.announceOnMount != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AccessibilityHelpers.announce(widget.announceOnMount!);
      });
    }
  }

  @override
  void dispose() {
    if (widget.announceOnDispose != null) {
      AccessibilityHelpers.announce(widget.announceOnDispose!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// High contrast theme provider
class AccessibilityTheme {
  static ThemeData getHighContrastTheme(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primary: isDarkMode ? Colors.white : Colors.black,
        onPrimary: isDarkMode ? Colors.black : Colors.white,
        secondary: isDarkMode ? Colors.white70 : Colors.black87,
        onSecondary: isDarkMode ? Colors.black : Colors.white,
        error: isDarkMode ? Colors.red[300]! : Colors.red[800]!,
        onError: isDarkMode ? Colors.black : Colors.white,
        surface: isDarkMode ? Colors.grey[900]! : Colors.grey[100]!,
        onSurface: isDarkMode ? Colors.white : Colors.black,
      ),
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: isDarkMode ? Colors.white : Colors.black,
        displayColor: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }
}

/// Skip link widget for keyboard navigation
class SkipLink extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  const SkipLink({
    super.key,
    required this.text,
    required this.onPressed,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -100,
      left: 0,
      child: Focus(
        focusNode: focusNode,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            // Move skip link into view when focused
            // This would typically be handled by scrolling logic
          }
        },
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).primaryColor,
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Accessible form field with enhanced semantics
class AccessibleFormField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool isRequired;
  final String? errorMessage;
  final String? helperText;

  const AccessibleFormField({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.errorMessage,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with required indicator
          Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (isRequired)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '*',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Form field
          Semantics(
            label: AccessibilityHelpers.buildSemanticLabel(
              baseLabel: label,
              isRequired: isRequired,
              errorMessage: errorMessage,
              hint: helperText,
            ),
            child: child,
          ),
          
          // Helper text
          if (helperText != null && errorMessage == null) ...[
            const SizedBox(height: 4),
            Text(
              helperText!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          
          // Error message
          if (errorMessage != null) ...[
            const SizedBox(height: 4),
            Semantics(
              liveRegion: true,
              child: Text(
                errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Live region for dynamic content announcements
class LiveRegion extends StatefulWidget {
  final String text;
  final Widget child;
  final bool isPolite;

  const LiveRegion({
    super.key,
    required this.text,
    required this.child,
    this.isPolite = true,
  });

  @override
  State<LiveRegion> createState() => _LiveRegionState();
}

class _LiveRegionState extends State<LiveRegion> {
  String _previousText = '';

  @override
  void didUpdateWidget(LiveRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && _previousText != widget.text) {
      _previousText = widget.text;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AccessibilityHelpers.announce(
          widget.text,
          assertiveness: widget.isPolite 
            ? Assertiveness.polite 
            : Assertiveness.assertive,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: widget.child,
    );
  }
}