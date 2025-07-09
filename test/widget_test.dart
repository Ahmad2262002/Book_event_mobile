import 'package:book_event/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Mock SharedPreferences for testing
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'isDarkMode': false});

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app with the required isDarkMode parameter
    await tester.pumpWidget(const MyApp(isDarkMode: false));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  // Add more theme-specific tests if needed
  testWidgets('App uses light theme when isDarkMode is false', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isDarkMode: false));

    // Verify light theme is used
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, isNot(Colors.grey[900]));
  });

  testWidgets('App uses dark theme when isDarkMode is true', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isDarkMode: true));

    // Verify dark theme is used
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, isNot(Colors.white));
  });
}