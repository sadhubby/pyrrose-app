import 'package:flutter_test/flutter_test.dart';

import 'package:pyrrose/main.dart';

void main() {
  testWidgets('home screen shows both actions and opens the builder', (
    tester,
  ) async {
    await tester.pumpWidget(const PyrroseApp());

    expect(find.text('Pyrrose'), findsOneWidget);
    expect(find.text('New bouquet'), findsOneWidget);
    expect(find.text('Browse flowers'), findsOneWidget);

    await tester.tap(find.text('New bouquet'));
    await tester.pumpAndSettle();

    expect(find.text('New bouquet'), findsWidgets);
    expect(find.text('Bouquet canvas arrives in Phase 3'), findsOneWidget);
  });
}
