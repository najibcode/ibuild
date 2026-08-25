// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class WebNotificationHelper {
  static Future<String> getPermissionStatus() async {
    try {
      if (html.Notification.supported) {
        return html.Notification.permission ?? 'default';
      }
    } catch (_) {}
    return 'unsupported';
  }

  static Future<bool> requestPermission() async {
    try {
      if (html.Notification.supported) {
        final result = await html.Notification.requestPermission();
        return result == 'granted';
      }
    } catch (_) {}
    return false;
  }

  static void showNotification({required String title, required String body, String? icon}) {
    try {
      if (html.Notification.supported && html.Notification.permission == 'granted') {
        html.Notification(
          title,
          body: body,
          icon: icon ?? 'icons/Icon-192.png',
        );
      }
    } catch (_) {}
  }
}
