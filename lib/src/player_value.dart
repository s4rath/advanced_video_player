import 'player_types.dart';

/// Immutable snapshot of all player state.
/// The controller exposes a [ValueNotifier<PlayerValue>] so widgets can
/// rebuild efficiently on specific state changes.
class PlayerValue {
  final bool isInitialized;
  final bool isLoading;
  final bool isPlaying;
  final bool isBuffering;
  final bool isEnded;
  final bool isAdaptive;
  final bool isFullscreen;
  final bool isInPiPMode;
  final PlayerState playerState;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final double playbackSpeed;
  final ResizeMode resizeMode;
  final VideoTrack? selectedVideoTrack;
  final AudioTrack? selectedAudioTrack;
  final SubtitleTrack? selectedSubtitleTrack;
  final List<VideoTrack> videoTracks;
  final List<AudioTrack> audioTracks;
  final List<SubtitleTrack> subtitleTracks;
  final PlayerError? error;
  final int totalPlayedSeconds;
  final int totalCoveredSeconds;

  const PlayerValue({
    this.isInitialized = false,
    this.isLoading = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isEnded = false,
    this.isAdaptive = true,
    this.isFullscreen = false,
    this.isInPiPMode = false,
    this.playerState = PlayerState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.playbackSpeed = 1.0,
    this.resizeMode = ResizeMode.fit,
    this.selectedVideoTrack,
    this.selectedAudioTrack,
    this.selectedSubtitleTrack,
    this.videoTracks = const [],
    this.audioTracks = const [],
    this.subtitleTracks = const [],
    this.error,
    this.totalPlayedSeconds = 0,
    this.totalCoveredSeconds = 0,
  });

  static const PlayerValue uninitialized = PlayerValue();

  PlayerValue copyWith({
    bool? isInitialized,
    bool? isLoading,
    bool? isPlaying,
    bool? isBuffering,
    bool? isEnded,
    bool? isAdaptive,
    bool? isFullscreen,
    bool? isInPiPMode,
    PlayerState? playerState,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? playbackSpeed,
    ResizeMode? resizeMode,
    VideoTrack? selectedVideoTrack,
    AudioTrack? selectedAudioTrack,
    SubtitleTrack? selectedSubtitleTrack,
    List<VideoTrack>? videoTracks,
    List<AudioTrack>? audioTracks,
    List<SubtitleTrack>? subtitleTracks,
    PlayerError? error,
    bool clearError = false,
    bool clearSelectedVideoTrack = false,
    bool clearSelectedSubtitle = false,
    int? totalPlayedSeconds,
    int? totalCoveredSeconds,
  }) {
    return PlayerValue(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isEnded: isEnded ?? this.isEnded,
      isAdaptive: isAdaptive ?? this.isAdaptive,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isInPiPMode: isInPiPMode ?? this.isInPiPMode,
      playerState: playerState ?? this.playerState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      resizeMode: resizeMode ?? this.resizeMode,
      selectedVideoTrack:
          clearSelectedVideoTrack ? null : selectedVideoTrack ?? this.selectedVideoTrack,
      selectedAudioTrack: selectedAudioTrack ?? this.selectedAudioTrack,
      selectedSubtitleTrack:
          clearSelectedSubtitle ? null : selectedSubtitleTrack ?? this.selectedSubtitleTrack,
      videoTracks: videoTracks ?? this.videoTracks,
      audioTracks: audioTracks ?? this.audioTracks,
      subtitleTracks: subtitleTracks ?? this.subtitleTracks,
      error: clearError ? null : error ?? this.error,
      totalPlayedSeconds: totalPlayedSeconds ?? this.totalPlayedSeconds,
      totalCoveredSeconds: totalCoveredSeconds ?? this.totalCoveredSeconds,
    );
  }
}
