import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/main.dart';

void main() {
  testWidgets('App mounts Today screen content', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TransformFitApp(),
      ),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.textContaining('Coach note:'), findsOneWidget);
  });
}
