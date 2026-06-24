import 'player_types.dart';
import 'video_source.dart';

/// Listener interface for playback lifecycle events — mirrors VdoCipher's
/// `PlaybackEventListener` but adapted for URL-based sources.
mixin class PlaybackEventListener {
  void onLoading(VideoSource source) {}
  void onLoaded(VideoSource source) {}
  void onLoadError(VideoSource source, PlayerError error) {}
  void onMediaEnded(VideoSource source) {}
  void onError(VideoSource source, PlayerError error) {}
  void onProgress(int positionMs) {}
  void onBufferUpdate(int bufferedMs) {}
  void onPlaybackSpeedChanged(double speed) {}
  void onTracksChanged(
    List<VideoTrack> videoTracks,
    List<AudioTrack> audioTracks,
    List<SubtitleTrack> subtitleTracks,
  ) {}
  void onFullscreenChanged(bool isFullscreen) {}
  void onPiPModeChanged(bool isInPiPMode) {}
}
