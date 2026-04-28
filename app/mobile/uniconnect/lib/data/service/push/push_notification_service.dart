import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/service/api/api_client.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.watch(apiClientProvider));
});

class PushNotificationService {
  final ApiClient _apiClient;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  PushNotificationService(this._apiClient);

  Future<void> initializeForAuthenticatedUser({required String userId}) async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _updateTokenOnServer(token);
      }
    }

    _fcm.onTokenRefresh.listen((token) async {
      await _updateTokenOnServer(token);
    });
  }

  Future<void> _updateTokenOnServer(String token) async {
    try {
      await _apiClient.updatePushToken(token);
    } catch (e) {
      // Log error or handle it
    }
  }

  Future<void> clearDeviceTokenOnServer() async {
    try {
      await _apiClient.removePushToken();
    } catch (e) {
      // Log error or handle it
    }
  }

  Future<void> teardown() async {
    await _fcm.deleteToken();
  }
}
