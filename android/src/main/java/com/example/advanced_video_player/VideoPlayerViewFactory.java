package com.example.advanced_video_player;

import android.app.Activity;
import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class VideoPlayerViewFactory extends PlatformViewFactory {

    private final BinaryMessenger messenger;
    @Nullable
    private Activity activity;

    public VideoPlayerViewFactory(BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
    }

    public void setActivity(@Nullable Activity activity) {
        this.activity = activity;
    }

    @NonNull
    @Override
    @SuppressWarnings("unchecked")
    public PlatformView create(Context context, int viewId, @Nullable Object args) {
        Map<String, Object> params = (Map<String, Object>) args;
        return new VideoPlayerView(context, viewId, messenger, params, activity);
    }
}
