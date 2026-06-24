package com.example.advanced_video_player;

import android.app.Activity;
import android.app.PictureInPictureParams;
import android.content.Context;
import android.graphics.Color;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Rational;
import android.view.View;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.media3.common.C;
import androidx.media3.common.Format;
import androidx.media3.common.MediaItem;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.Player;
import androidx.media3.common.TrackGroup;
import androidx.media3.common.TrackSelectionOverride;
import androidx.media3.common.Tracks;
import androidx.media3.datasource.DefaultDataSource;
import androidx.media3.datasource.DefaultHttpDataSource;
import androidx.media3.exoplayer.DefaultLoadControl;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory;
import androidx.media3.ui.AspectRatioFrameLayout;
import androidx.media3.ui.PlayerView;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class VideoPlayerView implements PlatformView, MethodChannel.MethodCallHandler {

    private final FrameLayout container;
    private final ExoPlayer exoPlayer;
    private final PlayerView playerView;
    private final WatermarkOverlayView watermarkOverlay;
    private final MethodChannel methodChannel;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    @Nullable
    private Activity activity;
    @Nullable
    private EventChannel.EventSink eventSink;

    // Track total played / covered time
    private long playbackStartMs = -1;
    private long totalPlayedMs = 0;
    private long highWaterMarkMs = 0; // for totalCovered

    @SuppressWarnings("unchecked")
    VideoPlayerView(@NonNull Context context, int id,
                    BinaryMessenger messenger,
                    @Nullable Map<String, Object> creationParams,
                    @Nullable Activity activity) {
        this.activity = activity;

        // ── Build ExoPlayer ────────────────────────────────────────────────
        int maxBufferMs = 50000;
        int minBufferMs = 15000;
        int bufferForPlaybackMs = 2500;
        int bufferForPlaybackAfterRebufferMs = 5000;

        Map<String, String> httpHeaders = null;

        if (creationParams != null) {
            Map<String, Object> settings = (Map<String, Object>) creationParams.get("settings");
            if (settings != null) {
                if (settings.get("maxBufferMs") != null)
                    maxBufferMs = ((Number) settings.get("maxBufferMs")).intValue();
                if (settings.get("minBufferMs") != null)
                    minBufferMs = ((Number) settings.get("minBufferMs")).intValue();
                if (settings.get("bufferForPlaybackMs") != null)
                    bufferForPlaybackMs = ((Number) settings.get("bufferForPlaybackMs")).intValue();
                if (settings.get("bufferForPlaybackAfterRebufferMs") != null)
                    bufferForPlaybackAfterRebufferMs =
                            ((Number) settings.get("bufferForPlaybackAfterRebufferMs")).intValue();
            }
            Map<String, Object> srcOptions = (Map<String, Object>) creationParams.get("sourceOptions");
            if (srcOptions != null && srcOptions.get("httpHeaders") != null) {
                httpHeaders = (Map<String, String>) srcOptions.get("httpHeaders");
            }
        }

        DefaultLoadControl loadControl = new DefaultLoadControl.Builder()
                .setBufferDurationsMs(minBufferMs, maxBufferMs,
                        bufferForPlaybackMs, bufferForPlaybackAfterRebufferMs)
                .build();

        ExoPlayer.Builder playerBuilder = new ExoPlayer.Builder(context)
                .setLoadControl(loadControl);

        if (httpHeaders != null && !httpHeaders.isEmpty()) {
            DefaultHttpDataSource.Factory httpFactory =
                    new DefaultHttpDataSource.Factory()
                            .setDefaultRequestProperties(httpHeaders);
            playerBuilder.setMediaSourceFactory(
                    new DefaultMediaSourceFactory(
                            new DefaultDataSource.Factory(context, httpFactory)));
        }

        exoPlayer = playerBuilder.build();

        // ── Layout: PlayerView + WatermarkOverlay stacked ─────────────────
        container = new FrameLayout(context);
        container.setBackgroundColor(Color.BLACK);

        playerView = new PlayerView(context);
        playerView.setPlayer(exoPlayer);
        playerView.setUseController(false);
        playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIT);
        container.addView(playerView, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));

        watermarkOverlay = new WatermarkOverlayView(context);
        watermarkOverlay.setVisibility(View.GONE);
        container.addView(watermarkOverlay, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));

        // ── Channels ──────────────────────────────────────────────────────
        methodChannel = new MethodChannel(messenger, "advanced_video_player/player_" + id);
        methodChannel.setMethodCallHandler(this);

        EventChannel eventChannel = new EventChannel(
                messenger, "advanced_video_player/player_events_" + id);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink sink) {
                eventSink = sink;
            }
            @Override
            public void onCancel(Object arguments) {
                eventSink = null;
            }
        });

        // ── Playback listener ─────────────────────────────────────────────
        exoPlayer.addListener(new Player.Listener() {
            @Override
            public void onPlaybackStateChanged(int state) {
                Map<String, Object> data = new HashMap<>();
                data.put("state", stateString(state));
                data.put("isPlaying", exoPlayer.isPlaying());
                sendEvent("playerStateChanged", data);

                if (state == Player.STATE_READY) {
                    Map<String, Object> dur = new HashMap<>();
                    dur.put("duration", exoPlayer.getDuration());
                    sendEvent("durationChanged", dur);
                    sendTracksChangedEvent();
                }
            }

            @Override
            public void onIsPlayingChanged(boolean isPlaying) {
                if (isPlaying) {
                    playbackStartMs = System.currentTimeMillis();
                } else if (playbackStartMs >= 0) {
                    totalPlayedMs += System.currentTimeMillis() - playbackStartMs;
                    playbackStartMs = -1;
                }
                Map<String, Object> data = new HashMap<>();
                data.put("isPlaying", isPlaying);
                sendEvent("playingChanged", data);
            }

            @Override
            public void onTracksChanged(@NonNull Tracks tracks) {
                sendTracksChangedEvent();
            }

            @Override
            public void onPlaybackParametersChanged(
                    @NonNull androidx.media3.common.PlaybackParameters params) {
                Map<String, Object> data = new HashMap<>();
                data.put("speed", (double) params.speed);
                sendEvent("playbackSpeedChanged", data);
            }

            @Override
            public void onPlayerError(@NonNull PlaybackException error) {
                Map<String, Object> data = new HashMap<>();
                data.put("message",
                        error.getMessage() != null ? error.getMessage() : "Unknown error");
                data.put("code", error.errorCode);
                sendEvent("error", data);
            }
        });

        // ── Notify Flutter player is ready ────────────────────────────────
        methodChannel.invokeMethod("onPlayerCreated", id);

        // ── Apply creation params ─────────────────────────────────────────
        if (creationParams != null) {
            applyCreationParams(creationParams);
        }

        startProgressReporting();
    }

    @SuppressWarnings("unchecked")
    private void applyCreationParams(Map<String, Object> p) {
        // Source
        String videoUrl = (String) p.get("videoUrl");
        if (videoUrl != null && !videoUrl.isEmpty()) {
            Map<String, Object> srcOptions = (Map<String, Object>) p.get("sourceOptions");
            loadMedia(videoUrl, srcOptions);
        }

        Boolean autoPlay = (Boolean) p.get("autoPlay");
        exoPlayer.setPlayWhenReady(Boolean.TRUE.equals(autoPlay));

        // Watermark
        Map<String, Object> wm = (Map<String, Object>) p.get("watermark");
        if (wm != null) {
            watermarkOverlay.applyConfig(wm);
            watermarkOverlay.setVisibility(View.VISIBLE);
        }
    }

    private void loadMedia(String url, @Nullable Map<String, Object> options) {
        MediaItem.Builder builder = new MediaItem.Builder().setUri(url);
        exoPlayer.setMediaItem(builder.build());

        if (options != null) {
            Number startMs = (Number) options.get("startPositionMs");
            if (startMs != null) exoPlayer.seekTo(startMs.longValue());
        }

        exoPlayer.prepare();
    }

    // ── Track helpers ──────────────────────────────────────────────────────

    private void sendTracksChangedEvent() {
        Tracks tracks = exoPlayer.getCurrentTracks();
        List<Map<String, Object>> videoList = new ArrayList<>();
        List<Map<String, Object>> audioList = new ArrayList<>();
        List<Map<String, Object>> subtitleList = new ArrayList<>();

        List<Tracks.Group> groups = tracks.getGroups();
        for (int gi = 0; gi < groups.size(); gi++) {
            Tracks.Group group = groups.get(gi);
            int type = group.getType();
            for (int ti = 0; ti < group.length; ti++) {
                Format fmt = group.getTrackFormat(ti);
                // Encode groupIndex and trackIndex into a single ID
                int id = gi * 1000 + ti;
                Map<String, Object> track = new HashMap<>();
                track.put("id", id);
                if (type == C.TRACK_TYPE_VIDEO) {
                    if (fmt.bitrate != Format.NO_VALUE) track.put("bitrate", fmt.bitrate / 1000);
                    if (fmt.width != Format.NO_VALUE) track.put("width", fmt.width);
                    if (fmt.height != Format.NO_VALUE) track.put("height", fmt.height);
                    videoList.add(track);
                } else if (type == C.TRACK_TYPE_AUDIO) {
                    if (fmt.language != null) track.put("language", fmt.language);
                    if (fmt.bitrate != Format.NO_VALUE) track.put("bitrate", fmt.bitrate / 1000);
                    if (fmt.label != null) track.put("label", fmt.label);
                    audioList.add(track);
                } else if (type == C.TRACK_TYPE_TEXT) {
                    if (fmt.language != null) track.put("language", fmt.language);
                    if (fmt.label != null) track.put("label", fmt.label);
                    subtitleList.add(track);
                }
            }
        }

        Map<String, Object> data = new HashMap<>();
        data.put("videoTracks", videoList);
        data.put("audioTracks", audioList);
        data.put("subtitleTracks", subtitleList);
        sendEvent("tracksChanged", data);
    }

    private void selectTrack(int encodedId, int targetType) {
        int groupIndex = encodedId / 1000;
        int trackIndex = encodedId % 1000;

        Tracks tracks = exoPlayer.getCurrentTracks();
        List<Tracks.Group> groups = tracks.getGroups();
        if (groupIndex >= groups.size()) return;
        Tracks.Group group = groups.get(groupIndex);
        if (group.getType() != targetType) return;

        TrackGroup mediaGroup = group.getMediaTrackGroup();
        TrackSelectionOverride override =
                new TrackSelectionOverride(mediaGroup,
                        Collections.singletonList(trackIndex));
        exoPlayer.setTrackSelectionParameters(
                exoPlayer.getTrackSelectionParameters()
                        .buildUpon()
                        .addOverride(override)
                        .build());
    }

    private void clearTrackSelection(int targetType) {
        exoPlayer.setTrackSelectionParameters(
                exoPlayer.getTrackSelectionParameters()
                        .buildUpon()
                        .clearOverridesOfType(targetType)
                        .build());
    }

    private void disableSubtitles() {
        exoPlayer.setTrackSelectionParameters(
                exoPlayer.getTrackSelectionParameters()
                        .buildUpon()
                        .setIgnoredTextSelectionFlags(C.SELECTION_FLAG_DEFAULT)
                        .build());
    }

    // ── Method channel ─────────────────────────────────────────────────────

    @Override
    @SuppressWarnings("unchecked")
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {

            // ── Basic playback ───────────────────────────────────────────
            case "play":
                exoPlayer.play();
                result.success(null);
                break;
            case "pause":
                exoPlayer.pause();
                result.success(null);
                break;
            case "stop":
                exoPlayer.stop();
                result.success(null);
                break;
            case "seekTo": {
                long ms = ((Number) call.arguments).longValue();
                exoPlayer.seekTo(ms);
                // Update high-water mark for totalCovered
                if (ms > highWaterMarkMs) highWaterMarkMs = ms;
                result.success(null);
                break;
            }
            case "setVolume":
                exoPlayer.setVolume(((Number) call.arguments).floatValue());
                result.success(null);
                break;
            case "setPlaybackSpeed":
                exoPlayer.setPlaybackSpeed(((Number) call.arguments).floatValue());
                result.success(null);
                break;

            // ── Load ─────────────────────────────────────────────────────
            case "loadUrl": {
                Map<String, Object> args = (Map<String, Object>) call.arguments;
                String url = (String) args.get("url");
                Map<String, Object> opts = new HashMap<>();
                loadMedia(url, opts);
                result.success(null);
                break;
            }
            case "loadSource": {
                Map<String, Object> src = (Map<String, Object>) call.arguments;
                String url = (String) src.get("url");
                Map<String, Object> opts = (Map<String, Object>) src.get("options");
                loadMedia(url, opts);
                result.success(null);
                break;
            }

            // ── Track selection ──────────────────────────────────────────
            case "setAdaptive":
                clearTrackSelection(C.TRACK_TYPE_VIDEO);
                result.success(null);
                break;
            case "setVideoTrack":
                selectTrack(((Number) call.arguments).intValue(), C.TRACK_TYPE_VIDEO);
                result.success(null);
                break;
            case "setAudioTrack":
                selectTrack(((Number) call.arguments).intValue(), C.TRACK_TYPE_AUDIO);
                result.success(null);
                break;
            case "setSubtitleTrack":
                if (call.arguments == null) {
                    disableSubtitles();
                } else {
                    selectTrack(((Number) call.arguments).intValue(), C.TRACK_TYPE_TEXT);
                }
                result.success(null);
                break;

            // ── Display ──────────────────────────────────────────────────
            case "setResizeMode":
                playerView.setResizeMode(mapResizeMode((String) call.arguments));
                result.success(null);
                break;

            // ── Fullscreen ────────────────────────────────────────────────
            case "enterFullScreen":
                methodChannel.invokeMethod("onFullscreenChanged", true);
                result.success(null);
                break;
            case "exitFullScreen":
                methodChannel.invokeMethod("onFullscreenChanged", false);
                result.success(null);
                break;

            // ── Picture-in-Picture ────────────────────────────────────────
            case "enterPiP":
                enterPiPMode();
                result.success(null);
                break;

            // ── Watermark ─────────────────────────────────────────────────
            case "updateWatermark": {
                Map<String, Object> wm = (Map<String, Object>) call.arguments;
                if (wm != null) {
                    watermarkOverlay.applyConfig(wm);
                    watermarkOverlay.setVisibility(View.VISIBLE);
                } else {
                    watermarkOverlay.stopAnimation();
                    watermarkOverlay.setVisibility(View.GONE);
                }
                result.success(null);
                break;
            }

            // ── Query ─────────────────────────────────────────────────────
            case "getPosition":
                result.success(exoPlayer.getCurrentPosition());
                break;
            case "getDuration":
                result.success(exoPlayer.getDuration());
                break;
            case "isPlaying":
                result.success(exoPlayer.isPlaying());
                break;
            case "getPlaybackProperty": {
                String prop = (String) call.arguments;
                if ("totalPlayed".equals(prop)) {
                    long current = exoPlayer.isPlaying()
                            ? totalPlayedMs + (System.currentTimeMillis() - playbackStartMs)
                            : totalPlayedMs;
                    result.success((int) (current / 1000));
                } else if ("totalCovered".equals(prop)) {
                    long covered = Math.max(highWaterMarkMs, exoPlayer.getCurrentPosition());
                    result.success((int) (covered / 1000));
                } else {
                    result.success(null);
                }
                break;
            }

            default:
                result.notImplemented();
        }
    }

    // ── PiP ────────────────────────────────────────────────────────────────

    private void enterPiPMode() {
        if (activity == null) return;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            int w = playerView.getWidth();
            int h = playerView.getHeight();
            if (w > 0 && h > 0) {
                PictureInPictureParams params = new PictureInPictureParams.Builder()
                        .setAspectRatio(new Rational(w, h))
                        .build();
                activity.enterPictureInPictureMode(params);
            } else {
                activity.enterPictureInPictureMode(
                        new PictureInPictureParams.Builder().build());
            }
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private String stateString(int state) {
        switch (state) {
            case Player.STATE_IDLE:      return "idle";
            case Player.STATE_BUFFERING: return "buffering";
            case Player.STATE_READY:     return "ready";
            case Player.STATE_ENDED:     return "ended";
            default:                     return "unknown";
        }
    }

    private int mapResizeMode(String mode) {
        if (mode == null) return AspectRatioFrameLayout.RESIZE_MODE_FIT;
        switch (mode) {
            case "fill":        return AspectRatioFrameLayout.RESIZE_MODE_FILL;
            case "zoom":        return AspectRatioFrameLayout.RESIZE_MODE_ZOOM;
            case "fixedWidth":  return AspectRatioFrameLayout.RESIZE_MODE_FIXED_WIDTH;
            case "fixedHeight": return AspectRatioFrameLayout.RESIZE_MODE_FIXED_HEIGHT;
            default:            return AspectRatioFrameLayout.RESIZE_MODE_FIT;
        }
    }

    private void sendEvent(String name, Map<String, Object> extras) {
        if (eventSink == null) return;
        Map<String, Object> event = new HashMap<>();
        event.put("event", name);
        if (extras != null) event.putAll(extras);
        eventSink.success(event);
    }

    // ── Progress reporting ─────────────────────────────────────────────────

    private final Runnable progressRunnable = new Runnable() {
        @Override
        public void run() {
            if (eventSink != null) {
                long pos = exoPlayer.getCurrentPosition();
                long dur = exoPlayer.getDuration();
                long buf = exoPlayer.getBufferedPosition();

                // Update high-water mark during forward playback
                if (pos > highWaterMarkMs) highWaterMarkMs = pos;

                long currentPlayed = exoPlayer.isPlaying()
                        ? totalPlayedMs + (System.currentTimeMillis() - playbackStartMs)
                        : totalPlayedMs;

                Map<String, Object> extras = new HashMap<>();
                extras.put("position", pos);
                extras.put("duration", dur >= 0 ? dur : 0);
                extras.put("buffered", buf);
                extras.put("totalPlayedSeconds", (int) (currentPlayed / 1000));
                extras.put("totalCoveredSeconds", (int) (highWaterMarkMs / 1000));
                sendEvent("progress", extras);
            }
            mainHandler.postDelayed(this, 500);
        }
    };

    private void startProgressReporting() {
        mainHandler.postDelayed(progressRunnable, 500);
    }

    @NonNull
    @Override
    public View getView() {
        return container;
    }

    @Override
    public void dispose() {
        mainHandler.removeCallbacks(progressRunnable);
        watermarkOverlay.stopAnimation();
        if (exoPlayer.isPlaying() && playbackStartMs >= 0) {
            totalPlayedMs += System.currentTimeMillis() - playbackStartMs;
        }
        exoPlayer.release();
        methodChannel.setMethodCallHandler(null);
    }

    void setActivity(@Nullable Activity activity) {
        this.activity = activity;
    }
}
