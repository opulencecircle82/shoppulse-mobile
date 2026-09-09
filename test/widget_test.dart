// Basic smoke test: the app boots and shows the splash screen. Without
// --dart-define SUPABASE_URL/SUPABASE_ANON_KEY (not set in the test
// environment), the splash screen deterministically shows the "not
// configured" message instead of trying to reach Supabase.

import 'package:flutter_test/flutter_test.dart';

import 'package:shoppulse_mobile/main.dart';

void main() {
  testWidgets('App boots to splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ShopPulseApp());

    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
  });
}
