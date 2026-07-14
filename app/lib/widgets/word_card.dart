import 'package:flutter/material.dart';

import '../models/scene.dart';
import '../utils/themes.dart';

/// A vocabulary card — the same unit kpop teaches, sourced from a drama scene.
///
/// Shows one key word (emoji, part of speech, the word, romanization,
/// translation) and an original example sentence. The example is written for
/// the app, never taken from the drama's dialogue (see CLAUDE.md). [onLoop]
/// replays the moment the word is heard; [onSpeak] reads the word aloud;
/// [onTap] seeks the video to it.
class WordCard extends StatelessWidget {
  final WordEntry word;
  final String lang;
  final SceneTheme theme;
  final bool active;
  final bool looping;
  final VoidCallback? onSpeak;
  final VoidCallback? onLoop;
  final VoidCallback? onTap;

  const WordCard({
    super.key,
    required this.word,
    required this.lang,
    required this.theme,
    this.active = false,
    this.looping = false,
    this.onSpeak,
    this.onLoop,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: active ? 0.14 : 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? theme.accent : Colors.white24,
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (word.emoji.isNotEmpty)
                  Text(word.emoji, style: const TextStyle(fontSize: 30))
                else
                  const SizedBox(width: 30),
                if (word.partOfSpeech.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(word.partOfSpeech,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70)),
                  ),
              ],
            ),
            const Spacer(),
            // The word.
            Text(
              word.korean,
              style: const TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              word.romanization,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: theme.accent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              word.translation(lang),
              style: const TextStyle(fontSize: 20, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            // Playback controls for the moment the word is heard.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onLoop,
                  icon: Icon(
                    looping ? Icons.repeat_on_rounded : Icons.repeat_rounded,
                    color: looping ? theme.accent : Colors.white54,
                  ),
                  tooltip: 'Replay in the scene',
                ),
                IconButton(
                  onPressed: onSpeak,
                  icon: Icon(Icons.volume_up_rounded, color: theme.accent),
                  tooltip: 'Listen',
                ),
              ],
            ),
            const Spacer(),
            // Original example sentence (written for the app, not the drama).
            if (word.example.isNotEmpty) ...[
              const Divider(color: Colors.white12),
              const SizedBox(height: 2),
              Text(
                word.example,
                style: const TextStyle(
                    fontSize: 17, height: 1.35, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              if (word.exampleRomanization.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  word.exampleRomanization,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: theme.accent),
                  textAlign: TextAlign.center,
                ),
              ],
              if (word.exampleTranslation.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  word.exampleTranslation,
                  style: const TextStyle(fontSize: 13.5, color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
