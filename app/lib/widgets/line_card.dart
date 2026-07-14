import 'package:flutter/material.dart';

import '../models/scene.dart';
import '../utils/themes.dart';

/// A dialogue-line card — the drama analog of kpop's WordCard.
///
/// Shows the Korean line, its romanization, the translation in the selected
/// language, and an optional grammar note. [onSpeak] reads the line aloud;
/// [onLoop] replays just this line's video range; [onTap] seeks to its start.
class LineCard extends StatelessWidget {
  final LineEntry line;
  final String lang;
  final SceneTheme theme;
  final bool active;
  final bool looping;
  final VoidCallback? onSpeak;
  final VoidCallback? onLoop;
  final VoidCallback? onTap;

  const LineCard({
    super.key,
    required this.line,
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
    final isMemorable = line.note.contains('★');
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
                if (isMemorable)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '★ 명대사',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.accent,
                          fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  const SizedBox(height: 24),
                Row(
                  children: [
                    IconButton(
                      onPressed: onLoop,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        looping ? Icons.repeat_on_rounded : Icons.repeat_rounded,
                        color: looping ? theme.accent : Colors.white54,
                      ),
                      tooltip: 'Loop this line',
                    ),
                    IconButton(
                      onPressed: onSpeak,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.volume_up_rounded, color: theme.accent),
                      tooltip: 'Listen',
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // Korean line — the main subject of the card.
            Text(
              line.korean,
              style: const TextStyle(
                fontSize: 27,
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (line.romanization.isNotEmpty)
              Text(
                line.romanization,
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: theme.accent,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
            Text(
              line.translation(lang),
              style: const TextStyle(
                  fontSize: 18, height: 1.3, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (line.note.isNotEmpty) ...[
              const Divider(color: Colors.white12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 16, color: theme.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      line.note.replaceAll('★', '').trim(),
                      style: const TextStyle(
                          fontSize: 13, height: 1.35, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
