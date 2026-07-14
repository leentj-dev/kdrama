import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../config/theme_controller.dart';
import '../config/remote_config.dart';
import '../data/scene_repository.dart';
import '../models/scene.dart';
import '../utils/ads.dart';
import '../utils/themes.dart';
import '../widgets/native_ad_card.dart';
import 'scene_screen.dart';

/// Home screen: the list of drama scenes. Ported from kpop's FeedScreen —
/// bundled scenes shown instantly, GitHub sync fills in new ones in the
/// background.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _repo = SceneRepository();
  List<SceneSummary> _scenes = [];
  bool _loading = true;
  String _lang = 'english';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('ui_lang') ?? 'english';
    final scenes = await _repo.loadManifest();
    if (!mounted) return;
    setState(() {
      _scenes = scenes;
      _loading = false;
    });
    final updated = await _repo.syncRemote();
    if (updated != null && mounted) setState(() => _scenes = updated);
  }

  Future<void> _setLang(String lang) async {
    setState(() => _lang = lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ui_lang', lang);
  }

  Future<void> _openScene(SceneSummary summary) async {
    final scene = await _repo.loadScene(summary.id);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SceneScreen(
          scene: scene,
          lang: _lang,
          onLangChanged: _setLang,
          repo: _repo,
        ),
      ),
    );
  }

  /// Feed rows: scenes with an ad slot (null) inserted after every
  /// [feedAdIntervalNotifier] scenes (Remote Config). No ad slots when ads are
  /// disabled remotely.
  List<SceneSummary?> get _rows {
    final out = <SceneSummary?>[];
    final interval = feedAdIntervalNotifier.value;
    final adsOn = adsEnabledNotifier.value;
    for (var i = 0; i < _scenes.length; i++) {
      out.add(_scenes[i]);
      if (adsOn && (i + 1) % interval == 0 && i != _scenes.length - 1) {
        out.add(null);
      }
    }
    return out;
  }

  int get _rowCount => _rows.length;

  Widget _buildRow(BuildContext context, int i) {
    final row = _rows[i];
    if (row == null) return NativeAdCard(adUnitId: Ads.feedUnitId);
    return _SceneTile(scene: row, onTap: () => _openScene(row));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appConfig.appTitle),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (context, mode, _) => IconButton(
              icon: Icon(mode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded),
              onPressed: () => setThemeMode(
                  mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final updated = await _repo.syncRemote();
                if (updated != null && mounted) {
                  setState(() => _scenes = updated);
                }
              },
              child: ValueListenableBuilder<int>(
                valueListenable: feedAdIntervalNotifier,
                builder: (context, _, __) => ValueListenableBuilder<bool>(
                  valueListenable: adsEnabledNotifier,
                  builder: (context, ___, ____) => ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _rowCount,
                    itemBuilder: _buildRow,
                  ),
                ),
              ),
            ),
    );
  }
}

class _SceneTile extends StatelessWidget {
  final SceneSummary scene;
  final VoidCallback onTap;
  const _SceneTile({required this.scene, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = sceneThemeFor(scene.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(gradient: theme.gradient),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _Thumbnail(youtubeId: scene.youtubeId, theme: theme),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scene.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${scene.drama} · ${scene.wordCount} words',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

/// YouTube thumbnail for a scene, with a play overlay. Falls back to a plain
/// play tile if the image can't load (offline, missing thumbnail).
class _Thumbnail extends StatelessWidget {
  final String youtubeId;
  final SceneTheme theme;
  const _Thumbnail({required this.youtubeId, required this.theme});

  @override
  Widget build(BuildContext context) {
    const w = 124.0, h = 70.0; // 16:9
    Widget fallback() => Container(
          width: w,
          height: h,
          color: Colors.black26,
          child: Icon(Icons.play_arrow_rounded, color: theme.accent),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            'https://img.youtube.com/vi/$youtubeId/mqdefault.jpg',
            width: w,
            height: h,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback(),
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : fallback(),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
