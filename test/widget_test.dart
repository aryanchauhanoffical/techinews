import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:techinews/app/app.dart';

void main() {
  testWidgets('App boots without crashing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TechiNewsApp()));
    await tester.pump();
    expect(find.byType(TechiNewsApp), findsOneWidget);
  });
}
