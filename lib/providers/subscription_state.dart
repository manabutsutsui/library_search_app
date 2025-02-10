import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, AsyncValue<bool>>((ref) {
  return SubscriptionNotifier();
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<bool>> {
  SubscriptionNotifier() : super(AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPro = customerInfo.entitlements.active.containsKey('sa_399_1m');
      state = AsyncValue.data(isPro);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> checkSubscription() async {
    state = const AsyncValue.loading();
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPro = customerInfo.entitlements.active.containsKey('sa_399_1m');
      state = AsyncValue.data(isPro);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
