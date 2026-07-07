import 'package:nyro/features/connection/notifier/connection_notifier.dart';
import 'package:nyro/features/stats/data/stats_data_providers.dart';
import 'package:nyro/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:nyro/utils/custom_loggers.dart';
import 'package:nyro/utils/riverpod_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stats_notifier.g.dart';

@riverpod
class StatsNotifier extends _$StatsNotifier with AppLogger {
  @override
  Stream<SystemInfo> build() {
    ref.disposeDelay(const Duration(seconds: 10));
    final serviceRunning = ref.watch(serviceRunningProvider);
    if (serviceRunning) {
      return ref
          .watch(statsRepositoryProvider)
          .watchStats()
          .map((event) => event.getOrElse((_) => SystemInfo.create()));
    } else {
      return Stream.value(SystemInfo.create());
    }
  }
}
