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
}
