/// Configuration for the native watermark overlay.
///
/// Populate this directly from an API response using [WatermarkConfig.fromApiResponse].
class WatermarkConfig {
  /// The text to display as a watermark (e.g. user email from your API).
  final String text;

  /// Opacity of the watermark text, 0.0 (invisible) to 1.0 (fully opaque).
  final double alpha;

  /// CSS-style hex color string, e.g. `'#FFFFFF'` for white.
  final String color;

  /// Font size in scale-independent pixels (sp).
  final double fontSize;

  /// When true the watermark moves to a random position every [moveDurationMs].
  final bool isMoving;

  /// Milliseconds between each repositioning when [isMoving] is true.
  final int moveDurationMs;

  /// Relative X position (0–1) when [isMoving] is false. Ignored when moving.
  final double? positionX;

  /// Relative Y position (0–1) when [isMoving] is false. Ignored when moving.
  final double? positionY;

  const WatermarkConfig({
    required this.text,
    this.alpha = 0.3,
    this.color = '#FFFFFF',
    this.fontSize = 14.0,
    this.isMoving = true,
    this.moveDurationMs = 5000,
    this.positionX,
    this.positionY,
  });

  /// Build a [WatermarkConfig] from an API response map.
  ///
  /// Expected API keys (all optional with sensible defaults):
  /// ```
  /// watermark_text           String
  /// watermark_alpha          num (0–1)
  /// watermark_color          String hex
  /// watermark_font_size      num (sp)
  /// watermark_is_moving      bool
  /// watermark_move_duration_ms  int
  /// watermark_position_x     num (0–1)
  /// watermark_position_y     num (0–1)
  /// ```
  factory WatermarkConfig.fromApiResponse(Map<String, dynamic> response) {
    return WatermarkConfig(
      text: response['watermark_text']?.toString() ?? '',
      alpha: (response['watermark_alpha'] as num?)?.toDouble() ?? 0.3,
      color: response['watermark_color']?.toString() ?? '#FFFFFF',
      fontSize: (response['watermark_font_size'] as num?)?.toDouble() ?? 14.0,
      isMoving: response['watermark_is_moving'] as bool? ?? true,
      moveDurationMs: response['watermark_move_duration_ms'] as int? ?? 5000,
      positionX: (response['watermark_position_x'] as num?)?.toDouble(),
      positionY: (response['watermark_position_y'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'text': text,
      'alpha': alpha,
      'color': color,
      'fontSize': fontSize,
      'isMoving': isMoving,
      'moveDurationMs': moveDurationMs,
      if (positionX != null) 'positionX': positionX,
      if (positionY != null) 'positionY': positionY,
    };
  }

  WatermarkConfig copyWith({
    String? text,
    double? alpha,
    String? color,
    double? fontSize,
    bool? isMoving,
    int? moveDurationMs,
    double? positionX,
    double? positionY,
  }) {
    return WatermarkConfig(
      text: text ?? this.text,
      alpha: alpha ?? this.alpha,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      isMoving: isMoving ?? this.isMoving,
      moveDurationMs: moveDurationMs ?? this.moveDurationMs,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
    );
  }
}
