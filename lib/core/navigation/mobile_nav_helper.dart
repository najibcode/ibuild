import 'package:flutter/material.dart';

/// Central controller for the root mobile scaffold and navigation drawer.
/// Allows any screen or nested Scaffold in the application to reliably open the root drawer.
class MobileNavHelper {
  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  /// Opens the root navigation drawer from anywhere in the widget tree,
  /// even from inside nested Scaffolds.
  static void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  /// Closes the root navigation drawer if open.
  static void closeDrawer() {
    scaffoldKey.currentState?.closeDrawer();
  }

  /// Returns a responsive leading widget for AppBars:
  /// - Back button if [hasBack] is true
  /// - Hamburger menu ONLY on narrow mobile screens (width < 800)
  /// - Null on desktop/web (width >= 800) to eliminate dummy hamburger symbols
  static Widget? buildLeading(
    BuildContext context, {
    bool hasBack = false,
    VoidCallback? onBackPressed,
  }) {
    if (hasBack) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Go back',
        onPressed: () {
          if (onBackPressed != null) {
            onBackPressed();
          } else {
            Navigator.maybePop(context);
          }
        },
      );
    }
    // On web/desktop with sidebar (width >= 800), return null to hide hamburger
    if (MediaQuery.of(context).size.width >= 800) {
      return null;
    }
    // Mobile navigation hamburger
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'Open navigation menu',
      onPressed: openDrawer,
    );
  }
}

