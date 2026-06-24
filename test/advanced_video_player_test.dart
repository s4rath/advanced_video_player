import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_video_player/advanced_video_player.dart';
import 'package:advanced_video_player/advanced_video_player_platform_interface.dart';
import 'package:advanced_video_player/advanced_video_player_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAdvancedVideoPlayerPlatform
    with MockPlatformInterfaceMixin
    implements AdvancedVideoPlayerPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AdvancedVideoPlayerPlatform initialPlatform = AdvancedVideoPlayerPlatform.instance;

  test('$MethodChannelAdvancedVideoPlayer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAdvancedVideoPlayer>());
  });

  test('getPlatformVersion', () async {
    AdvancedVideoPlayer advancedVideoPlayerPlugin = AdvancedVideoPlayer();
    MockAdvancedVideoPlayerPlatform fakePlatform = MockAdvancedVideoPlayerPlatform();
    AdvancedVideoPlayerPlatform.instance = fakePlatform;

    expect(await advancedVideoPlayerPlugin.getPlatformVersion(), '42');
  });
}
