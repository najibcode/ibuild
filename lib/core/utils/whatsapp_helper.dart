import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  /// Clean and sanitize text for universal WhatsApp compatibility across all devices
  /// Removes composite emoji variation selectors (\\uFE0F) and exotic box-drawing
  /// characters that cause the "?" question mark box icon on Android/iOS/Web WhatsApp.
  static String sanitizeMessage(String text) {
    String cleaned = text;

    // Replace unicode box-drawing lines with standard clean dashes
    cleaned = cleaned.replaceAll(RegExp(r'[━─═_]{3,}'), '----------------------------------------');

    // Remove variation selector 16 (\uFE0F) and zero-width joiners (\u200D) which break on WhatsApp URI decoders
    cleaned = cleaned.replaceAll('\uFE0F', '');
    cleaned = cleaned.replaceAll('\uFE0E', '');
    cleaned = cleaned.replaceAll('\u200D', '');

    return cleaned.trim();
  }

  /// Launch WhatsApp with universal compatibility
  static Future<void> shareMessage({
    required BuildContext context,
    required String message,
    String? phoneNumber,
    String successNotice = 'Message prepared & opening WhatsApp...',
  }) async {
    final sanitized = sanitizeMessage(message);

    // Copy clean text to clipboard as universal fallback
    await Clipboard.setData(ClipboardData(text: sanitized));

    final queryParams = <String, String>{
      'text': sanitized,
    };
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      // Clean phone number (strip spaces, dashes, parentheses)
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      queryParams['phone'] = cleanPhone;
    }

    final uri = Uri(
      scheme: 'https',
      host: 'api.whatsapp.com',
      path: '/send',
      queryParameters: queryParams,
    );

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Fallback to wa.me
        final waUri = Uri(
          scheme: 'https',
          host: 'wa.me',
          path: phoneNumber != null ? '/${phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')}' : '/',
          queryParameters: {'text': sanitized},
        );
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Browser popup blocker or no client installed
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successNotice (Copied to clipboard ✓)'),
          backgroundColor: const Color(0xFF25D366),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
