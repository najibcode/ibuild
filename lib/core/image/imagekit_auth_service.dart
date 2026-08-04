import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_client.provider.dart';
import '../utils/logger.dart';

/// Strongly-typed response model returned by the `imagekit-auth` Edge Function.
class ImageKitAuthResponse {
  final String token;
  final String signature;
  final int expire;
  final String publicKey;
  final String urlEndpoint;

  const ImageKitAuthResponse({
    required this.token,
    required this.signature,
    required this.expire,
    required this.publicKey,
    required this.urlEndpoint,
  });

  factory ImageKitAuthResponse.fromJson(Map<String, dynamic> json) {
    return ImageKitAuthResponse(
      token: json['token'] as String? ?? '',
      signature: json['signature'] as String? ?? '',
      expire: json['expire'] is int
          ? json['expire'] as int
          : int.tryParse(json['expire'].toString()) ?? 0,
      publicKey: json['publicKey'] as String? ?? '',
      urlEndpoint: json['urlEndpoint'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'signature': signature,
      'expire': expire,
      'publicKey': publicKey,
      'urlEndpoint': urlEndpoint,
    };
  }
}

/// Service dedicated to retrieving secure ImageKit upload authentication credentials.
class ImageKitAuthService {
  final SupabaseClient _client;

  ImageKitAuthService(this._client);

  /// Invokes the `imagekit-auth` Supabase Edge Function to fetch authentication tokens.
  /// Rejects unauthenticated callers (HTTP 401).
  Future<ImageKitAuthResponse> fetchAuthCredentials() async {
    try {
      final response = await _client.functions.invoke('imagekit-auth');

      if (response.status == 401) {
        throw Exception('Unauthorized: Please sign in to request upload authentication.');
      }

      if (response.status != 200) {
        throw Exception('Edge function error status: ${response.status}');
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ImageKitAuthResponse.fromJson(data);
      } else if (data is Map) {
        return ImageKitAuthResponse.fromJson(Map<String, dynamic>.from(data));
      } else {
        throw Exception('Unexpected response payload format from Edge Function.');
      }
    } catch (e) {
      appLogger.e('Failed to fetch ImageKit authentication from Edge Function: $e');
      rethrow;
    }
  }
}

final imageKitAuthServiceProvider = Provider<ImageKitAuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ImageKitAuthService(client);
});
