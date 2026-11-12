import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// RevenueCat setup, same pattern as BijbelQuiz: public SDK keys come in at
/// build time with --dart-define (GitHub Actions secrets in CI).
///
/// Dashboard setup for Judah:
/// - entitlement `judah_pro` (RevenueCat project "Judah")
/// - offering `default` with packages `$rc_annual` ($19.99, 7-day free trial)
///   and `$rc_monthly`
/// - a paywall designed in the RevenueCat dashboard (shown by [showPaywall])
class JudahPurchases {
  JudahPurchases._();

  static const entitlement = 'judah_pro';

  // Public SDK key (safe to ship in the app); a --dart-define overrides it.
  static const _appleKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: 'appl_PReMxojoIGAEcNjkFYkfkTKZGDG',
  );
  static const _googleKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY');

  /// Debug builds without keys can unlock Pro locally, so every screen and the
  /// widgets can be tested before RevenueCat is set up.
  static bool get configured => _configured;
  static bool _configured = false;

  static Future<void> init({required void Function(bool isPro) onChange}) async {
    if (kIsWeb) return;
    final key = defaultTargetPlatform == TargetPlatform.iOS ? _appleKey : _googleKey;
    if (key.isEmpty) {
      debugPrint('RevenueCat: no key passed, running without purchases.');
      return;
    }
    await Purchases.setLogLevel(kReleaseMode ? LogLevel.error : LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(key));
    _configured = true;
    Purchases.addCustomerInfoUpdateListener((info) => onChange(_isPro(info)));
    try {
      onChange(_isPro(await Purchases.getCustomerInfo()));
    } catch (e) {
      // Offline: keep the cached Pro state.
      debugPrint('RevenueCat: customer info unavailable: $e');
    }
  }

  static bool _isPro(CustomerInfo info) =>
      info.entitlements.active.containsKey(entitlement);

  /// Shows the dashboard paywall. Returns true when the user now has Pro.
  static Future<bool> showPaywall() async {
    if (!_configured) return false;
    final result = await RevenueCatUI.presentPaywall(displayCloseButton: true);
    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      return true;
    }
    return _isPro(await Purchases.getCustomerInfo());
  }

  static Future<bool> restore() async {
    if (!_configured) return false;
    return _isPro(await Purchases.restorePurchases());
  }
}
