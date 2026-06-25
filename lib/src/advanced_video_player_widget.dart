import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'advanced_video_player_controller.dart';
import 'player_controls.dart';
import 'player_settings.dart';
import 'player_types.dart';
import 'playback_event_listener.dart';
import 'video_source.dart';
import 'watermark_config.dart';

/// A Flutter widget that embeds a native Android ExoPlayer with optional
/// controls, fullscreen support, PiP, and an animated watermark overlay.
///
/// **Android only.** A placeholder is shown on other platforms.
///
/// ### Minimal usage
/// ```dart
/// AdvancedVideoPlayerWidget(
///   source: VideoSource(url: 'https://example.com/video.m3u8'),
///   onPlayerCreated: (c) => _controller = c,
/// )
/// ```
///
/// ### With all features
/// ```dart
/// AdvancedVideoPlayerWidget(
///   source: VideoSource(
///     url: 'https://example.com/video.m3u8',
///     options: VideoSourceOptions(autoplay: true),
///   ),
///   showControls: true,
///   watermark: WatermarkConfig.fromApiResponse(apiJson),
///   settings: PlayerSettings(maxBufferMs: 30000),
///   aspectRatio: 16 / 9,
///   onPlayerCreated: (c) => _controller = c,
///   playbackEventListener: MyListener(),
///   onFullscreenChange: (fs) => print('fullscreen: $fs'),
///   onPiPModeChanged: (pip) => print('pip: $pip'),
/// )
/// ```
class AdvancedVideoPlayerWidget extends StatefulWidget {
  final VideoSource? source;
  final WatermarkConfig? watermark;
  final PlayerSettings? settings;
  final bool autoPlay;

  /// Show the built-in Dart controls overlay (play/pause, seek, speed, quality).
  final bool showControls;

  /// Whether to block screen capture and recording on Android.
  final bool isSecure;

  final double aspectRatio;

  final void Function(AdvancedVideoPlayerController controller)? onPlayerCreated;
  final PlaybackEventListener? playbackEventListener;
  final void Function(bool isFullscreen)? onFullscreenChange;
  final void Function(bool isInPiPMode)? onPiPModeChanged;

  const AdvancedVideoPlayerWidget({
    super.key,
    this.source,
    this.watermark,
    this.settings,
    this.autoPlay = true,
    this.showControls = false,
    this.isSecure = true,
    this.aspectRatio = 16 / 9,
    this.onPlayerCreated,
    this.playbackEventListener,
    this.onFullscreenChange,
    this.onPiPModeChanged,
  });

  @override
  State<AdvancedVideoPlayerWidget> createState() =>
      _AdvancedVideoPlayerWidgetState();
}

class _AdvancedVideoPlayerWidgetState
    extends State<AdvancedVideoPlayerWidget> with WidgetsBindingObserver {
  static const String _viewType = 'advanced_video_player/video_player';
  final GlobalKey _platformViewKey = GlobalKey();

  AdvancedVideoPlayerController? _controller;
  bool _isFullscreen = false;
  OverlayEntry? _fullscreenOverlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeFullscreenOverlay();
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            'AdvancedVideoPlayerWidget is Android-only.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: _buildPlayerWithControls(),
    );
  }

  Widget _buildPlayerWithControls() {
    if (_isFullscreen) {
      return const ColoredBox(color: Colors.black);
    }
    return _buildPlayerView();
  }

  Widget _buildPlayerView({bool isFullscreen = false}) {
    final error = _controller?.value.error;
    if (error != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
                const SizedBox(height: 12),
                Text(
                  'Playback Error (${error.code})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  error.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.source != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.12),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    onPressed: () {
                      _controller?.load(widget.source!);
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final nativeView = _buildNativeView();
    final isBuffering = _controller?.value.isBuffering ?? false;

    Widget mainContent = nativeView;
    if (widget.showControls && _controller != null) {
      mainContent = Stack(
        fit: StackFit.expand,
        children: [
          nativeView,
          PlayerControlsOverlay(
            controller: _controller!,
            onFullscreenToggle: _toggleFullscreen,
            isFullscreen: isFullscreen,
          ),
        ],
      );
    }

    if (isBuffering) {
      return Stack(
        fit: StackFit.expand,
        children: [
          mainContent,
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ],
      );
    }

    return mainContent;
  }

  Widget _buildNativeView() {
    return PlatformViewLink(
      key: _platformViewKey,
      viewType: _viewType,
      surfaceFactory: (context, controller) => AndroidViewSurface(
        controller: controller as AndroidViewController,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      ),
      onCreatePlatformView: (params) {
        final Map<String, Object> creationParams = {
          'videoUrl': widget.source?.url ?? '',
          'autoPlay': widget.autoPlay,
          'isSecure': widget.isSecure,
          if (widget.source?.options != null)
            'sourceOptions': widget.source!.options!.toMap(),
          if (widget.watermark != null) 'watermark': widget.watermark!.toMap(),
          if (widget.settings != null) 'settings': widget.settings!.toMap(),
        };

        return PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: _viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        )
          ..addOnPlatformViewCreatedListener((id) {
            params.onPlatformViewCreated(id);
            _initController(id);
          })
          ..create();
      },
    );
  }

  void _initController(int id) {
    final methodChannel = MethodChannel('advanced_video_player/player_$id');
    final eventChannel = EventChannel('advanced_video_player/player_events_$id');

    final controller = AdvancedVideoPlayerController.withChannels(
        methodChannel, eventChannel);

    methodChannel.setMethodCallHandler((call) async {
      controller.handleMethodCall(call.method, call.arguments);
      _handleNativeCallback(call.method, call.arguments);
    });

    controller.events.listen((event) {
      final name = event['event'] as String? ?? '';
      controller.handleEvent(name, event);
      _dispatchToListener(name, event);
    });

    controller.addListener(_onControllerChanged);

    setState(() => _controller = controller);
    widget.onPlayerCreated?.call(controller);
  }

  void _handleNativeCallback(String method, dynamic args) {
    switch (method) {
      case 'onFullscreenChanged':
        final fullscreen = args as bool? ?? false;
        setState(() => _isFullscreen = fullscreen);
        widget.onFullscreenChange?.call(fullscreen);
        if (fullscreen) {
          _enterFullscreenUI();
        } else {
          _exitFullscreenUI();
        }
        break;
      case 'onPiPModeChanged':
        widget.onPiPModeChanged?.call(args as bool? ?? false);
        break;
    }
  }

  void _dispatchToListener(String name, Map<String, dynamic> data) {
    final l = widget.playbackEventListener;
    if (l == null) return;
    switch (name) {
      case 'progress':
        l.onProgress((data['position'] as int?) ?? 0);
        l.onBufferUpdate((data['buffered'] as int?) ?? 0);
        break;
      case 'playbackSpeedChanged':
        l.onPlaybackSpeedChanged((data['speed'] as num?)?.toDouble() ?? 1.0);
        break;
      case 'tracksChanged':
        final rawV =
            (data['videoTracks'] as List?)?.cast<Map<Object?, Object?>>() ?? [];
        final rawA =
            (data['audioTracks'] as List?)?.cast<Map<Object?, Object?>>() ?? [];
        final rawS = (data['subtitleTracks'] as List?)
                ?.cast<Map<Object?, Object?>>() ??
            [];
        l.onTracksChanged(
          rawV.map(VideoTrack.fromMap).toList(),
          rawA.map(AudioTrack.fromMap).toList(),
          rawS.map(SubtitleTrack.fromMap).toList(),
        );
        break;
      case 'playerStateChanged':
        final state = data['state'] as String? ?? '';
        if (state == 'buffering') {
          l.onLoading(widget.source ?? VideoSource(url: ''));
        } else if (state == 'ready') {
          l.onLoaded(widget.source ?? VideoSource(url: ''));
        } else if (state == 'ended') {
          l.onMediaEnded(widget.source ?? VideoSource(url: ''));
        }
        break;
      case 'error':
        l.onError(
          widget.source ?? VideoSource(url: ''),
          PlayerError(
            code: (data['code'] as int?) ?? -1,
            message: data['message'] as String? ?? '',
          ),
        );
        break;
    }
  }

  // ── Fullscreen UI ──────────────────────────────────────────────────────────

  void _toggleFullscreen() {
    if (_isFullscreen) {
      _controller?.exitFullScreen();
    } else {
      _controller?.enterFullScreen();
    }
  }

  void _enterFullscreenUI() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _fullscreenOverlay = OverlayEntry(
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        body: _buildPlayerView(isFullscreen: true),
      ),
    );
    Overlay.of(context).insert(_fullscreenOverlay!);
  }

  void _exitFullscreenUI() {
    _removeFullscreenOverlay();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _removeFullscreenOverlay() {
    _fullscreenOverlay?.remove();
    _fullscreenOverlay = null;
  }
}
