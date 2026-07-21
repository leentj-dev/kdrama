import UIKit
import GoogleMobileAds
import google_mobile_ads

/// iOS counterpart of `SceneCardNativeAdFactory.kt` — builds the compact
/// "scene row"-styled native ad for factory id "sceneCard" (`Ads.factoryId`).
///
/// Built programmatically rather than from a .xib so the layout stays in sync
/// with the Android version by reading side by side.
class SceneCardNativeAdFactory: NSObject, FLTNativeAdFactory {

  /// Matches the Android layout's accent (#F0ABFC) and row tint (#14808080).
  private static let accent = UIColor(red: 0.94, green: 0.67, blue: 0.99, alpha: 1.0)
  private static let rowTint = UIColor(white: 0.5, alpha: 0.08)

  func createNativeAd(
    _ nativeAd: GADNativeAd,
    customOptions: [AnyHashable: Any]? = nil
  ) -> GADNativeAdView? {
    let adView = GADNativeAdView()
    adView.backgroundColor = Self.rowTint

    // Icon (56x56, same as Android).
    let icon = UIImageView()
    icon.contentMode = .scaleAspectFill
    icon.clipsToBounds = true
    icon.translatesAutoresizingMaskIntoConstraints = false
    icon.image = nativeAd.icon?.image
    icon.isHidden = nativeAd.icon == nil

    // "Ad" badge — required attribution.
    let badge = UILabel()
    badge.text = " Ad "
    badge.font = .boldSystemFont(ofSize: 10)
    badge.textColor = .white
    badge.backgroundColor = Self.accent
    badge.setContentHuggingPriority(.required, for: .horizontal)

    let headline = UILabel()
    headline.font = .boldSystemFont(ofSize: 14)
    headline.numberOfLines = 1
    headline.lineBreakMode = .byTruncatingTail
    headline.text = nativeAd.headline

    let titleRow = UIStackView(arrangedSubviews: [badge, headline])
    titleRow.axis = .horizontal
    titleRow.spacing = 6
    titleRow.alignment = .center

    let body = UILabel()
    body.font = .systemFont(ofSize: 12)
    body.numberOfLines = 2
    body.lineBreakMode = .byTruncatingTail
    body.alpha = 0.7
    body.text = nativeAd.body
    body.isHidden = nativeAd.body == nil

    let textColumn = UIStackView(arrangedSubviews: [titleRow, body])
    textColumn.axis = .vertical
    textColumn.spacing = 2

    let cta = UIButton(type: .system)
    cta.setTitle(nativeAd.callToAction, for: .normal)
    cta.setTitleColor(.white, for: .normal)
    cta.titleLabel?.font = .systemFont(ofSize: 12)
    cta.backgroundColor = Self.accent
    cta.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
    cta.isHidden = nativeAd.callToAction == nil
    cta.setContentHuggingPriority(.required, for: .horizontal)
    // The SDK handles the click; the button must not swallow the touch.
    cta.isUserInteractionEnabled = false

    let row = UIStackView(arrangedSubviews: [icon, textColumn, cta])
    row.axis = .horizontal
    row.spacing = 10
    row.alignment = .center
    row.isLayoutMarginsRelativeArrangement = true
    row.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    row.translatesAutoresizingMaskIntoConstraints = false

    adView.addSubview(row)
    NSLayoutConstraint.activate([
      row.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
      row.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
      row.topAnchor.constraint(equalTo: adView.topAnchor),
      row.bottomAnchor.constraint(equalTo: adView.bottomAnchor),
      icon.widthAnchor.constraint(equalToConstant: 56),
      icon.heightAnchor.constraint(equalToConstant: 56),
    ])

    // Wiring these makes the SDK register impressions/clicks correctly.
    adView.iconView = icon
    adView.headlineView = headline
    adView.bodyView = body
    adView.callToActionView = cta
    adView.nativeAd = nativeAd

    return adView
  }
}
