import 'package:flutter/material.dart';
import 'responsive_breakpoints.dart';

typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
);

class ResponsiveLayout extends StatelessWidget {
  final ResponsiveWidgetBuilder? compact;
  final ResponsiveWidgetBuilder? medium;
  final ResponsiveWidgetBuilder? expanded;

  // Backwards compatibility aliases for existing phase code
  final ResponsiveWidgetBuilder? mobile;
  final ResponsiveWidgetBuilder? tablet;

  const ResponsiveLayout({
    super.key,
    this.compact,
    this.medium,
    this.expanded,
    this.mobile,
    this.tablet,
  }) : assert(
          compact != null || mobile != null,
          'Either compact or mobile builder must be provided',
        );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width > ResponsiveBreakpoints.mediumMax) {
          if (expanded != null) return expanded!(context, constraints);
          if (medium != null) return medium!(context, constraints);
          if (tablet != null) return tablet!(context, constraints);
        } else if (width >= ResponsiveBreakpoints.compactMax) {
          if (medium != null) return medium!(context, constraints);
          if (tablet != null) return tablet!(context, constraints);
          if (expanded != null) return expanded!(context, constraints);
        }

        final defaultCompact = compact ?? mobile!;
        return defaultCompact(context, constraints);
      },
    );
  }
}

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.maxContentWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
