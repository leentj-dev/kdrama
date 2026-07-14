import 'dart:io';

/// AdMob configuration (kpop-style placement: between feed rows + under the
/// word deck), using native ads.
///
/// These are the app's REAL AdMob ad unit IDs. Do NOT click these ads on your
/// own device — AdMob flags self-clicks as invalid traffic and can suspend the
/// account. During development, register your device as a test device (see
/// MobileAds test-device config) so it shows test ads instead.
///
/// Native ads require a platform-registered ad factory. The Flutter side asks
/// for factory id [factoryId]; register a matching `NativeAdFactory` in
/// MainActivity / AppDelegate for that id.
class Ads {
  Ads._();

  // App IDs (for AndroidManifest.xml / iOS Info.plist — not used at runtime).
  static const appIdAndroid = 'ca-app-pub-6232115093331648~8797899562';
  static const appIdIos = 'ca-app-pub-6232115093331648~8334865134';

  // Native ad units — separate unit per placement.
  static const _feedAndroid = 'ca-app-pub-6232115093331648/8606327879';
  static const _feedIos = 'ca-app-pub-6232115093331648/3082538454';
  static const _deckAndroid = 'ca-app-pub-6232115093331648/4697918164';
  static const _deckIos = 'ca-app-pub-6232115093331648/4802814235';

  /// Insert an ad after every N scenes in the feed.
  static const feedInterval = 8;

  /// Platform native-ad factory id to register in MainActivity / AppDelegate.
  static const factoryId = 'sceneCard';

  /// How often the native ad reloads (seconds).
  static const refreshSeconds = 45;

  /// Native ad unit shown between feed rows.
  static String get feedUnitId => Platform.isIOS ? _feedIos : _feedAndroid;

  /// Native ad unit shown under the word deck.
  static String get deckUnitId => Platform.isIOS ? _deckIos : _deckAndroid;
}
