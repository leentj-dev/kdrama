import 'package:flutter_test/flutter_test.dart';

import 'package:kdrama_hangul/models/scene.dart';

void main() {
  test('Scene parses words and falls back to English translation', () {
    final scene = Scene.fromJson({
      'id': 'x',
      'title': 'T',
      'drama': 'D',
      'youtubeId': 'y',
      'words': [
        {'korean': '눈', 'english': 'snow', 'timestamp': 8.5},
      ],
    });
    expect(scene.words.length, 1);
    expect(scene.words.first.korean, '눈');
    // Unset language falls back to English.
    expect(scene.words.first.translation('spanish'), 'snow');
  });
}
