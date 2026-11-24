import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tryfirebase/notification_detail_screen.dart';

void main() {
  testWidgets('NotificationDetailScreen menampilkan judul, isi, dan data payload',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationDetailScreen(
          data: {
            'title': 'Halo',
            'body': 'Tes notifikasi',
            'route': 'kelas',
          },
        ),
      ),
    );

    expect(find.text('Detail Notifikasi'), findsOneWidget);
    expect(find.text('Halo'), findsOneWidget);
    expect(find.text('Tes notifikasi'), findsOneWidget);
    expect(find.text('route'), findsOneWidget);
    expect(find.text('kelas'), findsOneWidget);
  });
}
