import 'dart:ui';

import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nyro/core/app_info/app_info_provider.dart';
import 'package:nyro/core/localization/translations.dart';
import 'package:nyro/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:nyro/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:nyro/features/connection/notifier/connection_notifier.dart';
import 'package:nyro/features/home/widget/connection_button.dart';
import 'package:nyro/features/profile/model/profile_entity.dart';
import 'package:nyro/features/profile/notifier/active_profile_notifier.dart';
import 'package:nyro/features/profile/widget/profile_tile.dart';
import 'package:nyro/features/proxy/active/active_proxy_card.dart';
import 'package:nyro/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:nyro/gen/assets.gen.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final activeProfile = ref.watch(activeProfileProvider);
    final isDesktop = Breakpoint(context).isDesktop();

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Row(
                children: [
                  Assets.images.logo.svg(height: 24),
                  const Gap(8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: t.common.appTitle),
                        const TextSpan(text: " "),
                        const WidgetSpan(child: AppVersionLabel(), alignment: PlaceholderAlignment.middle),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                Semantics(
                  key: const ValueKey("profile_add_button"),
                  label: t.pages.profiles.add,
                  child: IconButton(
                    icon: Icon(Icons.add_rounded, color: theme.colorScheme.primary),
                    onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(),
                  ),
                ),
                const Gap(8),
              ],
            ),
      body: isDesktop ? _MacosHomeBody(activeProfile: activeProfile) : _LegacyHomeBody(activeProfile: activeProfile),
    );
  }
}

class _LegacyHomeBody extends ConsumerWidget {
  const _LegacyHomeBody({required this.activeProfile});

  final AsyncValue<ProfileEntity?> activeProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/world_map.png'),
          fit: BoxFit.cover,
          opacity: 0.09,
          colorFilter: theme.brightness == Brightness.dark
              ? ColorFilter.mode(Colors.white.withValues(alpha: .15), BlendMode.srcIn)
              : ColorFilter.mode(Colors.grey.withValues(alpha: 1), BlendMode.srcATop),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: CustomScrollView(
                slivers: [
                  MultiSliver(
                    children: [
                      switch (activeProfile) {
                        AsyncData(value: final profile?) => ProfileTile(
                          profile: profile,
                          isMain: true,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Theme.of(context).colorScheme.surfaceContainer,
                        ),
                        _ => const Text(""),
                      },
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [ConnectionButton(), ActiveProxyDelayIndicator()],
                              ),
                            ),
                            ActiveProxyFooter(),
                            Gap(32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (ref.watch(hasAnyProfileProvider).value ?? false)
            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Material(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    child: InkWell(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      onTap: () => ref.read(bottomSheetsNotifierProvider.notifier).showQuickSettings(),
                      child: Container(
                        height: 32,
                        padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t.pages.home.quickSettings),
                            const Gap(4),
                            const Icon(Icons.arrow_drop_up_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MacosHomeBody extends ConsumerWidget {
  const _MacosHomeBody({required this.activeProfile});

  final AsyncValue<ProfileEntity?> activeProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final hasAnyProfile = ref.watch(hasAnyProfileProvider).value ?? false;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF101114) : const Color(0xFFF5F5F7)),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/world_map.png'),
                  fit: BoxFit.cover,
                  opacity: isDark ? .04 : .065,
                  colorFilter: ColorFilter.mode(
                    isDark ? Colors.white.withValues(alpha: .18) : Colors.blueGrey.withValues(alpha: .68),
                    BlendMode.srcATop,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(44, 34, 44, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MacosHomeHeader(
                    title: t.pages.home.title,
                    connectionLabel: connectionStatus.valueOrNull?.present(t) ?? '',
                    profileName: activeProfile.valueOrNull?.name,
                  ),
                  const SizedBox(height: 26),
                  Expanded(
                    child: _MacosHomeContent(activeProfile: activeProfile, hasAnyProfile: hasAnyProfile),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacosHomeContent extends StatelessWidget {
  const _MacosHomeContent({required this.activeProfile, required this.hasAnyProfile});

  final AsyncValue<ProfileEntity?> activeProfile;
  final bool hasAnyProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 560;
        final profileToControlGap = isCompact ? 18.0 : 34.0;
        final controlToFooterGap = isCompact ? 14.0 : 24.0;

        return SingleChildScrollView(
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(bottom: 2),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: _ProfileStatusSlot(activeProfile: activeProfile),
                ),
                SizedBox(height: profileToControlGap),
                const ConnectionButton(),
                const Gap(10),
                const ActiveProxyDelayIndicator(),
                SizedBox(height: controlToFooterGap),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: isDark ? .18 : .08),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 660),
                    child: const ActiveProxyFooter(),
                  ),
                ),
                if (hasAnyProfile) ...[const SizedBox(height: 12), const _QuickSettingsDock()],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MacosHomeHeader extends ConsumerWidget {
  const _MacosHomeHeader({required this.title, required this.connectionLabel, required this.profileName});

  final String title;
  final String connectionLabel;
  final String? profileName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (connectionLabel.isNotEmpty) connectionLabel,
                  profileName ?? t.dialogs.noActiveProfile.title,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileStatusSlot extends StatelessWidget {
  const _ProfileStatusSlot({required this.activeProfile});

  final AsyncValue<ProfileEntity?> activeProfile;

  @override
  Widget build(BuildContext context) {
    return switch (activeProfile) {
      AsyncData(value: final profile?) => ProfileTile(profile: profile, isMain: true),
      AsyncLoading() => const _LoadingProfileStatusCard(),
      _ => const _EmptyProfileStatusCard(),
    };
  }
}

class _EmptyProfileStatusCard extends ConsumerWidget {
  const _EmptyProfileStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return _StatusSurface(
      child: Row(
        children: [
          const _StatusIcon(icon: Icons.person_add_alt_1_rounded),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.dialogs.noActiveProfile.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  t.pages.profiles.add,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: Text(t.common.add),
          ),
        ],
      ),
    );
  }
}

class _LoadingProfileStatusCard extends StatelessWidget {
  const _LoadingProfileStatusCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _StatusSurface(
      child: Row(
        children: [
          const _StatusIcon(icon: Icons.autorenew_rounded),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 180,
                  height: 15,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 280,
                  height: 10,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSurface extends StatelessWidget {
  const _StatusSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: isDark ? .54 : .78),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: isDark ? .38 : .58)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: isDark ? .24 : .08),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(padding: const EdgeInsets.all(18), child: child),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: scheme.primary, size: 24),
    );
  }
}

class _QuickSettingsDock extends ConsumerWidget {
  const _QuickSettingsDock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = ref.watch(translationsProvider).requireValue;
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: isDark ? .58 : .72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: isDark ? .34 : .62)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: isDark ? .22 : .12),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _DockItem(
              label: t.pages.home.quickSettings,
              icon: Icons.tune_rounded,
              onTap: () => ref.read(bottomSheetsNotifierProvider.notifier).showQuickSettings(),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 14, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: scheme.primary, size: 23),
                ),
                const Gap(10),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.common.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
        ),
      ),
    );
  }
}
