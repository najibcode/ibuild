import 'package:flutter/material.dart';

/// Responsive layout helper with mobile (<800px), tablet (800–1100px),
/// and desktop (>1100px) breakpoints.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget desktopLayout;
  /// Optional tablet layout. Falls back to [desktopLayout] if not provided.
  final Widget? tabletLayout;

  const ResponsiveLayout({
    super.key,
    required this.mobileLayout,
    required this.desktopLayout,
    this.tabletLayout,
  });

  static const double mobileBreakpoint = 800;
  static const double tabletBreakpoint = 1100;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobileBreakpoint && w < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// Returns 1 for mobile, 2 for tablet, 3+ for desktop — useful for grid column counts.
  static int adaptiveColumns(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return mobileLayout;
        } else if (constraints.maxWidth < tabletBreakpoint && tabletLayout != null) {
          return tabletLayout!;
        } else {
          return desktopLayout;
        }
      },
    );
  }
}
