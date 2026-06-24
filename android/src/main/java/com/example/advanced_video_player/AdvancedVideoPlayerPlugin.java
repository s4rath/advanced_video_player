package com.example.advanced_video_player;

import android.app.Activity;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class AdvancedVideoPlayerPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {

    private static final String VIEW_TYPE = "advanced_video_player/video_player";

    private MethodChannel channel;
    private VideoPlayerViewFactory viewFactory;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "advanced_video_player");
        channel.setMethodCallHandler(this);

        viewFactory = new VideoPlayerViewFactory(binding.getBinaryMessenger());
        binding.getPlatformViewRegistry().registerViewFactory(VIEW_TYPE, viewFactory);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        if (viewFactory != null) {
            viewFactory.setActivity(binding.getActivity());
        }
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {}

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        if (viewFactory != null) {
            viewFactory.setActivity(binding.getActivity());
        }
    }

    @Override
    public void onDetachedFromActivity() {
        if (viewFactory != null) {
            viewFactory.setActivity(null);
        }
    }
}
