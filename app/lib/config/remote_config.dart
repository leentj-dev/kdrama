import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Ad controls driven by Firebase Remote Config. Widgets listen to these
/// notifiers, so changes take effect live (via onConfigUpdated) or on the next
/// cold start — no rebuild needed. Ported from kpop.
///
/// Remote Config keys (set them in the Firebase console for project
/// `kdrama-hangul`):
///   ads_enabled            bool   show ads at all (default true)
///   feed_ad_interval       int    scenes between feed ads (default 8, min 2)
///   native_ad_refresh_sec  int    native-ad reload seconds (default 45, min 30)

/// Whether ads should be shown. Defaults to true so ads still show if Remote
/// Config is unreachable.
final adsEnabledNotifier = ValueNotifier<bool>(true);

/// How many scenes appear between feed ads. Driven by `feed_ad_interval`.
final feedAdIntervalNotifier = ValueNotifier<int>(8);

/// Seconds between native-ad auto-refreshes. Driven by `native_ad_refresh_sec`.
final nativeAdRefreshSecNotifier = ValueNotifier<int>(45);

const _adsEnabledKey = 'ads_enabled';
const _feedAdIntervalKey = 'feed_ad_interval';
const _nativeRefreshKey = 'native_ad_refresh_sec';

/// Fetch + activate Remote Config, then publish the values. Never throws — on
/// any failure the app keeps the current (default) values.
Future<void> initRemoteConfig() async {
  try {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: Duration.zero,
    ));
    await rc.setDefaults(const {
      _adsEnabledKey: true,
      _feedAdIntervalKey: 8,
      _nativeRefreshKey: 45,
    });
    await rc.fetchAndActivate();
    _publish(rc);

    // Pick up changes pushed while the app is open.
    rc.onConfigUpdated.listen((event) async {
      await rc.activate();
      _publish(rc);
    });
  } on Exception {
    // Keep the defaults.
  }
}

void _publish(FirebaseRemoteConfig rc) {
  adsEnabledNotifier.value = rc.getBool(_adsEnabledKey);
  // Guard against a bad/zero value making every row an ad.
  final interval = rc.getInt(_feedAdIntervalKey);
  feedAdIntervalNotifier.value = interval >= 2 ? interval : 8;
  // AdMob requires >= 30s between refreshes; clamp to a safe floor.
  final refresh = rc.getInt(_nativeRefreshKey);
  nativeAdRefreshSecNotifier.value = refresh >= 30 ? refresh : 45;
}
