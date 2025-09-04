// lib/widgets/adaptive_components.dart
import 'package:flutter/material.dart';

/// 📱 COMPONENTES ADAPTATIVOS ANDROID 15
/// Se adaptan automáticamente al tamaño de pantalla y plataforma
class AdaptiveComponents {
  
  /// Breakpoints para diseño responsivo
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;
  static const double desktopBreakpoint = 1920;

  /// Detecta el tipo de dispositivo
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Layout adaptativo principal
  static Widget adaptiveLayout({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    return LayoutBuilder(
      builder: (layoutContext, constraints) {
        // Use constraints width instead of MediaQuery for more reliable detection
        final width = constraints.maxWidth;
        
        if (width >= tabletBreakpoint) {
          return desktop ?? tablet ?? mobile;
        } else if (width >= mobileBreakpoint) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }

  /// Navigation adaptativa
  static Widget adaptiveNavigation({
    required BuildContext context,
    required int selectedIndex,
    required ValueChanged<int> onDestinationSelected,
    required List<NavigationDestination> destinations,
    Widget? body,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.desktop:
      case DeviceType.tablet:
        return Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations.map((dest) {
                return NavigationRailDestination(
                  icon: dest.icon,
                  selectedIcon: dest.selectedIcon,
                  label: Text(dest.label),
                );
              }).toList(),
              extended: deviceType == DeviceType.desktop,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            if (body != null) Expanded(child: body),
          ],
        );
      
      case DeviceType.mobile:
        return Scaffold(
          body: body,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onDestinationSelected,
            type: BottomNavigationBarType.fixed,
            items: destinations.map((dest) {
              return BottomNavigationBarItem(
                icon: dest.icon,
                activeIcon: dest.selectedIcon ?? dest.icon,
                label: dest.label,
              );
            }).toList(),
          ),
        );
    }
  }

  /// Card adaptativa
  static Widget adaptiveCard({
    required BuildContext context,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    final deviceType = getDeviceType(context);
    final defaultPadding = deviceType == DeviceType.mobile 
      ? const EdgeInsets.all(12) 
      : const EdgeInsets.all(16);
    
    final defaultMargin = deviceType == DeviceType.mobile
      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
      : const EdgeInsets.all(8);

    return Card(
      margin: margin ?? defaultMargin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? defaultPadding,
          child: child,
        ),
      ),
    );
  }

  /// Grid adaptativo
  static Widget adaptiveGrid({
    required BuildContext context,
    required List<Widget> children,
    double? spacing,
    double? runSpacing,
  }) {
    final deviceType = getDeviceType(context);
    int crossAxisCount;
    
    switch (deviceType) {
      case DeviceType.mobile:
        crossAxisCount = 2;
        break;
      case DeviceType.tablet:
        crossAxisCount = 3;
        break;
      case DeviceType.desktop:
        crossAxisCount = 4;
        break;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing ?? 16,
      mainAxisSpacing: runSpacing ?? 16,
      children: children,
    );
  }

  /// Dialog adaptativo
  static Future<T?> showAdaptiveDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    final deviceType = getDeviceType(context);
    
    if (deviceType == DeviceType.mobile) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: builder(context),
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: builder,
      );
    }
  }

  /// Menu adaptativo
  static Widget adaptiveMenu({
    required BuildContext context,
    required Widget child,
    required List<PopupMenuEntry> items,
    PopupMenuItemSelected? onSelected,
  }) {
    final deviceType = getDeviceType(context);
    
    if (deviceType == DeviceType.mobile) {
      return PopupMenuButton(
        itemBuilder: (context) => items,
        onSelected: onSelected,
        child: child,
      );
    } else {
      return MenuAnchor(
        builder: (context, controller, child) {
          return InkWell(
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: child,
          );
        },
        menuChildren: items.map((item) {
          if (item is PopupMenuItem) {
            return MenuItemButton(
              onPressed: () => onSelected?.call(item.value),
              child: item.child,
            );
          }
          return const SizedBox.shrink();
        }).toList(),
        child: child,
      );
    }
  }

  /// Text Field adaptativo
  static Widget adaptiveTextField({
    required String label,
    String? hint,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
      ),
    );
  }

  /// Button adaptativo
  static Widget adaptiveButton({
    required VoidCallback? onPressed,
    required String text,
    Widget? icon,
    ButtonStyle? style,
    bool isOutlined = false,
    bool isText = false,
  }) {
    if (isText) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: Text(text),
        style: style,
      );
    }
    
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: Text(text),
        style: style,
      );
    }
    
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon ?? const SizedBox.shrink(),
      label: Text(text),
      style: style,
    );
  }

  /// Lista adaptativa
  static Widget adaptiveList({
    required BuildContext context,
    required List<Widget> children,
    bool shrinkWrap = false,
  }) {
    final deviceType = getDeviceType(context);
    
    if (deviceType == DeviceType.mobile) {
      return ListView(
        shrinkWrap: shrinkWrap,
        children: children,
      );
    } else {
      // Para tablet/desktop, usar más padding
      return ListView(
        shrinkWrap: shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: children,
      );
    }
  }

  /// Spacing adaptativo
  static double adaptiveSpacing(BuildContext context, {
    double mobile = 8,
    double tablet = 16,
    double desktop = 24,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
    }
  }

  /// Padding adaptativo
  static EdgeInsets adaptivePadding(BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile ?? const EdgeInsets.all(16);
      case DeviceType.tablet:
        return tablet ?? const EdgeInsets.all(24);
      case DeviceType.desktop:
        return desktop ?? const EdgeInsets.all(32);
    }
  }

  /// Tamaño de fuente adaptativo
  static double adaptiveFontSize(BuildContext context, {
    double mobile = 16,
    double tablet = 18,
    double desktop = 20,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
    }
  }

  /// Contenedor con ancho máximo adaptativo
  static Widget adaptiveContainer({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    final deviceType = getDeviceType(context);
    double? containerMaxWidth;
    
    switch (deviceType) {
      case DeviceType.mobile:
        containerMaxWidth = null; // Sin restricción en móvil
        break;
      case DeviceType.tablet:
        containerMaxWidth = maxWidth ?? 800;
        break;
      case DeviceType.desktop:
        containerMaxWidth = maxWidth ?? 1200;
        break;
    }

    Widget container = Container(
      width: double.infinity,
      constraints: containerMaxWidth != null 
        ? BoxConstraints(maxWidth: containerMaxWidth)
        : null,
      padding: padding,
      margin: margin,
      child: child,
    );

    // Centrar en tablet/desktop
    if (deviceType != DeviceType.mobile && containerMaxWidth != null) {
      return Center(child: container);
    }

    return container;
  }

  /// SafeArea adaptativo
  static Widget adaptiveSafeArea({
    required Widget child,
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
  }) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}

/// Enum para tipos de dispositivo
enum DeviceType { mobile, tablet, desktop }

/// Clase para destinos de navegación unificados
class NavigationDestination {
  final Widget icon;
  final Widget? selectedIcon;
  final String label;

  const NavigationDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}