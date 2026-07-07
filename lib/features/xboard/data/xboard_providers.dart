import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/features/xboard/data/xboard_api_client.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final xboardApiClientProvider = Provider<XboardApiClient>((ref) {
  return XboardApiClient(userAgent: ref.watch(appInfoProvider).requireValue.userAgent);
});
