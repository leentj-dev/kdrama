import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/scene.dart';

/// Loads bundled scene data from assets/scenes/ and keeps it up to date by
/// downloading new scenes from the GitHub repo (no backend needed).
///
/// Ported from kpop's SongRepository — same bundled + remote-sync design, same
/// content-hash change detection.
class SceneRepository {
  String get _remoteBase => appConfig.remoteBase;

  final Map<String, Scene> _cache = {};
  List<SceneSummary> _bundled = [];
  List<SceneSummary> _downloaded = [];
  Directory? _dir;

  Future<Directory> _scenesDir() async {
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/${appConfig.localDirName}');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _dir = dir;
    return dir;
  }

  List<SceneSummary> _parseManifest(String raw) =>
      (jsonDecode(raw) as List<dynamic>)
          .map((e) => SceneSummary.fromJson(e as Map<String, dynamic>))
          .toList();

  /// Bundled scenes + previously downloaded scenes.
  Future<List<SceneSummary>> loadManifest() async {
    _bundled = _parseManifest(
        await rootBundle.loadString('${appConfig.assetDir}/manifest.json'));

    final dir = await _scenesDir();
    final cached = File('${dir.path}/manifest.json');
    if (cached.existsSync()) {
      try {
        final remote = _parseManifest(cached.readAsStringSync());
        _downloaded = remote
            .where((s) => File('${dir.path}/${s.id}.json').existsSync())
            .toList();
      } on FormatException {
        _downloaded = [];
      }
    }
    return _merged();
  }

  /// Downloaded entries override bundled ones with the same id.
  List<SceneSummary> _merged() {
    final map = {for (final s in _bundled) s.id: s};
    for (final s in _downloaded) {
      map[s.id] = s;
    }
    final list = map.values.toList();
    // Most recently added first; fall back to drama title for equal order.
    list.sort((a, b) {
      if (a.order != b.order) return b.order.compareTo(a.order);
      return a.drama.compareTo(b.drama);
    });
    return list;
  }

  bool _changed(SceneSummary local, SceneSummary remote) {
    if (local.hash.isNotEmpty || remote.hash.isNotEmpty) {
      return local.hash != remote.hash;
    }
    return local.wordCount != remote.wordCount ||
        local.youtubeId != remote.youtubeId;
  }

  /// Checks GitHub for new or updated scenes and downloads them.
  /// Returns the updated list if anything changed, null otherwise.
  Future<List<SceneSummary>?> syncRemote() async {
    try {
      final res = await http
          .get(Uri.parse('$_remoteBase/manifest.json'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final remote = _parseManifest(utf8.decode(res.bodyBytes));

      final dir = await _scenesDir();
      final local = {
        for (final s in _bundled) s.id: s,
        for (final s in _downloaded) s.id: s,
      };
      var fetched = 0;
      for (final summary in remote) {
        final known = local[summary.id];
        if (known != null && !_changed(known, summary)) continue;
        final scene = await http
            .get(Uri.parse('$_remoteBase/${summary.id}.json'))
            .timeout(const Duration(seconds: 10));
        if (scene.statusCode != 200) continue;
        final body = utf8.decode(scene.bodyBytes);
        jsonDecode(body); // validate before persisting
        File('${dir.path}/${summary.id}.json').writeAsStringSync(body);
        _cache.remove(summary.id);
        // Scene data changed; drop any local sync-offset override tuned to the
        // old data so the freshly downloaded introOffset applies.
        (await SharedPreferences.getInstance()).remove('offset_${summary.id}');
        fetched++;
      }
      if (fetched == 0) return null;

      File('${dir.path}/manifest.json')
          .writeAsStringSync(utf8.decode(res.bodyBytes));
      _downloaded = remote
          .where((s) => File('${dir.path}/${s.id}.json').existsSync())
          .toList();
      return _merged();
    } on Exception {
      return null; // offline or GitHub unreachable — bundled scenes still work
    }
  }

  Future<Scene> loadScene(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;

    String raw;
    final dir = await _scenesDir();
    final file = File('${dir.path}/$id.json');
    if (file.existsSync()) {
      raw = file.readAsStringSync();
    } else {
      raw = await rootBundle.loadString('${appConfig.assetDir}/$id.json');
    }
    final scene = Scene.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _cache[id] = scene;
    return scene;
  }
}
