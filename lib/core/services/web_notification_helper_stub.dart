class WebNotificationHelper {
  static Future<String> getPermissionStatus() async => 'unsupported';
  static Future<bool> requestPermission() async => false;
  static void showNotification({required String title, required String body, String? icon}) {}
}
