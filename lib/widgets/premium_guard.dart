import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sepadan/notifiers/premium_notifier.dart';
import 'package:sepadan/screens/premium/premium_upsell_screen.dart';

class PremiumGuard extends StatelessWidget {
  final Widget child;
  final String featureName;

  const PremiumGuard({
    super.key,
    required this.child,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumNotifier>(
      builder: (context, premiumNotifier, _) {
        if (premiumNotifier.isPremium) {
          return child;
        } else {
          return PremiumUpsellScreen(featureName: featureName);
        }
      },
    );
  }
}
