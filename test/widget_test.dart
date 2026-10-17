import 'package:flutter_test/flutter_test.dart';
import 'package:kaamfast/app.dart';

void main() {
  testWidgets('Kaam Fast app boots to splash', (tester) async {
    await tester.pumpWidget(const KaamFastApp());
    expect(find.text('Kaam Fast'), findsWidgets);
  });
}
