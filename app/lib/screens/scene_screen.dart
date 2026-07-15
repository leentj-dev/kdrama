import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../config/app_config.dart';
import '../data/scene_repository.dart';
import '../models/scene.dart';
import '../utils/ads.dart';
import '../utils/themes.dart';
import '../widgets/native_ad_card.dart';
import '../widgets/word_card.dart';

/// Plays a scene: the YouTube clip up top, a swipeable stack of word cards
/// below that auto-follows playback. Ported from kpop's SongScreen, with a
/// per-word loop (replay the moment the word is heard) for listening practice.
class SceneScreen extends StatefulWidget {
  final Scene scene;
  final String lang;
  final ValueChanged<String> onLangChanged;
  final SceneRepository repo;

  /// Scenes to auto-advance through (the list the user tapped from, in order).
  /// When the current clip ends, the next one in this list loads automatically.
  final List<SceneSummary> playlist;

  /// Index of [scene] within [playlist].
  final int index;

  const SceneScreen({
    super.key,
    required this.scene,
    required this.lang,
    required this.onLangChanged,
    required this.repo,
    this.playlist = const [],
    this.index = 0,
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

  /// Index of the word currently being replayed, or -1 for none.
  int _loopIndex = -1;

  /// How long a word-replay loop runs from the word's timestamp (seconds).
  static const double _loopWindow = 4.0;

  late Scene _scene;
  late String _lang;

  /// Position in [widget.playlist]; drives auto-advance to the next scene.
  late int _index;

  /// Guards against firing the next-scene load more than once per clip end.
  bool _advancing = false;

  /// Effective intro offset (seconds): the scene's data value plus any local
  /// user nudge. video time = word.timestamp + offset.
  double _offset = 0;

  List<WordEntry> get _words => _scene.words;
  SceneTheme get _theme => sceneThemeFor(_scene.id);

  @override
  void initState() {
    super.initState();
    _scene = widget.scene;
    _lang = widget.lang;
    _index = widget.index;
    _offset = _scene.introOffset;
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

    // Clip finished → auto-advance to the next scene in the playlist.
    if (_player.value.playerState == PlayerState.ended && !_advancing) {
      _playNext();
      return;
    }

    final t = await _player.currentTime;

    // Word replay: loop a short window from the word's timestamp.
    if (_loopIndex >= 0 && _loopIndex < _words.length) {
      final ts = _words[_loopIndex].timestamp;
      if (ts != null) {
        final start = ts + _offset;
        if (t >= start + _loopWindow || t < start - 0.3) {
          _player.seekTo(seconds: start, allowSeekAhead: true);
          return;
        }
      }
    }

    if (_userScrolling) return;
    var index = -1;
    for (var i = 0; i < _words.length; i++) {
      final ts = _words[i].timestamp;
      if (ts != null && ts + _offset <= t) index = i;
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

  /// Loads the next scene in the playlist and starts it, so a finished clip
  /// rolls straight into the next episode/scene (in-place, no new screen).
  Future<void> _playNext() async {
    if (_advancing) return;
    final next = _index + 1;
    if (next >= widget.playlist.length) return; // end of the list
    _advancing = true;
    try {
      final scene = await widget.repo.loadScene(widget.playlist[next].id);
      if (!mounted) return;
      setState(() {
        _index = next;
        _scene = scene;
        _offset = scene.introOffset;
        _activeIndex = 0;
        _loopIndex = -1;
        _userScrolling = false;
      });
      await _player.loadVideoById(videoId: scene.youtubeId);
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    } finally {
      _advancing = false;
    }
  }

  Future<void> _seekToWord(int index) async {
    final ts = _words[index].timestamp;
    if (ts != null) {
      _player.seekTo(seconds: ts + _offset, allowSeekAhead: true);
    }
    setState(() => _activeIndex = index);
  }

  void _toggleLoop(int index) {
    setState(() => _loopIndex = _loopIndex == index ? -1 : index);
    if (_loopIndex == index) _seekToWord(index);
  }

  Future<void> _speak(int index) async {
    await _tts.stop();
    await _tts.speak(_words[index].korean);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _player.close();
    _pageController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _setLang(String code) {
    setState(() => _lang = code);
    widget.onLangChanged(code);
  }

  String _langLabel(String code) => uiLanguages
      .firstWhere((l) => l.code == code, orElse: () => uiLanguages.first)
      .label;

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
                    PopupMenuButton<String>(
                      initialValue: _lang,
                      onSelected: _setLang,
                      color: const Color(0xFF1C1C1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      offset: const Offset(0, 44),
                      tooltip: 'Translation language',
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
                                      ? theme.accent
                                      : Colors.white24,
                                ),
                                const SizedBox(width: 10),
                                Text(l.label,
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                      ],
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language_rounded,
                                size: 16, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              _langLabel(_lang),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18, color: Colors.white70),
                          ],
                        ),
                      ),
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
                      // Only a real finger drag counts as user scrolling —
                      // programmatic auto-sync scrolls have no dragDetails.
                      if (n is ScrollStartNotification &&
                          n.dragDetails != null) {
                        _userScrolling = true;
                      } else if (n is ScrollEndNotification) {
                        Future.delayed(const Duration(seconds: 3),
                            () => _userScrolling = false);
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _words.length,
                      onPageChanged: (i) {
                        setState(() => _activeIndex = i);
                        // A user swipe moves the video to that word's moment;
                        // auto-sync page changes (dragDetails == null) don't.
                        if (_userScrolling) _seekToWord(i);
                      },
                      itemBuilder: (context, i) => WordCard(
                        word: _words[i],
                        lang: _lang,
                        theme: theme,
                        active: i == _activeIndex,
                        looping: i == _loopIndex,
                        onTap: () => _seekToWord(i),
                        onSpeak: () => _speak(i),
                        onLoop: () => _toggleLoop(i),
                      ),
                    ),
                  ),
                ),
                _ProgressDots(count: _words.length, active: _activeIndex),
                const SizedBox(height: 4),
                // Ad under the word deck (kpop placement).
                NativeAdCard(adUnitId: Ads.deckUnitId),
                const SizedBox(height: 8),
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
