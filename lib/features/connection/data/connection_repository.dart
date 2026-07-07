import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/profile/data/profile_path_resolver.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:meta/meta.dart';

abstract interface class ConnectionRepository {
  SingboxConfigOption? get configOptionsSnapshot;

  TaskEither<ConnectionFailure, Unit> setup();
  Stream<ConnectionStatus> watchConnectionStatus();
  TaskEither<ConnectionFailure, Unit> connect(ProfileEntity activeProfile, bool disableMemoryLimit);
  TaskEither<ConnectionFailure, Unit> disconnect();
  TaskEither<ConnectionFailure, Unit> reconnect(ProfileEntity activeProfile, bool disableMemoryLimit);
}

class ConnectionRepositoryImpl with ExceptionHandler, InfraLogger implements ConnectionRepository {
  ConnectionRepositoryImpl({
    required this.ref,
    required this.directories,
    required this.singbox,
    required this.configOptionRepository,
    required this.profilePathResolver,
  });

  final Ref ref;

  final Directories directories;
  final HiddifyCoreService singbox;

  final ConfigOptionRepository configOptionRepository;
  final ProfilePathResolver profilePathResolver;

  SingboxConfigOption? _configOptionsSnapshot;
  @override
  SingboxConfigOption? get configOptionsSnapshot => _configOptionsSnapshot;

  bool _initialized = false;

  @override
  TaskEither<ConnectionFailure, Unit> setup() {
    if (_initialized) return TaskEither.of(unit);
    return exceptionHandler(() {
      loggy.debug("setting up singbox");

      return singbox
          .setup()
          .map((r) {
            _initialized = true;
            return r;
          })
          .mapLeft(UnexpectedConnectionFailure.new)
          .run();
    }, UnexpectedConnectionFailure.new);
  }

  @override
  Stream<ConnectionStatus> watchConnectionStatus() {
    return singbox.watchStatus().map(
      (event) => switch (event) {
        CoreStopped() => Disconnected(event.getCoreAlert()),
        CoreStarting() => const Connecting(),
        CoreStarted() => const Connected(),
        CoreStopping() => const Disconnecting(),
      },
    );
  }

  @override
  TaskEither<ConnectionFailure, Unit> connect(ProfileEntity activeProfile, bool disableMemoryLimit) =>
      TaskEither(() async {
        final setupResult = await setup().run();
        return await setupResult.match((failure) => Future.value(left(failure)), (_) async {
          final applyResult = await applyConfigOption(activeProfile).run();
          return await applyResult.match((failure) => Future.value(left(failure)), (_) async {
            final profilePath = profilePathResolver.file(activeProfile.id).path;
            final startResult = await singbox.start(profilePath, activeProfile.name, disableMemoryLimit).run();
            return await startResult.match(
              (failure) => _connectWithSanitizedRawConfig(activeProfile, disableMemoryLimit, failure).run(),
              (_) => Future.value(right(unit)),
            );
          });
        });
      });

  @override
  TaskEither<ConnectionFailure, Unit> disconnect() => singbox.stop().mapLeft(UnexpectedConnectionFailure.new);

  @override
  TaskEither<ConnectionFailure, Unit> reconnect(ProfileEntity activeProfile, bool disableMemoryLimit) =>
      applyConfigOption(activeProfile).flatMap(
        (_) => singbox
            .restart(profilePathResolver.file(activeProfile.id).path, activeProfile.name, disableMemoryLimit)
            .mapLeft(UnexpectedConnectionFailure.new),
      );

  @visibleForTesting
  TaskEither<ConnectionFailure, Unit> applyConfigOption(ProfileEntity prof) =>
      TaskEither.fromEither(configOptionRepository.fullOptionsOverrided(prof.profileOverride()))
          .mapLeft((l) => ConnectionFailure.invalidConfigOption(null, l))
          .flatMap(
            (overridedOptions) => TaskEither.tryCatch(() async {
              if (!overridedOptions.chainStatus.isOff()) {
                final isWarpLicenseAgreed = ref.read(Preferences.warpConsentGiven) == true;
                final isWarpEnabled =
                    overridedOptions.unblocker.mode.isWarp() || overridedOptions.extraSecurity.mode.isWarp();
                if (!isWarpLicenseAgreed && isWarpEnabled) {
                  final isAgreed = await ref.read(dialogNotifierProvider.notifier).showWarpLicense();
                  if (isAgreed == true) {
                    await ref.read(Preferences.warpConsentGiven.notifier).update(true);
                    // return (await applyConfigOption(prof).run()).match((l) => throw l, (_) => unit);
                  } else {
                    throw const MissingWarpLicense();
                  }
                }

                final isPsiphonLicenseAgreed = ref.read(Preferences.psiphonConsentGiven) == true;
                final isPsiphonEnabled =
                    overridedOptions.unblocker.mode.isPsiphon() || overridedOptions.extraSecurity.mode.isPsiphon();
                if (!isPsiphonLicenseAgreed && isPsiphonEnabled) {
                  final isAgreed = await ref.read(dialogNotifierProvider.notifier).showPsiphonLicense();
                  if (isAgreed == true) {
                    await ref.read(Preferences.psiphonConsentGiven.notifier).update(true);
                  } else {
                    throw const MissingPsiphonLicense();
                  }
                }
              }

              _configOptionsSnapshot = overridedOptions;
              await singbox.changeOptions(overridedOptions).run();
              return unit;
            }, (err, st) => err is ConnectionFailure ? err : ConnectionFailure.unexpected(err, st)),
          );

  TaskEither<ConnectionFailure, Unit> _connectWithSanitizedRawConfig(
    ProfileEntity activeProfile,
    bool disableMemoryLimit,
    ConnectionFailure originalFailure,
  ) {
    return TaskEither(() async {
      try {
        final profilePath = profilePathResolver.file(activeProfile.id).path;
        final fullConfigResult = await singbox.generateFullConfigByPath(profilePath).run();
        final fullConfig = await fullConfigResult.match((failure) {
          loggy.warning("error generating full config for sanitized retry", failure);
          return _readCurrentConfig();
        }, (config) => Future<String?>.value(config));
        final sanitizedConfig = fullConfig == null ? null : _sanitizeEmptyDirectDnsDetours(fullConfig);
        final fallbackConfig = sanitizedConfig ?? await _readSanitizedCurrentConfig();
        if (fallbackConfig == null) {
          loggy.warning("sanitized raw retry skipped; no patchable generated config found");
          return left(originalFailure);
        }

        final runtimeConfig = profilePathResolver.tempFile("${activeProfile.id}.runtime");
        await runtimeConfig.writeAsString(fallbackConfig);
        loggy.info("retrying connection with sanitized raw sing-box config");
        return await singbox
            .start(
              runtimeConfig.path,
              activeProfile.name,
              disableMemoryLimit,
              enableRawConfig: true,
              configContent: fallbackConfig,
            )
            .run();
      } catch (error, stackTrace) {
        loggy.warning("error retrying with sanitized raw config", error);
        loggy.debug(stackTrace);
        return left(originalFailure);
      }
    });
  }

  Future<String?> _readSanitizedCurrentConfig() async {
    final currentConfig = await _readCurrentConfig();
    if (currentConfig == null) return null;
    return _sanitizeEmptyDirectDnsDetours(currentConfig);
  }

  Future<String?> _readCurrentConfig() async {
    final currentConfig = File(directories.workingDir.uri.resolve("data/current-config.json").toFilePath());
    if (!await currentConfig.exists()) return null;
    return currentConfig.readAsString();
  }

  String? _sanitizeEmptyDirectDnsDetours(String configContent) {
    final root = jsonDecode(configContent);
    if (root is! Map<String, dynamic>) return null;

    final outbounds = root["outbounds"];
    if (outbounds is! List) return null;

    final emptyDirectTags = <String>{};
    for (final outbound in outbounds) {
      if (outbound case {"type": "direct", "tag": final String tag} when outbound.length == 2) {
        emptyDirectTags.add(tag);
      }
    }
    if (emptyDirectTags.isEmpty) return null;

    final dns = root["dns"];
    if (dns is! Map) return null;
    final servers = dns["servers"];
    if (servers is! List) return null;

    var changed = false;
    for (final server in servers) {
      if (server is Map && emptyDirectTags.contains(server["detour"])) {
        server.remove("detour");
        changed = true;
      }
    }

    if (!changed) return null;
    return const JsonEncoder.withIndent("  ").convert(root);
  }
}
