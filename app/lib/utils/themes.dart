import 'package:flutter/material.dart';

/// Per-scene color themes (ported from kpop's SongTheme). A scene gets a stable
/// gradient chosen from its id, so the same scene always looks the same.
class SceneTheme {
  final Color from;
  final Color via;
  final Color accent;
  const SceneTheme(this.from, this.via, this.accent);

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [from, via, Colors.black],
      );

  /// [accent] is a light pastel tuned for the dark gradient. On a light
  /// background it washes out, so darken it for readability in light mode.
  Color accentOn(bool isDark) {
    if (isDark) return accent;
    final hsl = HSLColor.fromColor(accent);
    return hsl
        .withLightness((hsl.lightness * 0.55).clamp(0.0, 0.42))
        .withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0))
        .toColor();
  }
}

const _pool = [
  SceneTheme(Color(0xFF082F49), Color(0xFF172554), Color(0xFF7DD3FC)), // sky
  SceneTheme(Color(0xFF4C0519), Color(0xFF500724), Color(0xFFFDA4AF)), // rose
  SceneTheme(Color(0xFF083344), Color(0xFF042F2E), Color(0xFF67E8F9)), // cyan
  SceneTheme(Color(0xFF451A03), Color(0xFF422006), Color(0xFFFCD34D)), // amber
  SceneTheme(Color(0xFF4A044E), Color(0xFF3B0764), Color(0xFFF0ABFC)), // fuchsia
  SceneTheme(Color(0xFF1A2E05), Color(0xFF052E16), Color(0xFFBEF264)), // lime
  SceneTheme(Color(0xFF500724), Color(0xFF4C0519), Color(0xFFF9A8D4)), // pink
  SceneTheme(Color(0xFF022C22), Color(0xFF042F2E), Color(0xFF6EE7B7)), // emerald
  SceneTheme(Color(0xFF2E1065), Color(0xFF1E1B4B), Color(0xFFC4B5FD)), // violet
  SceneTheme(Color(0xFF431407), Color(0xFF450A0A), Color(0xFFFDBA74)), // orange
];

SceneTheme sceneThemeFor(String sceneId) =>
    _pool[sceneId.hashCode.abs() % _pool.length];
