import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nyro/core/localization/translations.dart';
import 'package:nyro/core/model/constants.dart';
import 'package:nyro/core/router/adaptive_layout/shell_route_action.dart';
import 'package:nyro/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:nyro/core/router/go_router/routing_config_notifier.dart';
import 'package:nyro/features/stats/widget/side_bar_stats_overview.dart';
import 'package:nyro/gen/assets.gen.dart';

class MyAdaptiveLayout extends HookConsumerWidget {
  const MyAdaptiveLayout({
    super.key,
    required this.navigationShell,
    required this.isMobileBreakpoint,
    required this.showProfilesAction,
  });
  // managed by go router(Shell Route)
  final StatefulNavigationShell navigationShell;
  final bool isMobileBreakpoint;
  final bool showProfilesAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    // focus switch management
    final primaryFocusHash = useState<int?>(null);
    final navScopeNode = useFocusScopeNode();
    useEffect(() {
      bool handler(KeyEvent event) {
        final arrows = isMobileBreakpoint ? KeyboardConst.verticalArrows : KeyboardConst.horizontalArrows;
        if (!arrows.contains(event.logicalKey)) return false;
        if (event is KeyDownEvent) {
          primaryFocusHash.value = FocusManager.instance.primaryFocus.hashCode;
        } else {
          // focus node does not change => true.
          if (primaryFocusHash.value == FocusManager.instance.primaryFocus.hashCode) {
            if (branchesScope.values.any((node) => node.hasFocus)) {
              navScopeNode.requestFocus();
            } else if (navScopeNode.hasFocus) {
              branchesScope[getNameOfBranch(isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex)]
                  ?.requestFocus();
            }
          }
        }
        return true;
      }

      HardwareKeyboard.instance.addHandler(handler);
      return () {
        HardwareKeyboard.instance.removeHandler(handler);
      };
    }, [isMobileBreakpoint, showProfilesAction, navigationShell.currentIndex]);
    return Material(
      child: Scaffold(
        body: isMobileBreakpoint
            ? navigationShell
            : Row(
                children: [
                  FocusScope(
                    node: navScopeNode,
                    child: _MacosSidebar(
                      expanded: Breakpoint(context).isDesktop(),
                      sections: _desktopSections(t, showProfilesAction),
                      selectedIndex: navigationShell.currentIndex,
                      onDestinationSelected: (index) => _onTap(context, index),
                    ),
                  ),
                  Expanded(child: navigationShell),
                ],
              ),
        bottomNavigationBar: isMobileBreakpoint
            ? FocusScope(
                node: navScopeNode,
                child: NavigationBar(
                  selectedIndex: navigationShell.currentIndex <= 1 ? navigationShell.currentIndex : 0,
                  destinations: _navDests(_actions(t, showProfilesAction, isMobileBreakpoint)),
                  onDestinationSelected: (index) => _onTap(context, index),
                ),
              )
            : null,
      ),
    );
  }

  // shell route action onTap
  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  List<ShellRouteAction> _actions(Translations t, bool showProfilesAction, bool isMobileBreakpoint) => [
    ShellRouteAction(Icons.power_settings_new_rounded, t.pages.home.title),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.account_circle_rounded, t.pages.userCenter.title),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.workspace_premium_rounded, t.pages.subscription.title),
    if (showProfilesAction && !isMobileBreakpoint) ShellRouteAction(Icons.view_list_rounded, t.pages.profiles.title),
    ShellRouteAction(Icons.settings_rounded, t.pages.settings.title),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.description_rounded, t.pages.logs.title),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.info_rounded, t.pages.about.title),
  ];

  List<NavigationDestination> _navDests(List<ShellRouteAction> actions) =>
      actions.map((e) => NavigationDestination(icon: Icon(e.icon), label: e.title)).toList();

  List<_SidebarSection> _desktopSections(Translations t, bool showProfilesAction) {
    final settingsIndex = showProfilesAction ? 4 : 3;
    final logsIndex = settingsIndex + 1;
    final aboutIndex = settingsIndex + 2;

    return [
      _SidebarSection(
        title: '连接',
        items: [
          _SidebarItem(index: 0, icon: Icons.power_settings_new_rounded, title: t.pages.home.title),
          if (showProfilesAction) _SidebarItem(index: 3, icon: Icons.view_list_rounded, title: t.pages.profiles.title),
        ],
      ),
      _SidebarSection(
        title: '账户',
        items: [
          _SidebarItem(index: 1, icon: Icons.account_circle_rounded, title: t.pages.userCenter.title),
          _SidebarItem(index: 2, icon: Icons.workspace_premium_rounded, title: t.pages.subscription.title),
        ],
      ),
      _SidebarSection(
        title: '系统',
        items: [
          _SidebarItem(index: settingsIndex, icon: Icons.settings_rounded, title: t.pages.settings.title),
          _SidebarItem(index: logsIndex, icon: Icons.description_rounded, title: t.pages.logs.title),
          _SidebarItem(index: aboutIndex, icon: Icons.info_rounded, title: t.pages.about.title),
        ],
      ),
    ];
  }
}

class _MacosSidebar extends StatelessWidget {
  const _MacosSidebar({
    required this.expanded,
    required this.sections,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final bool expanded;
  final List<_SidebarSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final sidebarWidth = expanded ? 268.0 : 88.0;
    final glassColor = (isDark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest).withValues(alpha: .78);
    final borderColor = scheme.outlineVariant.withValues(alpha: isDark ? .38 : .64);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: sidebarWidth,
          decoration: BoxDecoration(
            color: glassColor,
            border: BorderDirectional(end: BorderSide(color: borderColor)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(expanded ? 20 : 14, 18, expanded ? 20 : 14, 16),
              child: Column(
                children: [
                  _SidebarBrand(expanded: expanded),
                  SizedBox(height: expanded ? 28 : 18),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final section in sections) ...[
                          if (expanded) _SidebarSectionTitle(section.title),
                          for (final item in section.items)
                            _SidebarDestination(
                              expanded: expanded,
                              item: item,
                              selected: item.index == selectedIndex,
                              onTap: () => onDestinationSelected(item.index),
                            ),
                          SizedBox(height: expanded ? 18 : 10),
                        ],
                      ],
                    ),
                  ),
                  if (expanded) const _SidebarStatsPanel() else const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        Assets.images.logo.svg(height: 30),
        if (expanded) ...[
          const SizedBox(width: 10),
          Text(
            Constants.appName,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
          ),
        ],
      ],
    );
  }
}

class _SidebarSectionTitle extends StatelessWidget {
  const _SidebarSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 7),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  const _SidebarDestination({required this.expanded, required this.item, required this.selected, required this.onTap});

  final bool expanded;
  final _SidebarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = selected ? scheme.primary : scheme.onSurfaceVariant;
    final selectedBackground = scheme.primary.withValues(alpha: theme.brightness == Brightness.dark ? .18 : .12);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: expanded ? '' : item.title,
        child: Material(
          color: selected ? selectedBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              height: 42,
              padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
              child: Row(
                mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 22, color: accent),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: selected ? scheme.primary : scheme.onSurface,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarStatsPanel extends StatelessWidget {
  const _SidebarStatsPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? .28 : .54),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .45)),
      ),
      child: const SideBarStatsOverview(),
    );
  }
}

class _SidebarSection {
  const _SidebarSection({required this.title, required this.items});

  final String title;
  final List<_SidebarItem> items;
}

class _SidebarItem {
  const _SidebarItem({required this.index, required this.icon, required this.title});

  final int index;
  final IconData icon;
  final String title;
}
