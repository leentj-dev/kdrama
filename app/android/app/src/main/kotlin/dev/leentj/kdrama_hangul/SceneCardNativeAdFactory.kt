package dev.leentj.kdrama_hangul

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

/** Builds the compact "scene row"-styled native ad for factory id "sceneCard". */
class SceneCardNativeAdFactory(private val inflater: LayoutInflater) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val adView =
            inflater.inflate(R.layout.native_ad_scenecard, null) as NativeAdView

        val headline = adView.findViewById<TextView>(R.id.ad_headline)
        headline.text = nativeAd.headline
        adView.headlineView = headline

        val body = adView.findViewById<TextView>(R.id.ad_body)
        if (nativeAd.body == null) {
            body.visibility = View.GONE
        } else {
            body.visibility = View.VISIBLE
            body.text = nativeAd.body
        }
        adView.bodyView = body

        val icon = adView.findViewById<ImageView>(R.id.ad_icon)
        if (nativeAd.icon == null) {
            icon.visibility = View.GONE
        } else {
            icon.setImageDrawable(nativeAd.icon?.drawable)
            icon.visibility = View.VISIBLE
        }
        adView.iconView = icon

        val cta = adView.findViewById<Button>(R.id.ad_cta)
        if (nativeAd.callToAction == null) {
            cta.visibility = View.GONE
        } else {
            cta.visibility = View.VISIBLE
            cta.text = nativeAd.callToAction
        }
        adView.callToActionView = cta

        adView.setNativeAd(nativeAd)
        return adView
    }
}
