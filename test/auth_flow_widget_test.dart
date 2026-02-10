import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hachinana_shogi/main.dart';
import 'package:hachinana_shogi/services/app_navigation_state.dart';
import 'package:hachinana_shogi/services/auth_service.dart';
import 'package:hachinana_shogi/services/instructor_service.dart';
import 'package:hachinana_shogi/services/payment_service.dart';
import 'package:hachinana_shogi/services/reservation_service.dart';

void main() {
  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AppNavigationState()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
        ChangeNotifierProvider(create: (_) => ReservationService()),
        ChangeNotifierProvider(create: (_) => InstructorService()),
      ],
      child: const MyApp(),
    );
  }

  testWidgets('結合(正常系): ゲストとして開始でホームに遷移する', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.text('ゲストとして開始'), findsOneWidget);
    await tester.tap(find.text('ゲストとして開始'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsWidgets);
    expect(find.text('マイページ'), findsWidgets);
    expect(find.text('ゲストとして開始'), findsNothing);
  });

  testWidgets('結合(異常系): 未入力でログインするとバリデーションエラー', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());

    final loginButton = find.widgetWithText(ElevatedButton, 'ログイン');
    expect(loginButton, findsOneWidget);

    await tester.tap(loginButton);
    await tester.pump();

    expect(find.text('メールアドレスを入力してください'), findsOneWidget);
    expect(find.text('パスワードを入力してください'), findsOneWidget);
  });
}
