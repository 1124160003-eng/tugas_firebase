import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'notification_service.dart';

class FcmTokenCard extends StatelessWidget {
  const FcmTokenCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FcmTokenState>(
      valueListenable: NotificationService.tokenState,
      builder: (context, state, _) {
        if (state.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final token = state.token;
        if (token == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                state.error ?? 'FCM Token tidak tersedia.',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FCM Device Token',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SelectableText(token),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: token));

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('FCM Token berhasil disalin'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Salin Token'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
