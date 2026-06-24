/// Describes what video to load — the equivalent of VdoCipher's EmbedInfo
/// but for arbitrary URL-based content.
class VideoSource {
  /// The video URL — supports HLS (.m3u8), DASH (.mpd), MP4, and any scheme
  /// ExoPlayer can handle.
  final String url;

  /// Optional playback options.
  final VideoSourceOptions? options;

  const VideoSource({required this.url, this.options});

  Map<String, dynamic> toMap() => {
        'url': url,
        if (options != null) 'options': options!.toMap(),
      };
}

/// Fine-grained options for [VideoSource].
class VideoSourceOptions {
  /// Seek to this position immediately after load.
  final Duration? startPosition;

  /// Stop playback at this position (clip end).
  final Duration? endPosition;

  /// Resume from the last known position (pass the position yourself).
  final Duration? resumePosition;

  /// Whether to start playing as soon as buffered.
  final bool autoplay;

  /// Extra HTTP request headers sent with every media segment request.
  final Map<String, String>? httpHeaders;

  /// Cap adaptive bitrate to this value (kbps).
  final int? maxBitrateKbps;

  /// Force the lowest available bitrate regardless of network.
  final bool forceLowestBitrate;

  /// Preferred subtitle / caption language (ISO 639 code).
  final String? preferredSubtitleLanguage;

  const VideoSourceOptions({
    this.startPosition,
    this.endPosition,
    this.resumePosition,
    this.autoplay = true,
    this.httpHeaders,
    this.maxBitrateKbps,
    this.forceLowestBitrate = false,
    this.preferredSubtitleLanguage,
  });

  Map<String, dynamic> toMap() => {
        'autoplay': autoplay,
        'forceLowestBitrate': forceLowestBitrate,
        if (startPosition != null)
          'startPositionMs': startPosition!.inMilliseconds,
        if (endPosition != null)
          'endPositionMs': endPosition!.inMilliseconds,
        if (resumePosition != null)
          'resumePositionMs': resumePosition!.inMilliseconds,
        if (httpHeaders != null) 'httpHeaders': httpHeaders,
        if (maxBitrateKbps != null) 'maxBitrateKbps': maxBitrateKbps,
        if (preferredSubtitleLanguage != null)
          'preferredSubtitleLanguage': preferredSubtitleLanguage,
      };
}
