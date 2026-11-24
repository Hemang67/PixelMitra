import 'package:flutter_test/flutter_test.dart';
import 'package:pixelmitra/main.dart';

void main() {
  testWidgets('shows PixelMitra home screen', (tester) async {
    await tester.pumpWidget(const PixelMitraApp());
    expect(find.text('Your Creative Friend'), findsOneWidget);
    expect(find.text('Photo Editor'), findsOneWidget);
  });
}
