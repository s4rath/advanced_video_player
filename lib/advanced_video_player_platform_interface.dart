import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'advanced_video_player_method_channel.dart';

abstract class AdvancedVideoPlayerPlatform extends PlatformInterface {
  /// Constructs a AdvancedVideoPlayerPlatform.
  AdvancedVideoPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static AdvancedVideoPlayerPlatform _instance = MethodChannelAdvancedVideoPlayer();

  /// The default instance of [AdvancedVideoPlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelAdvancedVideoPlayer].
  static AdvancedVideoPlayerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AdvancedVideoPlayerPlatform] when
  /// they register themselves.
  static set instance(AdvancedVideoPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
