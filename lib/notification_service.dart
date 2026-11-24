import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'notification_detail_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// State token FCM yang dipakai oleh UI.
class FcmTokenState {
  const FcmTokenState({this.token, this.error});

  final String? token;
  final String? error;

  bool get isLoading => token == null && error == null;
}

// Masukkan Public VAPID Key yang sama dengan fcm_token_card.dart.
const String webVapidKey =
    'BDJ9ebEcPM9oNYfqsCK7Jiqtw1ejRn4xl1A7v7Q_PMfxr6-Me4PpdDgNxEbgMa-fjnyxVKaCEZj7Vh8FbsRtSpM';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('[FCM] Background: ${message.messageId}');
  debugPrint('[FCM] Data: ${message.data}');
}

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifikasi Penting',
    description: 'Channel notifikasi Firebase',
    importance: Importance.max,
  );

  /// Dipantau oleh FcmTokenCard supaya token muncul begitu tersedia.
  static final ValueNotifier<FcmTokenState> tokenState =
      ValueNotifier<FcmTokenState>(const FcmTokenState());

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tokenState.value = const FcmTokenState();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // Inisialisasi khusus Android.
    if (!kIsWeb) {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

      await _localNotif.initialize(
        settings: const InitializationSettings(android: androidInit),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            _openDetail(jsonDecode(response.payload!) as Map<String, dynamic>);
          }
        },
      );

      await _localNotif
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }

    // Dengarkan token lebih dulu, lalu minta registrasi.
    // onRegistered juga dipanggil saat token di-refresh.
    _messaging.onRegistered.listen(
      (newToken) {
        debugPrint('[FCM] TOKEN: $newToken');
        tokenState.value = FcmTokenState(token: newToken);
      },
      onError: (Object error) {
        debugPrint('[FCM] Gagal mendengar token: $error');
        tokenState.value = FcmTokenState(error: error.toString());
      },
    );

    _messaging.onUnregistered.listen((fid) {
      if (tokenState.value.token == fid) {
        tokenState.value = const FcmTokenState();
      }
    });

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      tokenState.value = const FcmTokenState(
        error:
            'Izin notifikasi ditolak. Aktifkan izin notifikasi untuk melihat token.',
      );
    }

    try {
      await _messaging.register(vapidKey: kIsWeb ? webVapidKey : null);
    } catch (e) {
      debugPrint('[FCM] Gagal mengambil token: $e');
      tokenState.value = FcmTokenState(
        error: tokenState.value.error ?? 'Gagal mengambil FCM token: $e',
      );
    }

    // Subscribe topic hanya untuk Android.
    if (!kIsWeb) {
      await _messaging.subscribeToTopic('kelas');
    }

    // Pesan ketika aplikasi sedang terbuka.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground: ${message.data}');

      if (!kIsWeb) {
        _showForegroundNotification(message);
      }
    });

    // Penanganan ketika notifikasi dibuka dari background.
    if (!kIsWeb) {
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _openDetail(_messageToMap(message));
      });

      final initialMessage = await _messaging.getInitialMessage();

      if (initialMessage != null) {
        _openDetail(_messageToMap(initialMessage));
      }

      final launchDetails = await _localNotif.getNotificationAppLaunchDetails();

      final payload = launchDetails?.notificationResponse?.payload;

      if ((launchDetails?.didNotificationLaunchApp ?? false) &&
          payload != null) {
        _openDetail(jsonDecode(payload) as Map<String, dynamic>);
      }
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    await _localNotif.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(_messageToMap(message)),
    );
  }

  static Map<String, dynamic> _messageToMap(RemoteMessage message) {
    return {
      'title': message.notification?.title ?? '-',
      'body': message.notification?.body ?? '-',
      ...message.data,
    };
  }

  static void _openDetail(Map<String, dynamic> data) {
    void push() {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => NotificationDetailScreen(data: data)),
      );
    }

    if (navigatorKey.currentState != null) {
      push();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => push());
    }
  }
}
