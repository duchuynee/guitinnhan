import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/auth/app_login_screen.dart';

void main() {
  testWidgets('login screen renders core fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    expect(find.text('Mini Social'), findsOneWidget);
    expect(find.text('Dang nhap'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
