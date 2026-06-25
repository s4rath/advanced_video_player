import 'package:flutter/material.dart';
import 'package:advanced_video_player/advanced_video_player.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Video Player Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const VideoPlayerScreen(),
    );
  }
}

// ─── Demo screen ─────────────────────────────────────────────────────────────

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});
  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with PlaybackEventListener {
  // Public MP4 test video
  static const _defaultUrl =
      'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';

  AdvancedVideoPlayerController? _controller;
  String _status = 'Initializing…';
  bool _isFullscreen = false;

  // Simulated API watermark response
  final Map<String, dynamic> _apiResponse = {
    'watermark_text': 'user@example.com',
    'watermark_alpha': 0.35,
    'watermark_color': '#FFFFFF',
    'watermark_font_size': 13.0,
    'watermark_is_moving': true,
    'watermark_move_duration_ms': 4000,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen
          ? null
          : AppBar(
              title: const Text('Advanced Video Player'),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Player ────────────────────────────────────────────────────
            AdvancedVideoPlayerWidget(
              source: VideoSource(
                url: _defaultUrl,
                options: const VideoSourceOptions(autoplay: false),
              ),
              watermark: WatermarkConfig.fromApiResponse(_apiResponse),
              settings: const PlayerSettings(maxBufferMs: 30000),
              showControls: true,
              aspectRatio: 16 / 9,
              onPlayerCreated: (c) => setState(() => _controller = c),
              playbackEventListener: this,
              onFullscreenChange: (fs) =>
                  setState(() => _isFullscreen = fs),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  Text(_status,
                      style: const TextStyle(
                          color: Colors.black, fontSize: 12)),
                  const SizedBox(height: 12),

                  // ── Playback controls ─────────────────────────────────
                  _sectionTitle('Playback'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('Play', () => _controller?.play()),
                    _chip('Pause', () => _controller?.pause()),
                    _chip('+10s', () async {
                      final p = await _controller?.getPosition();
                      if (p != null) {
                        _controller
                            ?.seekTo(p + const Duration(seconds: 10));
                      }
                    }),
                    _chip('1.5x speed', () =>
                        _controller?.setPlaybackSpeed(1.5)),
                    _chip('Normal speed', () =>
                        _controller?.setPlaybackSpeed(1.0)),
                    _chip('Volume 50%', () =>
                        _controller?.setVolume(0.5)),
                  ]),
                  const SizedBox(height: 12),

                  // ── Display ───────────────────────────────────────────
                  _sectionTitle('Resize Mode'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('Fit', () =>
                        _controller?.setResizeMode(ResizeMode.fit)),
                    _chip('Fill', () =>
                        _controller?.setResizeMode(ResizeMode.fill)),
                    _chip('Zoom', () =>
                        _controller?.setResizeMode(ResizeMode.zoom)),
                  ]),
                  const SizedBox(height: 12),

                  // ── Track quality ─────────────────────────────────────
                  _sectionTitle('Quality'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('Adaptive', () => _controller?.setAdaptive()),
                    if (_controller?.value.videoTracks.isNotEmpty ?? false)
                      ..._controller!.value.videoTracks.map((t) =>
                          _chip(t.label, () =>
                              _controller?.setVideoTrack(t))),
                  ]),
                  const SizedBox(height: 12),

                  // ── Subtitles ─────────────────────────────────────────
                  _sectionTitle('Subtitles'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('Off', () =>
                        _controller?.setSubtitleTrack(null)),
                    if (_controller?.value.subtitleTracks.isNotEmpty ??
                        false)
                      ..._controller!.value.subtitleTracks.map((t) =>
                          _chip(t.displayLabel, () =>
                              _controller?.setSubtitleTrack(t))),
                  ]),
                  const SizedBox(height: 12),

                  // ── Load different source ─────────────────────────────
                  _sectionTitle('Load New Source'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('HLS Stream', () {
                      _controller?.load(VideoSource(
                        url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
                        options: const VideoSourceOptions(autoplay: true),
                      ));
                    }),
                    _chip('MP4 Sample', () {
                      _controller?.load(VideoSource(url: _defaultUrl));
                    }),
                  ]),
                  const SizedBox(height: 12),

                  // ── Watermark ─────────────────────────────────────────
                  _sectionTitle('Watermark (from API response)'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('Moving', () {
                      _controller?.updateWatermark(
                        WatermarkConfig.fromApiResponse({
                          ..._apiResponse,
                          'watermark_is_moving': true,
                        }),
                      );
                    }),
                    _chip('Fixed top-left', () {
                      _controller?.updateWatermark(
                        WatermarkConfig.fromApiResponse({
                          ..._apiResponse,
                          'watermark_is_moving': false,
                          'watermark_position_x': 0.05,
                          'watermark_position_y': 0.05,
                        }),
                      );
                    }),
                    _chip('Gold text', () {
                      _controller?.updateWatermark(
                        WatermarkConfig.fromApiResponse({
                          ..._apiResponse,
                          'watermark_text': 'sarath@reizend.ai',
                          'watermark_color': '#FFD700',
                          'watermark_font_size': 16.0,
                        }),
                      );
                    }),
                    _chip('Hide', () => _controller?.updateWatermark(null)),
                  ]),
                  const SizedBox(height: 12),

                  // ── Fullscreen / PiP ──────────────────────────────────
                  _sectionTitle('Fullscreen & PiP'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('Enter Fullscreen',
                        () => _controller?.enterFullScreen()),
                    _chip('Enter PiP',
                        () => _controller?.enterPiP()),
                  ]),
                  const SizedBox(height: 12),

                  // ── Analytics ─────────────────────────────────────────
                  _sectionTitle('Analytics'),
                  _chip('Get Stats', () async {
                    final played = await _controller
                        ?.getPlaybackProperty('totalPlayed');
                    final covered = await _controller
                        ?.getPlaybackProperty('totalCovered');
                    setState(() {
                      _status =
                          'Played: ${played}s | Covered: ${covered}s';
                    });
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PlaybackEventListener ─────────────────────────────────────────────────

  @override
  void onLoading(VideoSource source) =>
      setState(() => _status = 'Loading…');

  @override
  void onLoaded(VideoSource source) =>
      setState(() => _status = 'Ready');

  @override
  void onMediaEnded(VideoSource source) =>
      setState(() => _status = 'Ended');

  @override
  void onError(VideoSource source, PlayerError error) =>
      setState(() => _status = 'Error ${error.code}: ${error.message}');

  @override
  void onProgress(int positionMs) {} // handled by controller.value

  @override
  void onTracksChanged(List<VideoTrack> videoTracks,
      List<AudioTrack> audioTracks, List<SubtitleTrack> subtitleTracks) {
    setState(() {
      _status =
          '${videoTracks.length} video tracks, ${audioTracks.length} audio, ${subtitleTracks.length} subs';
    });
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      );

  Widget _chip(String label, VoidCallback? onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      );
}
