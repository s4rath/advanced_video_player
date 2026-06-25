package com.example.advanced_video_player;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ObjectAnimator;
import android.content.Context;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.util.TypedValue;
import android.view.Gravity;
import android.widget.FrameLayout;
import android.widget.TextView;

import java.util.Map;
import java.util.Random;

/**
 * Transparent overlay that displays a configurable watermark text above the video.
 * When isMoving=true the text fades out, jumps to a random position, and fades back in
 * at the configured interval — mirroring VdoCipher's animated watermark behavior.
 */
public class WatermarkOverlayView extends FrameLayout {

    private final TextView watermarkText;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Random random = new Random();

    private Runnable moveRunnable;
    private float targetAlpha = 0.3f;
    private int moveDurationMs = 5000;

    public WatermarkOverlayView(Context context) {
        super(context);

        watermarkText = new TextView(context);
        watermarkText.setTextColor(Color.WHITE);
        watermarkText.setAlpha(targetAlpha);
        watermarkText.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f);

        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
        lp.gravity = Gravity.TOP | Gravity.START;
        addView(watermarkText, lp);

        // Never intercept touch events — pass through to the video surface
        setClickable(false);
        setFocusable(false);
    }

    /**
     * Apply watermark configuration received from Flutter (API response values).
     *
     * Expected keys:
     *   text           String  – watermark label (e.g. user email)
     *   alpha          float   – opacity 0-1 (default 0.3)
     *   color          String  – hex color, e.g. "#FFFFFF" (default white)
     *   fontSize       float   – sp size (default 14)
     *   isMoving       bool    – animate to random positions (default true)
     *   moveDurationMs int     – ms between moves (default 5000)
     *   positionX      float   – 0-1 relative X, used when isMoving=false
     *   positionY      float   – 0-1 relative Y, used when isMoving=false
     */
    public void applyConfig(Map<String, Object> config) {
        if (config == null) return;

        String text = (String) config.get("text");
        if (text != null) watermarkText.setText(text);

        if (config.get("alpha") != null) {
            targetAlpha = ((Number) config.get("alpha")).floatValue();
            watermarkText.setAlpha(targetAlpha);
        }

        if (config.get("color") != null) {
            try {
                watermarkText.setTextColor(Color.parseColor((String) config.get("color")));
            } catch (IllegalArgumentException ignored) {
                watermarkText.setTextColor(Color.WHITE);
            }
        }

        if (config.get("fontSize") != null) {
            float sp = ((Number) config.get("fontSize")).floatValue();
            watermarkText.setTextSize(TypedValue.COMPLEX_UNIT_SP, sp);
        }

        boolean isMoving = Boolean.TRUE.equals(config.get("isMoving"));

        if (config.get("moveDurationMs") != null) {
            moveDurationMs = ((Number) config.get("moveDurationMs")).intValue();
        }

        stopAnimation();

        if (isMoving) {
            startMovingAnimation();
        } else {
            positionFixed(config);
        }
    }

    // Place the watermark at a fixed relative position (0-1 of parent dimensions).
    private void positionFixed(final Map<String, Object> config) {
        post(() -> {
            final float relX = config.get("positionX") != null
                    ? ((Number) config.get("positionX")).floatValue() : 0.1f;
            final float relY = config.get("positionY") != null
                    ? ((Number) config.get("positionY")).floatValue() : 0.1f;

            int parentW = getWidth();
            int parentH = getHeight();
            if (parentW == 0 || parentH == 0) {
                addOnLayoutChangeListener(new OnLayoutChangeListener() {
                    @Override
                    public void onLayoutChange(android.view.View v, int left, int top, int right, int bottom,
                                               int oldLeft, int oldTop, int oldRight, int oldBottom) {
                        removeOnLayoutChangeListener(this);
                        positionFixed(config);
                    }
                });
                return;
            }

            watermarkText.setX(relX * parentW);
            watermarkText.setY(relY * parentH);
        });
    }

    // Schedule periodic random repositioning with fade animation.
    private void startMovingAnimation() {
        moveRunnable = new Runnable() {
            @Override
            public void run() {
                animateToRandomPosition();
                handler.postDelayed(this, moveDurationMs);
            }
        };
        handler.post(moveRunnable);
    }

    private void animateToRandomPosition() {
        post(() -> {
            int parentW = getWidth();
            int parentH = getHeight();
            int textW = watermarkText.getWidth();
            int textH = watermarkText.getHeight();
            if (parentW == 0 || textW == 0) return;

            float maxX = Math.max(0f, parentW - textW - 16f);
            float maxY = Math.max(0f, parentH - textH - 16f);
            float newX = 16f + random.nextFloat() * maxX;
            float newY = 16f + random.nextFloat() * maxY;

            ObjectAnimator fadeOut = ObjectAnimator.ofFloat(watermarkText, "alpha", targetAlpha, 0f);
            fadeOut.setDuration(300);
            fadeOut.addListener(new AnimatorListenerAdapter() {
                @Override
                public void onAnimationEnd(Animator animation) {
                    watermarkText.setX(newX);
                    watermarkText.setY(newY);
                    ObjectAnimator fadeIn = ObjectAnimator.ofFloat(watermarkText, "alpha", 0f, targetAlpha);
                    fadeIn.setDuration(300);
                    fadeIn.start();
                }
            });
            fadeOut.start();
        });
    }

    public void stopAnimation() {
        if (moveRunnable != null) {
            handler.removeCallbacks(moveRunnable);
            moveRunnable = null;
        }
    }
}
