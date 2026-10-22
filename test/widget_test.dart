import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:farmer_market/app.dart';
import 'package:farmer_market/providers/auth_provider.dart';
import 'package:farmer_market/providers/app_state_provider.dart';

void main() {
  testWidgets('app starts on the splash screen', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const FarmerMarketApp(),
      ),
    );
    expect(find.text('Farmer Market'), findsOneWidget);
    // Let the splash timer finish so no timers are pending.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
