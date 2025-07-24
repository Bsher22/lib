import 'package:flutter/material.dart';
import '../responsive_system/responsive_core.dart';
import '../responsive_system/adaptive_layout.dart';

/// Helper class to migrate existing widgets to responsive design
class MigrationHelper {
  /// Convert existing screens to responsive with minimal changes
  static Widget makeResponsive(Widget existingWidget) {
    return ResponsiveContainer(
      child: AdaptiveLayout(
        mobile: existingWidget,
        tablet: existingWidget,
        desktop: existingWidget,
        fallback: existingWidget,
      ),
    );
  }
  
  /// Add responsive padding to existing content
  static Widget addResponsivePadding(Widget child, {
    double? horizontalMultiplier,
    double? verticalMultiplier,
  }) {
    return Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveConfig.spacing(
            context, 
            horizontalMultiplier ?? 2,
          ),
          vertical: ResponsiveConfig.spacing(
            context, 
            verticalMultiplier ?? 1,
          ),
        ),
        child: child,
      ),
    );
  }
  
  /// Convert hardcoded dimensions to responsive
  static double responsiveSize(BuildContext context, double baseSize) {
    return context.responsive<double>(
      mobile: baseSize,
      tablet: baseSize * 1.2,
      desktop: baseSize * 1.4,
    );
  }

  /// Convert hardcoded font sizes to responsive
  static double responsiveFontSize(BuildContext context, double baseFontSize) {
    return ResponsiveConfig.fontSize(context, baseFontSize);
  }

  /// Wrap existing ListView with responsive constraints
  static Widget makeListViewResponsive(
    ListView listView, {
    double? maxWidth,
  }) {
    return Builder(
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? context.maxContentWidth,
          ),
          child: listView,
        ),
      ),
    );
  }

  /// Wrap existing GridView with responsive constraints
  static Widget makeGridViewResponsive(
    GridView gridView, {
    double? maxWidth,
  }) {
    return Builder(
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? context.maxContentWidth,
          ),
          child: gridView,
        ),
      ),
    );
  }

  /// Convert existing Column to responsive layout
  static Widget makeColumnResponsive(
    List<Widget> children, {
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    bool addSpacing = true,
  }) {
    return Builder(
      builder: (context) {
        final spacedChildren = addSpacing
            ? _addSpacingBetweenChildren(context, children)
            : children;

        return ResponsiveContainer(
          child: Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: spacedChildren,
          ),
        );
      },
    );
  }

  /// Convert existing Row to responsive layout with optional wrapping
  static Widget makeRowResponsive(
    List<Widget> children, {
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    bool wrapOnMobile = true,
    bool addSpacing = true,
  }) {
    return Builder(
      builder: (context) {
        final spacedChildren = addSpacing
            ? _addSpacingBetweenChildren(context, children)
            : children;

        if (wrapOnMobile && context.isMobile) {
          return ResponsiveContainer(
            child: Column(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: spacedChildren,
            ),
          );
        }

        return ResponsiveContainer(
          child: Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: spacedChildren,
          ),
        );
      },
    );
  }

  /// Add responsive Card wrapper to existing widget
  static Widget wrapInResponsiveCard(
    Widget child, {
    EdgeInsets? padding,
    double? elevation,
  }) {
    return Builder(
      builder: (context) => Card(
        elevation: elevation ?? context.responsive<double>(
          mobile: 2,
          tablet: 4,
          desktop: 6,
        ),
        margin: EdgeInsets.all(ResponsiveConfig.spacing(context, 1)),
        child: Padding(
          padding: padding ?? EdgeInsets.all(ResponsiveConfig.spacing(context, 2)),
          child: child,
        ),
      ),
    );
  }

  /// Convert existing AppBar to responsive
  static PreferredSizeWidget makeAppBarResponsive(
    String title, {
    List<Widget>? actions,
    Widget? leading,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return Builder(
      builder: (context) => AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveConfig.fontSize(context, 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: actions,
        leading: leading,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: context.responsive<double>(
          mobile: 4,
          tablet: 2,
          desktop: 1,
        ),
      ),
    );
  }

  /// Convert existing buttons to responsive
  static Widget makeButtonResponsive(
    String text,
    VoidCallback? onPressed, {
    bool isPrimary = true,
    Widget? icon,
  }) {
    return Builder(
      builder: (context) {
        final buttonPadding = EdgeInsets.symmetric(
          horizontal: ResponsiveConfig.spacing(context, 3),
          vertical: ResponsiveConfig.spacing(context, 2),
        );

        final textStyle = TextStyle(
          fontSize: ResponsiveConfig.fontSize(context, 16),
        );

        final child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon,
              SizedBox(width: ResponsiveConfig.spacing(context, 1)),
            ],
            Text(text, style: textStyle),
          ],
        );

        if (isPrimary) {
          return ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              padding: buttonPadding,
            ),
            child: child,
          );
        } else {
          return OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: buttonPadding,
            ),
            child: child,
          );
        }
      },
    );
  }

  /// Helper method to add spacing between children
  static List<Widget> _addSpacingBetweenChildren(
    BuildContext context,
    List<Widget> children,
  ) {
    if (children.isEmpty) return children;

    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(
          SizedBox(height: ResponsiveConfig.spacing(context, 1)),
        );
      }
    }
    return spacedChildren;
  }

  /// Quick migration wrapper for existing screens
  static Widget quickMigration(Widget existingScreen) {
    return Builder(
      builder: (context) => Scaffold(
        body: ResponsiveContainer(
          child: existingScreen,
        ),
      ),
    );
  }

  /// Convert existing TextField to responsive
  static Widget makeTextFieldResponsive(
    String label, {
    TextEditingController? controller,
    String? hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    Widget? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveConfig.spacing(context, 1),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: ResponsiveConfig.fontSize(context, 16),
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.all(
              ResponsiveConfig.spacing(context, 2),
            ),
          ),
        ),
      ),
    );
  }
}