import 'package:flutter_test/flutter_test.dart';
import 'package:wordsnap/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('见词 WordSnap'), findsOneWidget);
  });
}
