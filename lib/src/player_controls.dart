import 'dart:async';

import 'package:flutter/material.dart';

import 'advanced_video_player_controller.dart';
import 'player_value.dart';

/// Built-in controls overlay — mirroring VdoCipher's `VdoControllerView`.
///
/// Rendered as a [Stack] child on top of the video. Tapping the video area
/// toggles control visibility. Auto-hides after 3 seconds of inactivity.
class PlayerControlsOverlay extends StatefulWidget {
  final AdvancedVideoPlayerController controller;
  final VoidCallback onFullscreenToggle;
  final bool isFullscreen;

  const PlayerControlsOverlay({
    super.key,
    required this.controller,
    required this.onFullscreenToggle,
    this.isFullscreen = false,
  });

  @override
  State<PlayerControlsOverlay> createState() => _PlayerControlsOverlayState();
}

class _PlayerControlsOverlayState extends State<PlayerControlsOverlay> {
  bool _visible = true;
  bool _showSpeedPicker = false;
  bool _showQualityPicker = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onValueChanged);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onValueChanged);
    super.dispose();
  }

  void _onValueChanged() => setState(() {});

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _visible = false;
          _showSpeedPicker = false;
          _showQualityPicker = false;
        });
      }
    });
  }

  void _showControls() {
    setState(() => _visible = true);
    _scheduleHide();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final v = widget.controller.value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showControls,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: !_visible,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Semi-transparent scrim
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x88000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0xAA000000),
                    ],
                    stops: [0, 0.2, 0.7, 1],
                  ),
                ),
              ),
              // Center play/pause + skip buttons
              _buildCenterRow(v),
              // Bottom bar: seek + time + speed + quality + fullscreen
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomBar(v),
              ),
              // Picker overlays
              if (_showSpeedPicker) _buildSpeedPicker(v),
              if (_showQualityPicker) _buildQualityPicker(v),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterRow(PlayerValue v) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBtn(Icons.replay_10, () async {
            final pos = await widget.controller.getPosition();
            widget.controller
                .seekTo(pos - const Duration(seconds: 10));
          }, size: 36),
          const SizedBox(width: 24),
          _iconBtn(
            v.isBuffering
                ? null
                : (v.isPlaying ? Icons.pause_circle : Icons.play_circle),
            v.isBuffering
                ? null
                : () => v.isPlaying
                    ? widget.controller.pause()
                    : widget.controller.play(),
            size: 56,
            loading: v.isBuffering,
          ),
          const SizedBox(width: 24),
          _iconBtn(Icons.forward_10, () async {
            final pos = await widget.controller.getPosition();
            widget.controller
                .seekTo(pos + const Duration(seconds: 10));
          }, size: 36),
        ],
      ),
    );
  }

  Widget _buildBottomBar(PlayerValue v) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSeekBar(v),
          Row(
            children: [
              // Current / total time
              Text(
                '${_fmt(v.position)} / ${_fmt(v.duration)}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              const Spacer(),
              // Playback speed
              _textBtn(
                '${v.playbackSpeed}x',
                () => setState(() {
                  _showSpeedPicker = !_showSpeedPicker;
                  _showQualityPicker = false;
                }),
              ),
              const SizedBox(width: 4),
              // Quality
              if (v.videoTracks.isNotEmpty)
                _textBtn(
                  v.selectedVideoTrack?.label ?? 'Auto',
                  () => setState(() {
                    _showQualityPicker = !_showQualityPicker;
                    _showSpeedPicker = false;
                  }),
                ),
              const SizedBox(width: 4),
              // Fullscreen
              _iconBtn(
                widget.isFullscreen
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen,
                widget.onFullscreenToggle,
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeekBar(PlayerValue v) {
    final total = v.duration.inMilliseconds.toDouble();
    final pos = v.position.inMilliseconds
        .clamp(0, total > 0 ? total : 1)
        .toDouble();
    final buffered = v.bufferedPosition.inMilliseconds
        .clamp(0, total > 0 ? total : 1)
        .toDouble();

    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Buffered progress
          if (total > 0)
            FractionallySizedBox(
              widthFactor: buffered / total,
              child: Container(height: 3, color: Colors.white38),
            ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.transparent,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
            ),
            child: Slider(
              value: pos,
              max: total > 0 ? total : 1,
              onChanged: total > 0
                  ? (v2) => widget.controller.seekTo(
                      Duration(milliseconds: v2.toInt()))
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedPicker(PlayerValue v) {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    return _picker(
      title: 'Playback Speed',
      children: speeds
          .map((s) => _pickerItem(
                '${s}x',
                v.playbackSpeed == s,
                () {
                  widget.controller.setPlaybackSpeed(s);
                  setState(() => _showSpeedPicker = false);
                },
              ))
          .toList(),
    );
  }

  Widget _buildQualityPicker(PlayerValue v) {
    return _picker(
      title: 'Quality',
      children: [
        _pickerItem('Auto', v.isAdaptive, () {
          widget.controller.setAdaptive();
          setState(() => _showQualityPicker = false);
        }),
        ...v.videoTracks.map((t) => _pickerItem(
              t.label,
              !v.isAdaptive && v.selectedVideoTrack?.id == t.id,
              () {
                widget.controller.setVideoTrack(t);
                setState(() => _showQualityPicker = false);
              },
            )),
      ],
    );
  }

  Widget _picker({required String title, required List<Widget> children}) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() {
          _showSpeedPicker = false;
          _showQualityPicker = false;
        }),
        child: Container(
          color: Colors.black87,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 240,
                maxHeight: 280, // Restrict maximum height in landscape/portrait
              ),
              child: Material(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(title,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      const Divider(
                          color: Colors.white12, height: 1),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: children,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickerItem(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 14))),
            if (selected)
              const Icon(Icons.check, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData? icon, VoidCallback? onTap,
      {double size = 28, bool loading = false}) {
    return IconButton(
      icon: loading
          ? SizedBox(
              width: size * 0.7,
              height: size * 0.7,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ))
          : Icon(icon, color: Colors.white, size: size),
      onPressed: onTap,
    );
  }

  Widget _textBtn(String label, VoidCallback onTap) => TextButton(
        style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
