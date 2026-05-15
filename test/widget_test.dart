import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:plant_recognition_app/services/database_service.dart';
import 'package:plant_recognition_app/services/recognition_service.dart';
import 'package:plant_recognition_app/state/app_state.dart';
import 'package:plant_recognition_app/theme/app_theme.dart';
import 'package:plant_recognition_app/ui/screens/home_screen.dart';
import 'package:plant_recognition_app/ui/screens/library_screen.dart';

void main() {
  testWidgets('HomeScreen loads with bottom navigation bar',
      (WidgetTester tester) async {
    final databaseService = DatabaseService();
    final recognitionService = RecognitionService(apiKey: '');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DatabaseService>.value(value: databaseService),
          Provider<RecognitionService>.value(value: recognitionService),
          ChangeNotifierProvider(create: (_) => AppState()),
        ],
        child: MaterialApp(
          theme: appTheme(),
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Thư viện'), findsOneWidget);
    expect(find.text('Lịch sử'), findsOneWidget);
    expect(find.text('Yêu thích'), findsOneWidget);

    await tester.tap(find.text('Thư viện'));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryScreen), findsOneWidget);
  });
}
