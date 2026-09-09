import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// TechiNews Pro, powered by RevenueCat.
///
/// One entitlement, `pro`, gates the things that cost us money or attention:
/// instant alerts (push per high-scoring story), topic alerts, and unlimited
/// saved stories (free tier keeps ten). Products live in RevenueCat, so
/// prices and trials change without an app release.
///
/// The SDK is configured once with the public key from `.env`
/// (`REVENUECAT_API_KEY`). On platforms RevenueCat does not support (web,
/// desktop) or with no key, the state is `unavailable` and every gate falls
/// back to the free tier without crashing.
enum ProStatus { unknown, unavailable, free, pro }

class ProState {
  final ProStatus status;
  final Offerings? offerings;
  final String? error;
  const ProState(this.status, {this.offerings, this.error});
  bool get isPro => status == ProStatus.pro;
  bool get canPurchase => status == ProStatus.free && offerings?.current != null;
}

class ProNotifier extends StateNotifier<ProState> {
  ProNotifier() : super(const ProState(ProStatus.unknown)) {
    _init();
  }

  static const entitlement = 'pro';
  static const freeSaveLimit = 10;

  Future<void> _init() async {
    // RevenueCat kills non-debuggable builds that carry a Test Store key
    // ("Wrong API Key" dialog). Release builds therefore need the store key
    // (goog_/appl_); debug and profile builds keep using the test key.
    final key = kReleaseMode
        ? (dotenv.maybeGet('REVENUECAT_STORE_KEY') ?? dotenv.maybeGet('REVENUECAT_API_KEY') ?? '')
        : (dotenv.maybeGet('REVENUECAT_API_KEY') ?? '');
    final supported = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    if (key.isEmpty || !supported) {
      state = const ProState(ProStatus.unavailable);
      return;
    }
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(key));
      Purchases.addCustomerInfoUpdateListener(_apply);
      final info = await Purchases.getCustomerInfo();
      final offerings = await Purchases.getOfferings();
      state = ProState(_statusOf(info), offerings: offerings);
    } catch (e) {
      state = ProState(ProStatus.unavailable, error: e.toString());
    }
  }

  ProStatus _statusOf(CustomerInfo info) => info.entitlements.active.containsKey(entitlement) ? ProStatus.pro : ProStatus.free;

  void _apply(CustomerInfo info) {
    state = ProState(_statusOf(info), offerings: state.offerings);
  }

  Future<bool> purchase(Package package) async {
    try {
      await Purchases.purchase(PurchaseParams.package(package));
      final info = await Purchases.getCustomerInfo();
      _apply(info);
      return state.isPro;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        state = ProState(state.status, offerings: state.offerings, error: e.message);
      }
      return false;
    }
  }

  Future<bool> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      _apply(info);
      return state.isPro;
    } catch (e) {
      state = ProState(state.status, offerings: state.offerings, error: e.toString());
      return false;
    }
  }

  /// Ties RevenueCat's customer to our signed-in user so entitlements follow
  /// the account across devices.
  Future<void> identify(String userId) async {
    if (state.status == ProStatus.unavailable) return;
    try {
      final result = await Purchases.logIn(userId);
      _apply(result.customerInfo);
    } catch (_) {}
  }
}

final proProvider = StateNotifierProvider<ProNotifier, ProState>((_) => ProNotifier());
final isProProvider = Provider<bool>((ref) => ref.watch(proProvider).isPro);
