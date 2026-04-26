import 'package:fpdart/fpdart.dart';
import 'package:labsvpn/core/utils/exception_handler.dart';
import 'package:labsvpn/features/stats/model/stats_failure.dart';
import 'package:labsvpn/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:labsvpn/hiddifycore/hiddify_core_service.dart';
import 'package:labsvpn/utils/custom_loggers.dart';

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
