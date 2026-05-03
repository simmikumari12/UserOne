import 'package:firebase_messaging/firebase_messaging.dart';

/// Service class for Firebase Cloud Messaging integration.
class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Requests notification permission and returns whether permission was granted.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Returns the current FCM device token.
  Future<String?> getDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribes to the specified FCM topic.
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  /// Listens for foreground messages.
  void configureForegroundMessageHandling({
    required void Function(RemoteMessage message) onMessage,
  }) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }
}
