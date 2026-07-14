import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../config/theme_controller.dart';
import '../data/scene_repository.dart';
import '../models/scene.dart';
import '../utils/themes.dart';
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
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _scenes.length,
                itemBuilder: (context, i) =>
                    _SceneTile(scene: _scenes[i], onTap: () => _openScene(_scenes[i])),
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
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.play_arrow_rounded, color: theme.accent),
              ),
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
