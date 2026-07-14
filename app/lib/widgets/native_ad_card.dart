import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/ads.dart';

/// A native AdMob ad rendered by the platform [Ads.factoryId] factory, styled
/// to look like a scene list row. Auto-refreshes and hides entirely until the
/// factory is registered / an ad loads. Used in the feed and under the word
/// deck so ads read like content, not a banner (the kpop approach).
///
/// Native ads need a platform factory registered in MainActivity for
/// [Ads.factoryId] ('sceneCard'); until then this stays hidden.
class NativeAdCard extends StatefulWidget {
  /// AdMob native unit id for this placement (feed vs word deck).
  final String adUnitId;
  const NativeAdCard({super.key, required this.adUnitId});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;
  Timer? _refreshTimer;

  static const _height = 92.0;

  @override
  void initState() {
    super.initState();
    _loadAd();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: Ads.refreshSeconds),
      (_) => _loadAd(),
    );
  }

  void _loadAd() {
    NativeAd(
      adUnitId: widget.adUnitId,
      factoryId: Ads.factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          final old = _ad;
          setState(() {
            _ad = ad as NativeAd;
            _loaded = true;
          });
          old?.dispose();
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    ).load();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    // The native layout draws its own background/border; this reserves height.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      height: _height,
      child: AdWidget(ad: _ad!),
    );
  }
}
