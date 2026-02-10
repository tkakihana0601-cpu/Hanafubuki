// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hachinana_shogi/main.dart';
import 'package:hachinana_shogi/services/app_navigation_state.dart';
import 'package:hachinana_shogi/services/auth_service.dart';
import 'package:hachinana_shogi/services/payment_service.dart';
import 'package:hachinana_shogi/services/reservation_service.dart';
import 'package:hachinana_shogi/services/instructor_service.dart';

void main() {
  testWidgets('App builds with providers', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => AppNavigationState()),
          ChangeNotifierProvider(create: (_) => PaymentService()),
          ChangeNotifierProvider(create: (_) => ReservationService()),
          ChangeNotifierProvider(create: (_) => InstructorService()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text('87（はちなな）将棋'), findsOneWidget);
  });
}
