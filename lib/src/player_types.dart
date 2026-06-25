// ─── Track types ─────────────────────────────────────────────────────────────

/// A selectable video quality track.
class VideoTrack {
  /// Opaque identifier sent to [AdvancedVideoPlayerController.setVideoTrack].
  final int id;
  final int? bitrate;
  final int? width;
  final int? height;

  const VideoTrack({
    required this.id,
    this.bitrate,
    this.width,
    this.height,
  });

  /// Human-readable label, e.g. "720p" or "1500 kbps".
  String get label {
    if (height != null) return '${height}p';
    if (bitrate != null) return '$bitrate kbps';
    return 'Track $id'; // ignore: unnecessary_string_interpolation
  }

  factory VideoTrack.fromMap(Map<Object?, Object?> map) => VideoTrack(
        id: (map['id'] as num).toInt(),
        bitrate: (map['bitrate'] as num?)?.toInt(),
        width: (map['width'] as num?)?.toInt(),
        height: (map['height'] as num?)?.toInt(),
      );

  @override
  String toString() => 'VideoTrack($label, id=$id)';
}

/// A selectable audio track.
class AudioTrack {
  final int id;
  final String? language;
  final int? bitrate;
  final String? label;

  const AudioTrack({required this.id, this.language, this.bitrate, this.label});

  String get displayLabel =>
      label ?? language ?? '${(bitrate != null ? '${(bitrate! / 1000).round()} kbps' : 'Track $id')}';

  factory AudioTrack.fromMap(Map<Object?, Object?> map) => AudioTrack(
        id: (map['id'] as num).toInt(),
        language: map['language'] as String?,
        bitrate: (map['bitrate'] as num?)?.toInt(),
        label: map['label'] as String?,
      );
}

/// A selectable subtitle / caption track.
class SubtitleTrack {
  final int id;
  final String? language;
  final String? label;

  const SubtitleTrack({required this.id, this.language, this.label});

  String get displayLabel => label ?? language ?? 'Track $id';

  factory SubtitleTrack.fromMap(Map<Object?, Object?> map) => SubtitleTrack(
        id: (map['id'] as num).toInt(),
        language: map['language'] as String?,
        label: map['label'] as String?,
      );
}

// ─── Resize mode ─────────────────────────────────────────────────────────────

/// Controls how the video frame is scaled inside the player view.
enum ResizeMode {
  /// Fit inside the view while maintaining aspect ratio (letterbox / pillarbox).
  fit,

  /// Stretch to fill the view ignoring aspect ratio.
  fill,

  /// Zoom/crop to fill without distortion — parts may be clipped.
  zoom,

  /// Fix the width; adjust height to maintain aspect ratio.
  fixedWidth,

  /// Fix the height; adjust width to maintain aspect ratio.
  fixedHeight,
}

// ─── Error ───────────────────────────────────────────────────────────────────

class PlayerError {
  final int code;
  final String message;

  const PlayerError({required this.code, required this.message});

  @override
  String toString() => 'PlayerError($code: $message)';
}

// ─── Media info ───────────────────────────────────────────────────────────────

class MediaInfo {
  final String url;
  final Duration duration;
  final String? title;

  const MediaInfo({required this.url, required this.duration, this.title});
}

// ─── Player state ────────────────────────────────────────────────────────────

enum PlayerState { idle, buffering, ready, ended, unknown }

PlayerState playerStateFromString(String s) {
  switch (s) {
    case 'idle':      return PlayerState.idle;
    case 'buffering': return PlayerState.buffering;
    case 'ready':     return PlayerState.ready;
    case 'ended':     return PlayerState.ended;
    default:          return PlayerState.unknown;
  }
}
