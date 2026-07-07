import 'package:fpdart/fpdart.dart';
import 'package:nyro/core/utils/exception_handler.dart';
import 'package:nyro/features/stats/model/stats_failure.dart';
import 'package:nyro/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:nyro/hiddifycore/hiddify_core_service.dart';
import 'package:nyro/utils/custom_loggers.dart';

abstract interface class StatsRepository {
  Stream<Either<StatsFailure, SystemInfo>> watchStats();
}

class StatsRepositoryImpl with ExceptionHandler, InfraLogger implements StatsRepository {
  StatsRepositoryImpl({required this.singbox});

  final HiddifyCoreService singbox;

  @override
  Stream<Either<StatsFailure, SystemInfo>> watchStats() {
    return singbox.watchStats().handleExceptions(StatsUnexpectedFailure.new);
  }
}
