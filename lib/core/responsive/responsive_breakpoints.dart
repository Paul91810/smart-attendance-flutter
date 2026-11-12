import 'package:flutter/material.dart';

/// Screen size breakpoints according to Material 3 responsive guidelines:
/// - Compact: width < 600 (phones in portrait)
/// - Medium: 600 <= width <= 900 (foldables, small tablets, phones in landscape)
/// - Expanded: width > 900 (tablets in landscape, desktop)
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double compactMax = 600.0;
  static const double mediumMax = 900.0;
  static const double mobileMax = 600.0; // Backwards compatibility

  // Max readable content widths
  static const double maxFormWidth = 420.0;
  static const double maxContentWidth = 720.0;
  static const double maxExpandedContentWidth = 1100.0;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactMax;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compactMax && width <= mediumMax;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width > mediumMax;

  // Aliases for compatibility
  static bool isMobile(BuildContext context) => isCompact(context);
  static bool isTablet(BuildContext context) => !isCompact(context);
}
