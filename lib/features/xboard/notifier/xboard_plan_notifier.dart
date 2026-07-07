import 'package:hiddify/features/xboard/data/xboard_providers.dart';
import 'package:hiddify/features/xboard/model/xboard_models.dart';
import 'package:hiddify/features/xboard/notifier/xboard_auth_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final xboardPlanOffersProvider = FutureProvider.autoDispose<List<XboardPlanOffer>>((ref) async {
  final client = ref.watch(xboardApiClientProvider);
  final authData = ref.watch(xboardAuthNotifierProvider).valueOrNull?.authData;
  try {
    return await client.getPlanOffers(authData: authData);
  } on XboardApiException catch (error) {
    if (authData != null && authData.isNotEmpty && error.isUnauthorized) {
      return client.getPlanOffers();
    }
    rethrow;
  }
});
