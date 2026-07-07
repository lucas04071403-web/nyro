import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nyro/core/preferences/preferences_provider.dart';
import 'package:nyro/features/connection/notifier/connection_notifier.dart';
import 'package:nyro/features/profile/data/profile_data_providers.dart';
import 'package:nyro/features/profile/data/profile_parser.dart';
import 'package:nyro/features/profile/model/profile_entity.dart';
import 'package:nyro/features/profile/notifier/active_profile_notifier.dart';
import 'package:nyro/features/settings/data/config_option_repository.dart';
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
  static const _managedByHeader = 'nyro-managed-by';
  static const _xboardSubscribeUrlHeader = 'nyro-xboard-subscribe-url';
  static const _managedByXboard = 'xboard';

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
    final account = state.valueOrNull;
    state = const AsyncLoading();
    await _clearSyncedProfilesSafely(account);
    await ref.read(sharedPreferencesProvider).requireValue.remove(_authDataKey);
    state = const AsyncData(null);
    _refreshProfileProviders();
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
      if (synced) _refreshProfileProviders();
      state = AsyncData(account);
      return synced;
    } on XboardApiException catch (error, stackTrace) {
      loggy.warning('failed to ensure Xboard profile sync', error, stackTrace);
      if (error.isUnauthorized) {
        await ref.read(sharedPreferencesProvider).requireValue.remove(_authDataKey);
        await _clearSyncedProfilesSafely(null);
        state = const AsyncData(null);
        _refreshProfileProviders();
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
          await _clearSyncedProfilesSafely(null);
          _refreshProfileProviders();
          return null;
        }
        rethrow;
      }
    });
  }

  Future<XboardAccount> _getAccountAndSyncProfile(String authData) async {
    final account = await ref.read(xboardApiClientProvider).getAccount(authData);
    final synced = await _syncActiveProfile(account);
    if (synced) _refreshProfileProviders();
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
    final profileName = _profileNameForAccount(account);
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
    final subscribeUrl = account.subscribeUrl.trim();
    return {
      _managedByHeader: _managedByXboard,
      if (subscribeUrl.isNotEmpty) _xboardSubscribeUrlHeader: subscribeUrl,
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

  Future<void> _clearSyncedProfiles(XboardAccount? account) async {
    final profiles = await _readProfiles();
    final profilesToDelete = profiles.where((profile) => _isXboardSyncedProfile(profile, account)).toList()
      ..sort((a, b) {
        if (a.active == b.active) return 0;
        return a.active ? 1 : -1;
      });

    if (profilesToDelete.isEmpty) return;
    if (profilesToDelete.any((profile) => profile.active)) {
      await ref.read(connectionNotifierProvider.notifier).abortConnection();
    }

    final repository = ref.read(profileRepositoryProvider).requireValue;
    final deletedProfileIds = <String>{};
    for (final profile in profilesToDelete) {
      final result = await repository.deleteById(profile.id, profile.active).run();
      result.match((error) => loggy.warning('failed to delete Xboard subscription profile [${profile.id}]', error), (
        _,
      ) {
        deletedProfileIds.add(profile.id);
        loggy.info('deleted Xboard subscription profile [${profile.id}]');
      });
    }

    if (deletedProfileIds.isEmpty) return;

    final remainingProfiles = await _readProfiles();
    String? activeProfileId;
    for (final profile in remainingProfiles) {
      if (profile.active) {
        activeProfileId = profile.id;
        break;
      }
    }
    await _repairDeletedProfileReferences(deletedProfileIds, activeProfileId);
    _refreshProfileProviders();
  }

  Future<void> _clearSyncedProfilesSafely(XboardAccount? account) async {
    try {
      await _clearSyncedProfiles(account);
    } catch (error, stackTrace) {
      loggy.warning('failed to clear Xboard subscription profiles', error, stackTrace);
    }
  }

  Future<List<ProfileEntity>> _readProfiles() async {
    final repository = ref.read(profileRepositoryProvider).requireValue;
    final result = await repository.watchAll().first;
    return result.match((error) {
      loggy.warning('failed to read profiles for Xboard cleanup', error);
      return <ProfileEntity>[];
    }, (profiles) => profiles);
  }

  Future<void> _repairDeletedProfileReferences(Set<String> deletedProfileIds, String? fallbackProfileId) async {
    if (deletedProfileIds.contains(ref.read(ConfigOptions.extraSecurityProfileId))) {
      await ref.read(ConfigOptions.extraSecurityProfileId.notifier).update(fallbackProfileId);
    }
    if (deletedProfileIds.contains(ref.read(ConfigOptions.unblockerProfileId))) {
      await ref.read(ConfigOptions.unblockerProfileId.notifier).update(fallbackProfileId);
    }
  }

  bool _isXboardSyncedProfile(ProfileEntity profile, XboardAccount? account) {
    if (_isMarkedXboardProfile(profile)) return true;
    if (_matchesXboardSubscribeUrl(profile, account)) return true;
    return _looksLikeLegacyXboardProfile(profile, account);
  }

  bool _isMarkedXboardProfile(ProfileEntity profile) {
    final headers = profile.populatedHeaders;
    if (headers == null) return false;

    final managedBy = headers[_managedByHeader]?.toString().trim().toLowerCase();
    if (managedBy == _managedByXboard) return true;

    final subscribeUrl = headers[_xboardSubscribeUrlHeader]?.toString().trim();
    return subscribeUrl != null && subscribeUrl.isNotEmpty;
  }

  bool _matchesXboardSubscribeUrl(ProfileEntity profile, XboardAccount? account) {
    final subscribeUrl = account?.subscribeUrl.trim();
    if (subscribeUrl == null || subscribeUrl.isEmpty) return false;

    final headerUrl = profile.populatedHeaders?[_xboardSubscribeUrlHeader]?.toString().trim();
    if (headerUrl == subscribeUrl) return true;

    return switch (profile) {
      RemoteProfileEntity(:final url) => url.trim() == subscribeUrl,
      LocalProfileEntity() => false,
    };
  }

  bool _looksLikeLegacyXboardProfile(ProfileEntity profile, XboardAccount? account) {
    if (account == null) return false;

    final profileName = _profileNameForAccount(account);
    final nameMatches = profile.name == profileName || profile.userOverride?.name == profileName;
    if (!nameMatches || profile.userOverride?.updateInterval != 6) return false;

    final headers = profile.populatedHeaders ?? {};
    return headers['connection-test-url'] == 'http://www.gstatic.com/generate_204' &&
        headers['remote-dns-address'] == 'https://1.1.1.1/dns-query' &&
        headers['direct-dns-address'] == '223.5.5.5';
  }

  String _profileNameForAccount(XboardAccount account) {
    final planName = account.plan?.name.trim();
    return planName != null && planName.isNotEmpty ? planName : 'Xboard';
  }

  void _refreshProfileProviders() {
    ref.invalidate(activeProfileProvider);
    ref.invalidate(hasAnyProfileProvider);
  }
}
