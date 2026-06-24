/// Configures playback buffering and behavior before the player starts.
///
/// Pass to [AdvancedVideoPlayerWidget] via [AdvancedVideoPlayerWidget.settings].
class PlayerSettings {
  /// Maximum buffer duration in milliseconds. Default is 50 000 ms (50 s).
  final int maxBufferMs;

  /// Minimum buffer needed before playback starts/resumes (ms).
  final int minBufferMs;

  /// Buffer the player tries to maintain during playback (ms).
  final int bufferForPlaybackMs;

  /// Buffer threshold after rebuffering (ms).
  final int bufferForPlaybackAfterRebufferMs;

  const PlayerSettings({
    this.maxBufferMs = 50000,
    this.minBufferMs = 15000,
    this.bufferForPlaybackMs = 2500,
    this.bufferForPlaybackAfterRebufferMs = 5000,
  });

  Map<String, dynamic> toMap() => {
        'maxBufferMs': maxBufferMs,
        'minBufferMs': minBufferMs,
        'bufferForPlaybackMs': bufferForPlaybackMs,
        'bufferForPlaybackAfterRebufferMs': bufferForPlaybackAfterRebufferMs,
      };
}
