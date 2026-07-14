import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../config/app_config.dart';
import '../data/scene_repository.dart';
import '../models/scene.dart';
import '../utils/themes.dart';
import '../widgets/line_card.dart';

/// Plays a scene: the YouTube clip up top, a swipeable stack of line cards
/// below that auto-follows playback. Ported from kpop's SongScreen, with a
/// per-line loop (A–B repeat) added for listening practice.
class SceneScreen extends StatefulWidget {
  final Scene scene;
  final String lang;
  final ValueChanged<String> onLangChanged;
  final SceneRepository repo;

  const SceneScreen({
    super.key,
    required this.scene,
    required this.lang,
    required this.onLangChanged,
    required this.repo,
  });

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  late final YoutubePlayerController _player;
  late final PageController _pageController;
  final FlutterTts _tts = FlutterTts();
  Timer? _syncTimer;
  int _activeIndex = 0;
  bool _userScrolling = false;

  /// Index of the line currently on A–B repeat, or -1 for none.
  int _loopIndex = -1;

  late Scene _scene;
  late String _lang;

  /// Effective intro offset (seconds): the scene's data value plus any local
  /// user nudge. video time = line.start + offset.
  double _offset = 0;

  List<LineEntry> get _lines => _scene.lines;
  SceneTheme get _theme => sceneThemeFor(_scene.id);

  @override
  void initState() {
    super.initState();
    _scene = widget.scene;
    _lang = widget.lang;
    _loadOffset();
    _player = YoutubePlayerController.fromVideoId(
      videoId: _scene.youtubeId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: false,
        strictRelatedVideos: true,
        enableCaption: false,
      ),
    );
    _pageController = PageController(viewportFraction: 0.86);
    _tts.setLanguage(appConfig.ttsLocale);
    _syncTimer = Timer.periodic(
        const Duration(milliseconds: 400), (_) => _syncToPlayback());
  }

  Future<void> _syncToPlayback() async {
    if (!mounted) return;
    final t = await _player.currentTime;

    // A–B repeat: if a line is looping and playback passed its end, jump back.
    if (_loopIndex >= 0 && _loopIndex < _lines.length) {
      final line = _lines[_loopIndex];
      if (t >= line.end + _offset || t < line.start + _offset - 0.3) {
        _player.seekTo(
            seconds: line.start + _offset, allowSeekAhead: true);
        return;
      }
    }

    if (_userScrolling) return;
    var index = -1;
    for (var i = 0; i < _lines.length; i++) {
      if (_lines[i].start + _offset <= t) index = i;
    }
    if (index >= 0 && index != _activeIndex && mounted) {
      setState(() => _activeIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _seekToLine(int index) async {
    _player.seekTo(seconds: _lines[index].start + _offset, allowSeekAhead: true);
    setState(() => _activeIndex = index);
  }

  void _toggleLoop(int index) {
    setState(() => _loopIndex = _loopIndex == index ? -1 : index);
    if (_loopIndex == index) _seekToLine(index);
  }

  Future<void> _speak(int index) async {
    await _tts.stop();
    await _tts.speak(_lines[index].korean);
  }

  Future<void> _loadOffset() async {
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getDouble('offset_${_scene.id}');
    if (mounted) {
      setState(() => _offset = override ?? _scene.introOffset);
    }
  }

  Future<void> _nudgeOffset(double delta) async {
    final next = _offset + delta;
    setState(() => _offset = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('offset_${_scene.id}', next);
  }

  Future<void> _resetOffset() async {
    setState(() => _offset = _scene.introOffset);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offset_${_scene.id}');
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _player.close();
    _pageController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _pickLanguage() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Translation language',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            for (final l in uiLanguages)
              ListTile(
                title: Text(l.label,
                    style: const TextStyle(color: Colors.white)),
                trailing: l.code == _lang
                    ? Icon(Icons.check_rounded, color: _theme.accent)
                    : null,
                onTap: () {
                  setState(() => _lang = l.code);
                  widget.onLangChanged(l.code);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openSyncAdjust() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          void nudge(double d) {
            _nudgeOffset(d);
            setSheet(() {});
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Sync adjust',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text(
                  'If the cards run ahead of the speech, add delay (+).',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final d in [-1.0, -0.5, 0.5, 1.0])
                      OutlinedButton(
                        onPressed: () => nudge(d),
                        child: Text(d > 0 ? '+$d' : '$d'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('offset: ${_offset.toStringAsFixed(1)}s',
                    style: const TextStyle(color: Colors.white70)),
                TextButton(
                  onPressed: () {
                    _resetOffset();
                    setSheet(() {});
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    return Scaffold(
      body: YoutubePlayerControllerProvider(
        controller: _player,
        child: Container(
          decoration: BoxDecoration(gradient: theme.gradient),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_scene.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          Text(_scene.drama,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.translate_rounded,
                          color: Colors.white70),
                      onPressed: _pickLanguage,
                      tooltip: 'Translation language',
                    ),
                    IconButton(
                      icon: const Icon(Icons.sync_rounded,
                          color: Colors.white70),
                      onPressed: _openSyncAdjust,
                      tooltip: 'Sync adjust',
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: YoutubePlayer(controller: _player),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollStartNotification) _userScrolling = true;
                      if (n is ScrollEndNotification) {
                        Future.delayed(const Duration(seconds: 2),
                            () => _userScrolling = false);
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _lines.length,
                      onPageChanged: (i) => setState(() => _activeIndex = i),
                      itemBuilder: (context, i) => LineCard(
                        line: _lines[i],
                        lang: _lang,
                        theme: theme,
                        active: i == _activeIndex,
                        looping: i == _loopIndex,
                        onTap: () => _seekToLine(i),
                        onSpeak: () => _speak(i),
                        onLoop: () => _toggleLoop(i),
                      ),
                    ),
                  ),
                ),
                _ProgressDots(count: _lines.length, active: _activeIndex),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int count;
  final int active;
  const _ProgressDots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    // Cap the dot row so long scenes don't overflow.
    final show = count.clamp(0, 20);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < show; i++)
          Container(
            width: i == active ? 18 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i == active ? Colors.white : Colors.white30,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
