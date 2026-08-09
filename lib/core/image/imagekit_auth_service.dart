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

  /// Validates that all required fields are non-empty.
  bool get isValid =>
      token.isNotEmpty &&
      signature.isNotEmpty &&
      expire > 0 &&
      publicKey.isNotEmpty;
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

      // In functions_client v2.6+, non-2xx responses throw FunctionException
      // before reaching here. The status check below is a defensive fallback.
      if (response.status != 200) {
        throw Exception('Edge function returned status: ${response.status}');
      }

      final data = response.data;
      late final ImageKitAuthResponse authResponse;

      if (data is Map<String, dynamic>) {
        authResponse = ImageKitAuthResponse.fromJson(data);
      } else if (data is Map) {
        authResponse = ImageKitAuthResponse.fromJson(Map<String, dynamic>.from(data));
      } else {
        throw Exception(
          'Unexpected response format from imagekit-auth Edge Function: ${data.runtimeType}',
        );
      }

      // Validate the response has all required fields
      if (!authResponse.isValid) {
        throw Exception(
          'Incomplete auth response from edge function: '
          'token=${authResponse.token.isNotEmpty}, '
          'signature=${authResponse.signature.isNotEmpty}, '
          'expire=${authResponse.expire}, '
          'publicKey=${authResponse.publicKey.isNotEmpty}',
        );
      }

      return authResponse;
    } on FunctionException catch (e) {
      // The functions_client throws FunctionException for non-2xx HTTP status codes.
      // This includes 401 (unauthorized), 500 (server error / missing secrets), etc.
      final statusMsg = 'status=${e.status}';
      final detailsMsg = e.details != null ? ', details=${e.details}' : '';
      appLogger.e('ImageKit auth edge function error ($statusMsg$detailsMsg)');

      if (e.status == 401) {
        throw Exception(
          'Unauthorized: Please sign in to upload images. '
          'Your session may have expired.',
        );
      }
      if (e.status == 500) {
        throw Exception(
          'ImageKit server configuration error. '
          'Please ensure ImageKit secrets are configured in Supabase.',
        );
      }
      throw Exception('ImageKit auth failed ($statusMsg$detailsMsg)');
    } catch (e) {
      appLogger.e('Failed to fetch ImageKit authentication: $e');
      rethrow;
    }
  }
}

final imageKitAuthServiceProvider = Provider<ImageKitAuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ImageKitAuthService(client);
});
