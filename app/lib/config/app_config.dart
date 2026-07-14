import 'dart:io';

import 'package:flutter/material.dart';

/// App-wide configuration. Kept as a single object (like kpop's AppConfig) so
/// a second flavor — a different target language, a different content pack —
/// can be added later by swapping this out at bootstrap.
class AppConfig {
  final String appTitle;
  final Color seedColor;

  /// Bundled asset dir for scenes, e.g. 'assets/scenes'.
  final String assetDir;

  /// Base URL for the manifest + scene files (GitHub raw, no backend).
  final String remoteBase;

  /// TTS locale for the language being learned.
  final String ttsLocale;

  final String androidPackageId;
  final String iosAppId;

  const AppConfig({
    required this.appTitle,
    required this.seedColor,
    required this.assetDir,
    required this.remoteBase,
    this.ttsLocale = 'ko-KR',
    required this.androidPackageId,
    this.iosAppId = '',
  });

  String get localDirName => assetDir.split('/').last;

  String get storeUrl => Platform.isIOS
      ? 'https://apps.apple.com/app/id$iosAppId'
      : 'https://play.google.com/store/apps/details?id=$androidPackageId';
}

/// Set once by the flavor entrypoint (main.dart) before runApp().
late AppConfig appConfig;

/// K-drama → Korean.
const kdramaConfig = AppConfig(
  appTitle: 'K-Drama Hangul',
  seedColor: Color(0xFF7DD3FC),
  assetDir: 'assets/scenes',
  remoteBase:
      'https://raw.githubusercontent.com/leentj-dev/kdrama/main/app/assets/scenes',
  ttsLocale: 'ko-KR',
  androidPackageId: 'dev.leentj.kdrama_hangul',
);

/// Languages the UI can show translations in. English is the default and the
/// fallback for every line. Codes match the fields on [LineEntry].
class UiLanguage {
  final String code;
  final String label;
  const UiLanguage(this.code, this.label);
}

const uiLanguages = <UiLanguage>[
  UiLanguage('english', 'English'),
  UiLanguage('spanish', 'Español'),
  UiLanguage('portuguese', 'Português'),
  UiLanguage('indonesian', 'Indonesia'),
  UiLanguage('japanese', '日本語'),
  UiLanguage('chinese', '简体中文'),
  UiLanguage('chinese_traditional', '繁體中文'),
  UiLanguage('thai', 'ไทย'),
  UiLanguage('french', 'Français'),
];
