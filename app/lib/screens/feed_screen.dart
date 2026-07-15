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

  /// Which drama the feed is filtered to. null = show all dramas.
  String? _dramaFilter;

  /// Distinct drama names, in the order they appear in the (pre-sorted) feed.
  List<String> get _dramas {
    final seen = <String>[];
    for (final s in _scenes) {
      if (!seen.contains(s.drama)) seen.add(s.drama);
    }
    return seen;
  }

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('ui_lang') ?? 'english';
    _dramaFilter = prefs.getString('drama_filter');
    final scenes = await _repo.loadManifest();
    if (!mounted) return;
    setState(() {
      _scenes = scenes;
      // Drop a stale filter if that drama is no longer present.
      if (_dramaFilter != null && !_dramas.contains(_dramaFilter)) {
        _dramaFilter = null;
      }
      _loading = false;
    });
    final updated = await _repo.syncRemote();
    if (updated != null && mounted) setState(() => _scenes = updated);
  }

  Future<void> _setDramaFilter(String? drama) async {
    setState(() => _dramaFilter = drama);
    final prefs = await SharedPreferences.getInstance();
    if (drama == null) {
      await prefs.remove('drama_filter');
    } else {
      await prefs.setString('drama_filter', drama);
    }
  }

  Future<void> _setLang(String lang) async {
    setState(() => _lang = lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ui_lang', lang);
  }

  String _langLabel(String code) => uiLanguages
      .firstWhere((l) => l.code == code,
          orElse: () => uiLanguages.first)
      .label;

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

  /// Feed rows. Each entry is one of:
  ///   String        → a drama section header
  ///   SceneSummary  → a scene tile
  ///   null          → an ad slot (every [feedAdIntervalNotifier] scenes)
  /// Scenes come pre-sorted by drama then episode order, so headers mark where
  /// one drama's block starts.
  List<Object?> get _rows {
    final out = <Object?>[];
    final interval = feedAdIntervalNotifier.value;
    final adsOn = adsEnabledNotifier.value;
    // When a single drama is selected the filter chip already names it, so the
    // in-list header is redundant; show headers only in the "All" view.
    final showHeaders = _dramaFilter == null;
    String? drama;
    var sceneCount = 0;
    for (final s in _scenes) {
      if (_dramaFilter != null && s.drama != _dramaFilter) continue;
      if (showHeaders && s.drama != drama) {
        drama = s.drama;
        out.add(s.drama);
      }
      out.add(s);
      sceneCount++;
      if (adsOn && sceneCount % interval == 0) out.add(null);
    }
    return out;
  }

  int get _rowCount => _rows.length;

  Widget _buildRow(BuildContext context, int i) {
    final row = _rows[i];
    if (row == null) return NativeAdCard(adUnitId: Ads.feedUnitId);
    if (row is String) return _DramaHeader(drama: row);
    final scene = row as SceneSummary;
    return _SceneTile(scene: scene, onTap: () => _openScene(scene));
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
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
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              initialValue: _lang,
              onSelected: _setLang,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              offset: const Offset(0, 44),
              itemBuilder: (context) => [
                for (final l in uiLanguages)
                  PopupMenuItem(
                    value: l.code,
                    child: Row(
                      children: [
                        Icon(
                          l.code == _lang
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 18,
                          color: l.code == _lang
                              ? const Color(0xFFF0ABFC)
                              : onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 10),
                        Text(l.label, style: TextStyle(color: onSurface)),
                      ],
                    ),
                  ),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: onSurface.withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.language_rounded,
                        size: 16, color: onSurface.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      _langLabel(_lang),
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: onSurface.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: _dramas.length > 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: _DramaFilterBar(
                  dramas: _dramas,
                  selected: _dramaFilter,
                  onSelected: _setDramaFilter,
                ),
              )
            : null,
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

/// Horizontal drama filter pinned under the app bar: "All" + one chip per
/// drama. Lets the user jump straight to a drama instead of scrolling past a
/// long block of another. Scrolls horizontally as more dramas are added.
class _DramaFilterBar extends StatelessWidget {
  final List<String> dramas;
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _DramaFilterBar({
    required this.dramas,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;
    Widget chip(String label, bool active, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: active,
            onSelected: (_) => onTap(),
            showCheckmark: false,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? accent : onSurface.withValues(alpha: 0.75),
            ),
            side: BorderSide(
              color: active
                  ? accent.withValues(alpha: 0.6)
                  : onSurface.withValues(alpha: 0.18),
            ),
            backgroundColor: Colors.transparent,
            selectedColor: accent.withValues(alpha: 0.15),
          ),
        );
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          chip('All', selected == null, () => onSelected(null)),
          for (final d in dramas)
            chip(d, selected == d, () => onSelected(d)),
        ],
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
                    Row(
                      children: [
                        if (scene.episodeLabel.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.accent.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(scene.episodeLabel,
                                style: TextStyle(
                                    color: theme.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(scene.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${scene.wordCount} words',
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

/// Section header naming the drama a block of scenes belongs to. As more
/// dramas are added, each gets its own titled block of episode-ordered scenes.
class _DramaHeader extends StatelessWidget {
  final String drama;
  const _DramaHeader({required this.drama});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Row(
        children: [
          Text(drama,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          const Expanded(child: Divider()),
        ],
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
