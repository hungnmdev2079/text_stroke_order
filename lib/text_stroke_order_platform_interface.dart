import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'text_stroke_order_method_channel.dart';

abstract class TextStrokeOrderPlatform extends PlatformInterface {
  /// Constructs a TextStrokeOrderPlatform.
  TextStrokeOrderPlatform() : super(token: _token);

  static final Object _token = Object();

  static TextStrokeOrderPlatform _instance = MethodChannelTextStrokeOrder();

  /// The default instance of [TextStrokeOrderPlatform] to use.
  ///
  /// Defaults to [MethodChannelTextStrokeOrder].
  static TextStrokeOrderPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TextStrokeOrderPlatform] when
  /// they register themselves.
  static set instance(TextStrokeOrderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
