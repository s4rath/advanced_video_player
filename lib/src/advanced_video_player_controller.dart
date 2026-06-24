import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'player_types.dart';
import 'player_value.dart';
import 'video_source.dart';
import 'watermark_config.dart';

/// Controls a single [AdvancedVideoPlayerWidget].
///
/// Obtain an instance from the [AdvancedVideoPlayerWidget.onPlayerCreated]
/// callback. All methods are async and resolve once the native call completes.
///
/// Observe state changes with [value]:
/// ```dart
/// controller.addListener(() {
///   final v = controller.value;
///   print(v.position);
/// });
/// ```
class AdvancedVideoPlayerController extends ChangeNotifier {
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  Stream<Map<String, dynamic>>? _eventStream;

  PlayerValue _value = PlayerValue.uninitialized;

  AdvancedVideoPlayerController._(this._methodChannel, this._eventChannel);

  factory AdvancedVideoPlayerController.withChannels(
    MethodChannel method,
    EventChannel event,
  ) =>
      AdvancedVideoPlayerController._(method, event);

  /// Current immutable snapshot of all player state.
  PlayerValue get value => _value;

  // ── Internal event wiring ──────────────────────────────────────────────────

  /// Broadcast stream of raw native events. Prefer using [value] + listeners
  /// for state updates; use this only for one-off custom event handling.
  Stream<Map<String, dynamic>> get events {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((e) => Map<String, dynamic>.from(e as Map));
    return _eventStream!;
  }

  void handleEvent(String event, Map<String, dynamic> data) {
    switch (event) {
      case 'playerStateChanged':
        final state = playerStateFromString(data['state'] as String? ?? '');
        _value = _value.copyWith(
          playerState: state,
          isPlaying: data['isPlaying'] as bool? ?? _value.isPlaying,
          isBuffering: state == PlayerState.buffering,
          isEnded: state == PlayerState.ended,
          isLoading: state == PlayerState.buffering,
        );
        notifyListeners();
        break;

      case 'playingChanged':
        _value = _value.copyWith(
          isPlaying: data['isPlaying'] as bool? ?? _value.isPlaying,
        );
        notifyListeners();
        break;

      case 'durationChanged':
        _value = _value.copyWith(
          duration: Duration(milliseconds: (data['duration'] as int?) ?? 0),
          isInitialized: true,
        );
        notifyListeners();
        break;

      case 'progress':
        _value = _value.copyWith(
          position: Duration(milliseconds: (data['position'] as int?) ?? 0),
          duration: Duration(milliseconds: (data['duration'] as int?) ?? 0),
          bufferedPosition:
              Duration(milliseconds: (data['buffered'] as int?) ?? 0),
          totalPlayedSeconds: (data['totalPlayedSeconds'] as int?) ??
              _value.totalPlayedSeconds,
          totalCoveredSeconds: (data['totalCoveredSeconds'] as int?) ??
              _value.totalCoveredSeconds,
        );
        notifyListeners();
        break;

      case 'playbackSpeedChanged':
        _value = _value.copyWith(
            playbackSpeed: (data['speed'] as num?)?.toDouble() ?? 1.0);
        notifyListeners();
        break;

      case 'tracksChanged':
        final rawVideo =
            (data['videoTracks'] as List?)?.cast<Map<Object?, Object?>>() ?? [];
        final rawAudio =
            (data['audioTracks'] as List?)?.cast<Map<Object?, Object?>>() ?? [];
        final rawSub =
            (data['subtitleTracks'] as List?)?.cast<Map<Object?, Object?>>() ??
                [];

        _value = _value.copyWith(
          videoTracks: rawVideo.map(VideoTrack.fromMap).toList(),
          audioTracks: rawAudio.map(AudioTrack.fromMap).toList(),
          subtitleTracks: rawSub.map(SubtitleTrack.fromMap).toList(),
        );
        notifyListeners();
        break;

      case 'error':
        _value = _value.copyWith(
          error: PlayerError(
            code: (data['code'] as int?) ?? -1,
            message: data['message'] as String? ?? 'Unknown error',
          ),
        );
        notifyListeners();
        break;
    }
  }

  void handleMethodCall(String method, dynamic arguments) {
    switch (method) {
      case 'onFullscreenChanged':
        _value = _value.copyWith(
            isFullscreen: arguments as bool? ?? _value.isFullscreen);
        notifyListeners();
        break;
      case 'onPiPModeChanged':
        _value = _value.copyWith(
            isInPiPMode: arguments as bool? ?? _value.isInPiPMode);
        notifyListeners();
        break;
    }
  }

  // ── Playback control ───────────────────────────────────────────────────────

  Future<void> play() => _methodChannel.invokeMethod('play');

  Future<void> pause() => _methodChannel.invokeMethod('pause');

  Future<void> stop() => _methodChannel.invokeMethod('stop');

  Future<void> seekTo(Duration position) =>
      _methodChannel.invokeMethod('seekTo', position.inMilliseconds);

  /// Load a new [VideoSource] without recreating the native view.
  Future<void> load(VideoSource source) =>
      _methodChannel.invokeMethod('loadSource', source.toMap());

  /// Convenience method — loads a raw URL with optional headers.
  Future<void> loadUrl(String url, {Map<String, String>? headers}) =>
      _methodChannel.invokeMethod('loadUrl', {
        'url': url,
        if (headers != null) 'headers': headers,
      });

  // ── Audio / video controls ─────────────────────────────────────────────────

  /// Volume between 0.0 and 1.0.
  Future<void> setVolume(double volume) =>
      _methodChannel.invokeMethod('setVolume', volume);

  Future<void> setPlaybackSpeed(double speed) =>
      _methodChannel.invokeMethod('setPlaybackSpeed', speed);

  // ── Track selection ────────────────────────────────────────────────────────

  /// Switch back to adaptive bitrate (clears any manual track selection).
  Future<void> setAdaptive() {
    _value = _value.copyWith(
        isAdaptive: true, clearSelectedVideoTrack: true);
    notifyListeners();
    return _methodChannel.invokeMethod('setAdaptive');
  }

  Future<void> setVideoTrack(VideoTrack track) {
    _value = _value.copyWith(
        selectedVideoTrack: track, isAdaptive: false);
    notifyListeners();
    return _methodChannel.invokeMethod('setVideoTrack', track.id);
  }

  Future<void> setAudioTrack(AudioTrack track) {
    _value = _value.copyWith(selectedAudioTrack: track);
    notifyListeners();
    return _methodChannel.invokeMethod('setAudioTrack', track.id);
  }

  /// Pass null to disable subtitles.
  Future<void> setSubtitleTrack(SubtitleTrack? track) {
    _value = _value.copyWith(
        selectedSubtitleTrack: track,
        clearSelectedSubtitle: track == null);
    notifyListeners();
    final int? trackId = track?.id;
    return _methodChannel.invokeMethod('setSubtitleTrack', trackId);
  }

  // ── Resize / display ──────────────────────────────────────────────────────

  Future<void> setResizeMode(ResizeMode mode) {
    _value = _value.copyWith(resizeMode: mode);
    notifyListeners();
    return _methodChannel.invokeMethod(
        'setResizeMode', _resizeModeToString(mode));
  }

  // ── Fullscreen & PiP ──────────────────────────────────────────────────────

  Future<void> enterFullScreen() =>
      _methodChannel.invokeMethod('enterFullScreen');

  Future<void> exitFullScreen() =>
      _methodChannel.invokeMethod('exitFullScreen');

  /// Enter Android Picture-in-Picture mode.
  Future<void> enterPiP() => _methodChannel.invokeMethod('enterPiP');

  // ── Watermark ─────────────────────────────────────────────────────────────

  /// Update or remove the watermark at runtime.
  Future<void> updateWatermark(WatermarkConfig? config) =>
      _methodChannel.invokeMethod('updateWatermark', config?.toMap());

  // ── Query ─────────────────────────────────────────────────────────────────

  Future<Duration> getPosition() async {
    final ms = await _methodChannel.invokeMethod<int>('getPosition') ?? 0;
    return Duration(milliseconds: ms);
  }

  Future<Duration> getDuration() async {
    final ms = await _methodChannel.invokeMethod<int>('getDuration') ?? 0;
    return Duration(milliseconds: ms);
  }

  Future<bool> isPlaying() async =>
      await _methodChannel.invokeMethod<bool>('isPlaying') ?? false;

  /// Retrieve a custom playback property from the native player.
  ///
  /// Supported keys:
  /// - `"totalPlayed"` – total seconds the video has been actively playing
  /// - `"totalCovered"` – total unique seconds seeked/watched
  Future<Object?> getPlaybackProperty(String propertyName) =>
      _methodChannel.invokeMethod('getPlaybackProperty', propertyName);

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _resizeModeToString(ResizeMode m) {
    switch (m) {
      case ResizeMode.fit:         return 'fit';
      case ResizeMode.fill:        return 'fill';
      case ResizeMode.zoom:        return 'zoom';
      case ResizeMode.fixedWidth:  return 'fixedWidth';
      case ResizeMode.fixedHeight: return 'fixedHeight';
    }
  }
}
