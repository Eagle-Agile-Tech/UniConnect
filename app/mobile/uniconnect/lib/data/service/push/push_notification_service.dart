import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.read(apiClientProvider));
});

class PushNotificationService {
  final ApiClient _api;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription? _tokenRefreshSub;
  bool _initialized = false;

  PushNotificationService(this._api);

  Future<void> initializeForAuthenticatedUser({required String userId}) async {
    if (_initialized) return;
    _initialized = true;

    try {
      // iOS needs explicit permission; Android 13+ also benefits from this.
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[push] permission request failed: $e');
    }

    try {
      final token = await _messaging.getToken();
      await _api.updateNotificationDeviceToken(token);
    } catch (e) {
      debugPrint('[push] token registration failed: $e');
    }

    // Keep server token fresh.
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      try {
        await _api.updateNotificationDeviceToken(token);
      } catch (e) {
        debugPrint('[push] token refresh update failed: $e');
      }
    });

    // Foreground push handling is app-specific (you may want a local notification).
    // We leave it to UI layers for now, but we at least keep the stream hot.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[push] foreground message: ${message.messageId}');
    });
  }

  Future<void> clearDeviceTokenOnServer() async {
    try {
      await _api.updateNotificationDeviceToken(null);
    } catch (e) {
      debugPrint('[push] clear device token failed: $e');
    }
  }

  Future<void> teardown() async {
    _initialized = false;
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }
}

