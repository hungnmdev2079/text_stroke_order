import 'package:flutter_test/flutter_test.dart';
import 'package:text_stroke_order/text_stroke_order.dart';
import 'package:text_stroke_order/text_stroke_order_platform_interface.dart';
import 'package:text_stroke_order/text_stroke_order_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockTextStrokeOrderPlatform
    with MockPlatformInterfaceMixin
    implements TextStrokeOrderPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final TextStrokeOrderPlatform initialPlatform =
      TextStrokeOrderPlatform.instance;

  test('$MethodChannelTextStrokeOrder is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTextStrokeOrder>());
  });

  test('getPlatformVersion', () async {
    MockTextStrokeOrderPlatform fakePlatform = MockTextStrokeOrderPlatform();
    TextStrokeOrderPlatform.instance = fakePlatform;
  });
}
