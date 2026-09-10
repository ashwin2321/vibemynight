import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibemynight/core/widgets/loading_view.dart';

void main() {
  testWidgets('ShimmerArtistSlider smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShimmerArtistSlider(count: 3),
        ),
      ),
    );
    expect(find.byType(ShimmerArtistSlider), findsOneWidget);
    expect(find.byType(ShimmerBox), findsWidgets);
  });
}
