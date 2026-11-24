import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/user_info_screen.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Daftarkan handler untuk pesan saat aplikasi di background / mati.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e, stackTrace) {
    initError = e.toString();
    debugPrint('[Firebase] Gagal inisialisasi: $e');
    debugPrint(stackTrace.toString());
  }

  // PENTING: runApp dipanggil segera setelah Firebase siap.
  // Jangan menunggu NotificationService.init() di sini: FCM bisa lama
  // atau menggantung (misalnya tanpa Google Play Services), yang bikin
  // layar putih sebelum widget apa pun sempat dirender.
  runApp(MyApp(initError: initError));

  if (initError == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.init());
    });
  }
}

class MyApp extends StatelessWidget {
  final String? initError;

  const MyApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Simple',
      navigatorKey: navigatorKey,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: initError != null
          ? FirebaseErrorScreen(message: initError!)
          : const AuthWrapper(),
    );
  }
}

/// Munculkan pesan error yang jelas daripada layar putih kalau Firebase gagal.
class FirebaseErrorScreen extends StatelessWidget {
  final String message;

  const FirebaseErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Error')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Gagal menginisialisasi Firebase.\n'
              'Cek koneksi internet, google-services.json, dan firebase_options.dart.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  message,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return UserInfoScreen(user: snapshot.data!);
        }
        return const LoginScreen();
      },
    );
  }
}
