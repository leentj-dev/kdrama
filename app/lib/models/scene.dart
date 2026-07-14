/// A key word taught in a scene — the same copyright-safe unit kpop uses.
///
/// Copyright posture (see CLAUDE.md): we extract only individual **words** that
/// occur in the scene (words themselves aren't copyrightable) and teach each
/// with an **original** example sentence written for the app — never a line of
/// the drama's dialogue. The licensed YouTube embed carries the actual scene;
/// the app never reproduces the script as text.
class WordEntry {
  final String korean;
  final String romanization;

  // Translations of the word, into the UI language (English is the fallback).
  final String english;
  final String spanish;
  final String portuguese;
  final String indonesian;
  final String japanese;
  final String thai;
  final String french;

  final String partOfSpeech;
  final String emoji;

  /// Original example sentence using the word (written for the app).
  final String example;
  final String exampleRomanization;
  final String exampleTranslation;

  /// Seconds into the audio where the word is heard (single point, like kpop).
  /// Video time = timestamp + introOffset.
  final double? timestamp;

  const WordEntry({
    required this.korean,
    this.romanization = '',
    this.english = '',
    this.spanish = '',
    this.portuguese = '',
    this.indonesian = '',
    this.japanese = '',
    this.thai = '',
    this.french = '',
    this.partOfSpeech = '',
    this.emoji = '',
    this.example = '',
    this.exampleRomanization = '',
    this.exampleTranslation = '',
    this.timestamp,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
        korean: json['korean'] as String? ?? '',
        romanization: json['romanization'] as String? ?? '',
        english: json['english'] as String? ?? '',
        spanish: json['spanish'] as String? ?? '',
        portuguese: json['portuguese'] as String? ?? '',
        indonesian: json['indonesian'] as String? ?? '',
        japanese: json['japanese'] as String? ?? '',
        thai: json['thai'] as String? ?? '',
        french: json['french'] as String? ?? '',
        partOfSpeech: json['partOfSpeech'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '',
        example: json['example'] as String? ?? '',
        exampleRomanization: json['exampleRomanization'] as String? ?? '',
        exampleTranslation: json['exampleTranslation'] as String? ?? '',
        timestamp: (json['timestamp'] as num?)?.toDouble(),
      );

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

/// A drama scene — a YouTube clip and the key words drawn from it.
class Scene {
  final String id;
  final String title;
  final String drama;
  final String youtubeId;

  /// Seconds the video runs ahead of the dialogue audio. Video time =
  /// word.timestamp + introOffset. User can nudge it live (stored per-scene).
  final double introOffset;

  final List<WordEntry> words;

  const Scene({
    required this.id,
    required this.title,
    required this.drama,
    required this.youtubeId,
    this.introOffset = 0,
    required this.words,
  });

  factory Scene.fromJson(Map<String, dynamic> json) => Scene(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        drama: json['drama'] as String? ?? '',
        youtubeId: json['youtubeId'] as String? ?? '',
        introOffset: (json['introOffset'] as num?)?.toDouble() ?? 0,
        words: (json['words'] as List<dynamic>? ?? [])
            .map((w) => WordEntry.fromJson(w as Map<String, dynamic>))
            .toList(),
      );
}

/// Lightweight manifest entry for the feed + update detection.
class SceneSummary {
  final String id;
  final String title;
  final String drama;
  final String youtubeId;
  final int wordCount;
  final int order;
  final String hash;

  const SceneSummary({
    required this.id,
    required this.title,
    required this.drama,
    required this.youtubeId,
    required this.wordCount,
    this.order = 0,
    this.hash = '',
  });

  factory SceneSummary.fromJson(Map<String, dynamic> json) => SceneSummary(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        drama: json['drama'] as String? ?? '',
        youtubeId: json['youtubeId'] as String? ?? '',
        wordCount: json['wordCount'] as int? ?? 0,
        order: json['order'] as int? ?? 0,
        hash: json['hash'] as String? ?? '',
      );
}
