/// One line of dialogue in a scene — the drama analog of kpop's WordEntry.
///
/// A word card teaches a single word at one timestamp; a line card teaches a
/// whole spoken line over a [start]..[end] range, so the player can loop just
/// that stretch of video for listening practice.
class LineEntry {
  final String korean;
  final String romanization;
  final String english;
  final String spanish;
  final String portuguese;
  final String indonesian;
  final String japanese;
  final String thai;
  final String french;

  /// Short learning note — a grammar/usage point for this line (honorific vs
  /// casual, a contracted form, a connective ending, …). Optional.
  final String note;

  /// Audio-relative start/end of the line, in seconds. Video time is
  /// [start] + introOffset (see [Scene.introOffset]).
  final double start;
  final double end;

  const LineEntry({
    required this.korean,
    this.romanization = '',
    this.english = '',
    this.spanish = '',
    this.portuguese = '',
    this.indonesian = '',
    this.japanese = '',
    this.thai = '',
    this.french = '',
    this.note = '',
    required this.start,
    required this.end,
  });

  factory LineEntry.fromJson(Map<String, dynamic> json) => LineEntry(
        korean: json['korean'] as String? ?? '',
        romanization: json['romanization'] as String? ?? '',
        english: json['english'] as String? ?? '',
        spanish: json['spanish'] as String? ?? '',
        portuguese: json['portuguese'] as String? ?? '',
        indonesian: json['indonesian'] as String? ?? '',
        japanese: json['japanese'] as String? ?? '',
        thai: json['thai'] as String? ?? '',
        french: json['french'] as String? ?? '',
        note: json['note'] as String? ?? '',
        start: (json['start'] as num?)?.toDouble() ?? 0,
        end: (json['end'] as num?)?.toDouble() ?? 0,
      );

  /// Translation for the given language code, falling back to English.
  String translation(String lang) {
    final value = switch (lang) {
      'spanish' => spanish,
      'portuguese' => portuguese,
      'indonesian' => indonesian,
      'japanese' => japanese,
      'thai' => thai,
      'french' => french,
      _ => english,
    };
    return value.isEmpty ? english : value;
  }
}

/// A drama scene — a single YouTube clip broken into teachable lines.
/// Mirrors kpop's Song (id / title / youtubeId / introOffset / list of units).
class Scene {
  final String id;
  final String title;

  /// The drama this scene is from (the "artist" slot in the kpop model).
  final String drama;
  final String youtubeId;

  /// Seconds the video runs ahead of the dialogue audio (channel intro, logo
  /// sting, …). Line timestamps are audio-relative, so
  /// video time = line.start + introOffset. The user can nudge it live and the
  /// override is stored per-scene on device.
  final double introOffset;

  final List<LineEntry> lines;

  const Scene({
    required this.id,
    required this.title,
    required this.drama,
    required this.youtubeId,
    this.introOffset = 0,
    required this.lines,
  });

  factory Scene.fromJson(Map<String, dynamic> json) => Scene(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        drama: json['drama'] as String? ?? '',
        youtubeId: json['youtubeId'] as String? ?? '',
        introOffset: (json['introOffset'] as num?)?.toDouble() ?? 0,
        lines: (json['lines'] as List<dynamic>? ?? [])
            .map((l) => LineEntry.fromJson(l as Map<String, dynamic>))
            .toList(),
      );
}

/// Lightweight manifest entry — enough to render the feed and detect updates,
/// without loading every line. Mirrors kpop's SongSummary.
class SceneSummary {
  final String id;
  final String title;
  final String drama;
  final String youtubeId;
  final int lineCount;

  /// When the scene was first added (unix seconds). The feed sorts descending,
  /// so the most recently added scene is on top.
  final int order;

  /// Content hash from the manifest. Any change to the scene changes it, which
  /// is how [SceneRepository] detects a scene needs re-downloading.
  final String hash;

  const SceneSummary({
    required this.id,
    required this.title,
    required this.drama,
    required this.youtubeId,
    required this.lineCount,
    this.order = 0,
    this.hash = '',
  });

  factory SceneSummary.fromJson(Map<String, dynamic> json) => SceneSummary(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        drama: json['drama'] as String? ?? '',
        youtubeId: json['youtubeId'] as String? ?? '',
        lineCount: json['lineCount'] as int? ?? 0,
        order: json['order'] as int? ?? 0,
        hash: json['hash'] as String? ?? '',
      );
}
