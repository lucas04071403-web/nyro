import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nyro/core/preferences/preferences_provider.dart';
import 'package:nyro/features/profile/data/profile_data_providers.dart';
import 'package:nyro/features/profile/data/profile_parser.dart';
import 'package:nyro/features/profile/model/profile_entity.dart';
import 'package:nyro/features/profile/notifier/active_profile_notifier.dart';
import 'package:nyro/features/xboard/data/xboard_providers.dart';
import 'package:nyro/features/xboard/model/xboard_models.dart';
import 'package:nyro/utils/custom_loggers.dart';

final xboardAuthNotifierProvider = StateNotifierProvider<XboardAuthNotifier, AsyncValue<XboardAccount?>>((ref) {
  return XboardAuthNotifier(ref);
});

class XboardAuthNotifier extends StateNotifier<AsyncValue<XboardAccount?>> with AppLogger {
  XboardAuthNotifier(this.ref) : super(const AsyncLoading()) {
    restore();
  }

  static const _authDataKey = 'xboard_auth_data';

  final Ref ref;

  Future<void> restore() async {
    final prefs = ref.read(sharedPreferencesProvider).requireValue;
    final authData = prefs.getString(_authDataKey);
    if (authData == null || authData.isEmpty) {
      state = const AsyncData(null);
      return;
    }
    await _loadAccount(authData, clearOnUnauthorized: true);
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final auth = await ref.read(xboardApiClientProvider).login(email: email, password: password);
      await _saveAuthAndLoadAccount(auth.authData);
    } catch (error, stackTrace) {
      loggy.warning('Xboard login failed', error, stackTrace);
      await ref.read(sharedPreferencesProvider).requireValue.remove(_authDataKey);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String emailCode,
    String? inviteCode,
  }) async {
    try {
      final client = ref.read(xboardApiClientProvider);
      var auth = await client.register(email: email, password: password, emailCode: emailCode, inviteCode: inviteCode);
      if (auth.authData.isEmpty) {
        auth = await client.login(email: email, password: password);
      }
      await _saveAuthAndLoadAccount(auth.authData);
    } catch (error, stackTrace) {
      loggy.warning('Xboard register failed', error, stackTrace);
      await ref.read(sharedPreferencesProvider).requireValue.remove(_authDataKey);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    final authData =
        state.valueOrNull?.authData ?? ref.read(sharedPreferencesProvider).requireValue.getString(_authDataKey);
    if (authData == null || authData.isEmpty) {
      state = const AsyncData(null);
      return;
    }
    await _loadAccount(authData);
  }

  Future<void> logout() async {
    await ref.read(sharedPreferencesProvider).requireValue.remove(_authDataKey);
    state = const AsyncData(null);
  }

  Future<bool> ensureActiveProfileSynced() async {
    if (await ref.read(activeProfileProvider.future) != null) return true;

    final authData =
        state.valueOrNull?.authData ?? ref.read(sharedPreferencesProvider).requireValue.getString(_authDataKey);
    if (authData == null || authData.isEmpty) return false;

    try {
      final account = state.valueOrNull?.authData == authData
          ? state.valueOrNull!
          : await ref.read(xboardApiClientProvider).getAccount(authData);
      final synced = await _syncActiveProfile(account);
      state = AsyncData(account);
      return synced;
    } on XboardApiException catch (error, stackTrace) {
      loggy.warning('failed to ensure Xboard profile sync', error, stackTrace);
      if (error.isUnauthorized) {
        await ref.read(sharedPreferencesProvider).requireValue.remove(_authDataKey);
        state = const AsyncData(null);
      }
      return false;
    } catch (error, stackTrace) {
      loggy.warning('failed to ensure Xboard profile sync', error, stackTrace);
      return false;
    }
  }

  Future<void> _loadAccount(String authData, {bool clearOnUnauthorized = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        return await _getAccountAndSyncProfile(authData);
      } on XboardApiException catch (error) {
        if (clearOnUnauthorized && error.isUnauthorized) {
          await ref.read(sharedPreferencesProvider).requireValue.remove(_authDataKey);
          return null;
        }
        rethrow;
      }
    });
  }

  Future<XboardAccount> _getAccountAndSyncProfile(String authData) async {
    final account = await ref.read(xboardApiClientProvider).getAccount(authData);
    await _syncActiveProfile(account);
    return account;
  }

  Future<void> _saveAuthAndLoadAccount(String authData) async {
    if (authData.isEmpty) throw XboardApiException('Missing authorization token');
    await ref.read(sharedPreferencesProvider).requireValue.setString(_authDataKey, authData);
    state = AsyncData(await _getAccountAndSyncProfile(authData));
  }

  Future<bool> _syncActiveProfile(XboardAccount account) async {
    if (!account.hasValidSubscription) {
      loggy.debug('Xboard subscription is not valid, skip profile sync');
      return false;
    }

    final subscribeUrl = account.subscribeUrl.trim();
    final planName = account.plan?.name.trim();
    final profileName = planName != null && planName.isNotEmpty ? planName : 'Xboard';
    final userOverride = UserOverride(name: profileName, updateInterval: 6);
    final profileHeaders = _xboardProfileHeaders(account);

    try {
      final activeProfile = await ref.read(activeProfileProvider.future);
      final repository = ref.read(profileRepositoryProvider).requireValue;

      final upsertResult = await repository
          .upsertRemote(subscribeUrl, userOverride: userOverride, profileHeaders: profileHeaders)
          .run();
      final synced = await upsertResult.match(
        (error) {
          loggy.warning('failed to sync Xboard subscription profile', error);
          return Future.value(false);
        },
        (_) async {
          if (activeProfile is RemoteProfileEntity && activeProfile.url == subscribeUrl) {
            loggy.info('Xboard subscription profile is already active');
            return true;
          }

          final profileEntry = await ref.read(profileDataSourceProvider).getByUrl(subscribeUrl);
          if (profileEntry == null) {
            loggy.warning('synced Xboard profile was not found after upsert');
            return false;
          }

          final activeResult = await repository.setAsActive(profileEntry.id).run();
          return activeResult.match(
            (error) {
              loggy.warning('failed to activate Xboard subscription profile', error);
              return false;
            },
            (_) {
              loggy.info('Xboard subscription profile activated');
              return true;
            },
          );
        },
      );
      if (synced) return true;
      return await _syncCompatibleLocalProfile(
        subscribeUrl: subscribeUrl,
        profileName: profileName,
        userOverride: userOverride,
        profileHeaders: profileHeaders,
      );
    } catch (error, stackTrace) {
      loggy.warning('failed to auto sync Xboard subscription profile', error, stackTrace);
      return await _syncCompatibleLocalProfile(
        subscribeUrl: subscribeUrl,
        profileName: profileName,
        userOverride: userOverride,
        profileHeaders: profileHeaders,
      );
    }
  }

  Map<String, dynamic> _xboardProfileHeaders(XboardAccount account) {
    return {
      'profile-update-interval': '6',
      'connection-test-url': 'http://www.gstatic.com/generate_204',
      'url-test-interval': 300,
      'remote-dns-address': 'https://1.1.1.1/dns-query',
      'remote-dns-domain-strategy': 'ipv4_only',
      'direct-dns-address': '223.5.5.5',
      'direct-dns-domain-strategy': 'ipv4_only',
      'ipv6-mode': 'ipv4_only',
      if (account.subscriptionUserInfoHeader case final subInfo?) 'subscription-userinfo': subInfo,
    };
  }

  Future<bool> _syncCompatibleLocalProfile({
    required String subscribeUrl,
    required String profileName,
    required UserOverride userOverride,
    required Map<String, dynamic> profileHeaders,
  }) async {
    try {
      final dataSource = ref.read(profileDataSourceProvider);
      final repository = ref.read(profileRepositoryProvider).requireValue;

      final existingProfile = await dataSource.getByName(profileName);
      if (existingProfile != null) {
        final activeResult = await repository.setAsActive(existingProfile.id).run();
        return activeResult.match(
          (error) {
            loggy.warning('failed to activate existing Xboard compatible profile', error);
            return false;
          },
          (_) {
            loggy.info('existing Xboard compatible profile activated');
            return true;
          },
        );
      }

      final subscription = await ref.read(xboardApiClientProvider).getSubscription(subscribeUrl);
      final compatibleContent = ProfileParser.normalizeSubscriptionLinksForCompatibleImport(subscription.content);
      final compatibleHeaders = {
        ...profileHeaders,
        if (subscription.subscriptionUserInfo case final subInfo?) 'subscription-userinfo': subInfo,
      };
      final compatibleLines = compatibleContent.split('\n').where((line) => line.trim().isNotEmpty).toList();
      final compatibleRealityLines = compatibleLines.where((line) {
        final uri = Uri.tryParse(line.trim());
        return uri?.scheme == 'vless' && uri?.queryParameters['security']?.toLowerCase() == 'reality';
      }).length;
      loggy.info(
        'Xboard compatible subscription prepared, lines: ${compatibleLines.length}, reality: $compatibleRealityLines',
      );
      if (compatibleContent.trim().isEmpty) {
        loggy.warning('Xboard compatible subscription content is empty');
        return false;
      }

      final addResult = await repository
          .addLocal(compatibleContent, userOverride: userOverride, profileHeaders: compatibleHeaders)
          .run();
      return addResult.match(
        (error) {
          loggy.warning('failed to add Xboard compatible subscription profile', error);
          return false;
        },
        (_) {
          loggy.info('Xboard compatible subscription profile added and activated');
          return true;
        },
      );
    } catch (error, stackTrace) {
      loggy.warning('failed to sync Xboard compatible subscription profile', error, stackTrace);
      return false;
    }
  }
}
