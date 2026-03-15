import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdService {
  InterstitialAd? _interstitialAd;
  int _swipeCount = 0;
  final int _adThreshold = 12; // Tampilkan iklan setiap 12 swipe

  // 🔥 ID Unit Iklan Interstitial
  final String interstitialAdUnitId = kDebugMode 
      ? 'ca-app-pub-3940256099942544/1033173712' // ID Test Universal Google (Gunakan saat development)
      : 'ca-app-pub-9089827400048785/1652254717'; // 👆 ID Unit Iklan Asli Anda

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('AdMob: Interstitial Ad Loaded');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          debugPrint('AdMob: Failed to load Interstitial Ad: $error');
        },
      ),
    );
  }

  void showInterstitialAdIfEligible(bool isPremium) {
    if (isPremium) {
      debugPrint('AdMob: User is Premium, skipping ads.');
      return;
    }

    _swipeCount++;
    debugPrint('AdMob: Swipe Count $_swipeCount / $_adThreshold');

    if (_swipeCount >= _adThreshold) {
      if (_interstitialAd != null) {
        _interstitialAd!.show();
        _swipeCount = 0;
        loadInterstitialAd(); // Load iklan baru untuk putaran berikutnya
      } else {
        debugPrint('AdMob: Ad not ready, retrying load...');
        loadInterstitialAd(); 
      }
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
