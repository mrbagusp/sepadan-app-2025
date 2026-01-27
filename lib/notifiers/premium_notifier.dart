import 'package:flutter/material.dart';
import 'package:sepadan/services/premium_service.dart';

class PremiumNotifier extends ChangeNotifier {
  final PremiumService _premiumService = PremiumService();
  bool _isPremium = false;

  bool get isPremium => _isPremium;

  PremiumNotifier() {
    _init();
  }

  void _init() {
    _premiumService.getPremiumStatus().listen((status) {
      _isPremium = status;
      notifyListeners();
    });
  }

  Future<void> upgradeToPremium() async {
    // This is for simulation as per step 8
    await _premiumService.updatePremiumStatus(true);
  }
}
