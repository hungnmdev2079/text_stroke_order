import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_stroke_order/text_stroke_order.dart';

void main() {
  testWidgets('sequential stroke advances on a 100x100 canvas', (tester) async {
    final controller = TextStrokeOrderController(
      svgProvider: SvgProvider.string(
        '<svg><path id="test-s1" '
        'style="stroke:#000000;stroke-width:1;" '
        'd="M0,50 L100,50"/></svg>',
      ),
      vsync: TestVSync(),
      duration: const Duration(milliseconds: 1),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: TextStrokeOrder.sequentialStroke(
            controller: controller,
            isFreeDraw: false,
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(20),
            isShowNumber: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final offsets = controller.currentOffset!;
    final handlePosition = controller.handlePosition!;
    final panStartIndex = offsets.indexWhere(
      (offset) => (offset - offsets.first).distance > 18,
    );
    final targetIndex = offsets.indexWhere(
      (offset) => (offset - offsets.first).distance > 24,
    );

    expect(panStartIndex, greaterThan(20));
    expect(targetIndex, greaterThan(20));

    final widgetTopLeft = tester.getTopLeft(find.byType(TextStrokeOrder));
    const paddingOffset = Offset(20, 20);
    final gesture = await tester.startGesture(
      widgetTopLeft + paddingOffset + handlePosition,
    );
    await gesture.moveTo(
      widgetTopLeft + paddingOffset + offsets[panStartIndex],
    );
    await tester.pump();
    await gesture.moveTo(
      widgetTopLeft + paddingOffset + offsets[targetIndex],
    );
    await tester.pump();

    expect(
      controller.listPathSegments.first.currentIndexOffset,
      greaterThan(20),
    );

    await gesture.up();
  });

  group('findNearestIndexOffset', () {
    late TextStrokeOrderController controller;

    setUp(() {
      controller = TextStrokeOrderController(
        svgProvider: SvgProvider.string(
          '<svg><path id="test-s1" '
          'style="stroke:#000000;stroke-width:1;" '
          'd="M0,0 L10,0"/></svg>',
        ),
        vsync: TestVSync(),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('allows more samples when a scaled path only moves a few pixels', () {
      final offsets = List.generate(
        100,
        (index) => Offset(index * 0.5, 0),
      );

      expect(
        controller.findNearestIndexOffset(0, const Offset(12, 0), offsets),
        24,
      );
    });

    test('keeps the large-jump guard for normal rendered distances', () {
      final offsets = List.generate(
        100,
        (index) => Offset(index * 2, 0),
      );

      expect(
        controller.findNearestIndexOffset(0, const Offset(50, 0), offsets),
        0,
      );
    });
  });
}
