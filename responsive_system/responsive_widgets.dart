// ============================================================================
// File: lib/responsive_system/responsive_widgets.dart (FIXED)
// ============================================================================
import 'package:flutter/material.dart';
import 'responsive_config.dart';
import 'enhanced_context_extensions.dart';

/// Enhanced Responsive Text Widget (updated to use new scaling)
class ResponsiveText extends StatelessWidget {
  final String text;
  final double baseFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;
  
  const ResponsiveText(
    this.text, {
    super.key,
    required this.baseFontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.style,
  });
  
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: ResponsiveConfig.fontSize(context, baseFontSize),
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Enhanced ResponsiveButton with ALL missing parameters INCLUDING prefix (FIXED)
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double baseHeight;
  final double? width;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final Color? textColor;
  final double? borderRadius;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  final Widget? child;
  final TextStyle? style;
  final BorderSide? side;
  final Color? borderColor;
  final IconData? icon;
  final Widget? prefix;  // NEW: Added prefix parameter
  final double? iconSize;
  final Size? minimumSize;
  final Size? maximumSize;
  final bool autofocus;
  final FocusNode? focusNode;

  const ResponsiveButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.baseHeight = 48,
    this.width,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.textColor,
    this.borderRadius,
    this.elevation,
    this.padding,
    this.isLoading = false,
    this.child,
    this.style,
    this.side,
    this.borderColor,
    this.icon,
    this.prefix,  // NEW: Added prefix parameter to constructor
    this.iconSize,
    this.minimumSize,
    this.maximumSize,
    this.autofocus = false,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaledHeight = ResponsiveConfig.dimension(context, baseHeight);
    final scaledBorderRadius = ResponsiveConfig.borderRadiusValue(context, borderRadius ?? 8);
    final scaledPadding = padding ?? ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8);
    final scaledIconSize = ResponsiveConfig.iconSize(context, iconSize ?? 20);

    // Determine final colors
    final finalBackgroundColor = backgroundColor;
    final finalForegroundColor = foregroundColor ?? textColor;
    final finalDisabledBackgroundColor = disabledBackgroundColor;
    final finalDisabledForegroundColor = disabledForegroundColor;

    // ✅ FIXED: Calculate minimum size properly to avoid infinite width
    final Size calculatedMinimumSize;
    if (minimumSize != null) {
      calculatedMinimumSize = minimumSize!;
    } else if (width != null) {
      calculatedMinimumSize = Size(width!, scaledHeight);
    } else {
      // ✅ FIXED: Don't use double.infinity, use a reasonable default
      calculatedMinimumSize = Size(0, scaledHeight);
    }

    // Create button style
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: finalBackgroundColor,
      foregroundColor: finalForegroundColor,
      disabledBackgroundColor: finalDisabledBackgroundColor,
      disabledForegroundColor: finalDisabledForegroundColor,
      elevation: elevation,
      padding: scaledPadding,
      minimumSize: calculatedMinimumSize, // ✅ FIXED: Use calculated size
      maximumSize: maximumSize,
      side: side ?? (borderColor != null ? BorderSide(color: borderColor!) : null),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaledBorderRadius),
      ),
      textStyle: style,
    );

    Widget buttonChild = child ?? ResponsiveText(
      text,
      baseFontSize: 16,
      style: style,
    );

    // NEW: Handle prefix widget (takes priority over icon)
    if (prefix != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          prefix!,
          SizedBox(width: ResponsiveConfig.spacing(context, 1)),
          Flexible(child: buttonChild),
        ],
      );
    }
    // Handle icon if provided and no prefix
    else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: scaledIconSize),
          SizedBox(width: ResponsiveConfig.spacing(context, 1)),
          Flexible(child: buttonChild),
        ],
      );
    }

    // Add loading indicator if loading
    if (isLoading) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: scaledIconSize,
            height: scaledIconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                finalForegroundColor ?? Colors.white,
              ),
            ),
          ),
          SizedBox(width: ResponsiveConfig.spacing(context, 1)),
          buttonChild,
        ],
      );
    }

    // ✅ FIXED: Wrap in proper container based on width parameter
    Widget finalButton = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      autofocus: autofocus,
      focusNode: focusNode,
      child: buttonChild,
    );

    // ✅ FIXED: Only apply SizedBox if width is explicitly provided
    if (width != null) {
      return SizedBox(
        width: width,
        height: scaledHeight,
        child: finalButton,
      );
    } else {
      // ✅ FIXED: Let the button size itself naturally
      return SizedBox(
        height: scaledHeight,
        child: finalButton,
      );
    }
  }
}

/// Enhanced ResponsiveCard with ALL missing parameters
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final double? maxHeight;
  final double? baseBorderRadius;
  final Color? backgroundColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final Clip clipBehavior;
  final Border? border;
  final Color? borderColor;
  final double? borderWidth;
  final VoidCallback? onTap;
  final bool semanticContainer;

  const ResponsiveCard({
    Key? key,
    required this.child,
    this.maxWidth,
    this.maxHeight,
    this.baseBorderRadius,
    this.backgroundColor,
    this.elevation,
    this.padding,
    this.margin,
    this.shadowColor,
    this.surfaceTintColor,
    this.clipBehavior = Clip.none,
    this.border,
    this.borderColor,
    this.borderWidth,
    this.onTap,
    this.semanticContainer = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaledBorderRadius = ResponsiveConfig.borderRadiusValue(context, baseBorderRadius ?? 12);
    final scaledPadding = padding ?? ResponsiveConfig.paddingAll(context, 16);
    final scaledMargin = margin ?? EdgeInsets.zero;

    Widget cardChild = Padding(
      padding: scaledPadding,
      child: child,
    );

    // Apply constraints if specified
    if (maxWidth != null || maxHeight != null) {
      cardChild = ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? double.infinity,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: cardChild,
      );
    }

    // Create the card shape with borders
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(scaledBorderRadius),
      side: border?.top ?? (borderColor != null 
        ? BorderSide(color: borderColor!, width: borderWidth ?? 1.0)
        : BorderSide.none),
    );

    Widget cardWidget = Card(
      color: backgroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      clipBehavior: clipBehavior,
      shape: shape,
      semanticContainer: semanticContainer,
      margin: scaledMargin,
      child: cardChild,
    );

    // Add tap functionality if provided
    if (onTap != null) {
      cardWidget = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(scaledBorderRadius),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

/// ResponsiveSpacing widget (unchanged)
class ResponsiveSpacing extends StatelessWidget {
  final double multiplier;
  final Axis direction;

  const ResponsiveSpacing({
    Key? key,
    required this.multiplier,
    this.direction = Axis.vertical,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveConfig.spacing(context, multiplier);
    
    return direction == Axis.vertical
        ? SizedBox(height: spacing)
        : SizedBox(width: spacing);
  }
}

/// NEW: ResponsiveGrid widget for grid layouts
class ResponsiveGrid extends StatelessWidget {
  final int crossAxisCount;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final double childAspectRatio;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveGrid({
    Key? key,
    required this.crossAxisCount,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.childAspectRatio = 1.0,
    required this.children,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaledCrossAxisSpacing = ResponsiveConfig.spacing(context, crossAxisSpacing ?? 1);
    final scaledMainAxisSpacing = ResponsiveConfig.spacing(context, mainAxisSpacing ?? 1);
    final scaledPadding = padding ?? ResponsiveConfig.paddingAll(context, 8);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: scaledCrossAxisSpacing,
      mainAxisSpacing: scaledMainAxisSpacing,
      childAspectRatio: childAspectRatio,
      padding: scaledPadding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      children: children,
    );
  }
}

/// NEW: ResponsiveWrapper widget for constraining content
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final double? maxHeight;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry alignment;

  const ResponsiveWrapper({
    Key? key,
    required this.child,
    this.maxWidth,
    this.maxHeight,
    this.padding,
    this.margin,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaledPadding = padding ?? EdgeInsets.zero;
    final scaledMargin = margin ?? EdgeInsets.zero;

    return Container(
      padding: scaledPadding,
      margin: scaledMargin,
      alignment: alignment,
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: child,
    );
  }
}