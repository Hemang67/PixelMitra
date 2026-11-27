import 'package:flutter_test/flutter_test.dart';
import 'package:pixelmitra/main.dart';

void main() {
  testWidgets('home screen shows PixelMitra branding and feature entries',
      (tester) async {
    await tester.pumpWidget(const PixelMitraApp());

    expect(find.text('Your Creative Friend'), findsOneWidget);
    expect(find.text('Photo Editor'), findsOneWidget);
    expect(find.text('AI Studio'), findsOneWidget);
    expect(find.text('Video Studio'), findsOneWidget);
  });

  testWidgets('AI Studio opens from the home screen', (tester) async {
    await tester.pumpWidget(const PixelMitraApp());

    await tester.tap(find.text('AI Studio'));
    await tester.pumpAndSettle();

    expect(find.text('Create with your own AI'), findsOneWidget);
    expect(find.text('Generate text'), findsOneWidget);
    expect(find.text('Generate image'), findsOneWidget);
  });

  testWidgets('Video Studio opens and presents local video selection',
      (tester) async {
    await tester.pumpWidget(const PixelMitraApp());

    await tester.tap(find.text('Video Studio'));
    await tester.pumpAndSettle();

    expect(find.text('Trim your video'), findsOneWidget);
    expect(find.text('Choose video'), findsOneWidget);
    expect(find.text('Export trimmed video'), findsNothing);
  });

  testWidgets('update screen opens and offers a release check',
      (tester) async {
    await tester.pumpWidget(const PixelMitraApp());

    await tester.tap(find.byTooltip('Check updates'));
    await tester.pumpAndSettle();

    expect(find.text('App updates'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
  });
}
