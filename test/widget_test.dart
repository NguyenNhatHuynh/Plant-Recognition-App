// lib/test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_recognition_app/theme/app_theme.dart';
import 'package:plant_recognition_app/ui/screens/library_screen.dart';
import 'package:provider/provider.dart';
import 'package:plant_recognition_app/main.dart';
import 'package:plant_recognition_app/services/database_service.dart';
import 'package:plant_recognition_app/ui/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen loads with bottom navigation bar',
      (WidgetTester tester) async {
    // Create a mock DatabaseService
    final databaseService = DatabaseService();

    // Build the app with Provider and trigger a frame
    await tester.pumpWidget(
      Provider<DatabaseService>(
        create: (_) => databaseService,
        child: MaterialApp(
          theme: appTheme(),
          home: HomeScreen(),
        ),
      ),
    );

    // Wait for any asynchronous operations (e.g., database initialization)
    await tester.pumpAndSettle();

    // Verify that the HomeScreen loads
    expect(find.byType(HomeScreen), findsOneWidget);

    // Verify that the bottom navigation bar is present
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify that specific tabs are present (e.g., "Scan", "Library")
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);

    // Simulate tapping the "Library" tab
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    // Verify that the LibraryScreen is displayed
    expect(find.byType(LibraryScreen), findsOneWidget);
  });
}
