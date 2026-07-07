import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nyro/core/app_info/app_info_provider.dart';
import 'package:nyro/features/xboard/data/xboard_api_client.dart';
import 'package:nyro/features/xboard/model/xboard_models.dart';

final xboardApiClientProvider = Provider<XboardApiClient>((ref) {
  return XboardApiClient(userAgent: ref.watch(appInfoProvider).requireValue.userAgent);
});

final xboardRegisterConfigProvider = FutureProvider.autoDispose<XboardRegisterConfig>((ref) {
  return ref.watch(xboardApiClientProvider).getRegisterConfig();
});
