import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:labsvpn/core/localization/translations.dart';
import 'package:labsvpn/core/model/constants.dart';
import 'package:labsvpn/core/router/adaptive_layout/shell_route_action.dart';
import 'package:labsvpn/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:labsvpn/core/router/go_router/routing_config_notifier.dart';
import 'package:labsvpn/core/theme/moky_colors.dart';
import 'package:labsvpn/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyAdaptiveLayout extends HookConsumerWidget {
  const MyAdaptiveLayout({
    super.key,
    required this.navigationShell,
    required this.isMobileBreakpoint,
    required this.showProfilesAction,
  });
  final StatefulNavigationShell navigationShell;
  final bool isMobileBreakpoint;
  final bool showProfilesAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final mc = MokyThemeData.of(context);

    final primaryFocusHash = useState<int?>(null);
    final navScopeNode = useFocusScopeNode();
    useEffect(() {
      bool handler(KeyEvent event) {
        final arrows = isMobileBreakpoint ? KeyboardConst.verticalArrows : KeyboardConst.horizontalArrows;
        if (!arrows.contains(event.logicalKey)) return false;
        if (event is KeyDownEvent) {
          primaryFocusHash.value = FocusManager.instance.primaryFocus?.hashCode;
        } else {
          if (primaryFocusHash.value == FocusManager.instance.primaryFocus?.hashCode) {
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
        backgroundColor: mc.bg,
        body: isMobileBreakpoint
            ? navigationShell
            : Row(
                children: [
                  FocusScope(
                    node: navScopeNode,
                    child: NavigationRail(
                      extended: Breakpoint(context).isDesktop(),
                      backgroundColor: mc.bg,
                      destinations: _navRailDests(_actions(t, showProfilesAction, isMobileBreakpoint), mc),
                      selectedIndex: navigationShell.currentIndex,
                      onDestinationSelected: (index) => _onTap(context, index),
                      trailing: Breakpoint(context).isDesktop()
                          ? const Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: SizedBox(width: 220, child: SideBarStatsOverview()),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Expanded(child: navigationShell),
                ],
              ),
        bottomNavigationBar: _MokyBottomNav(
          mc: mc,
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => _onTap(context, index),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  List<ShellRouteAction> _actions(Translations t, bool showProfilesAction, bool isMobileBreakpoint) => [
    ShellRouteAction(Icons.lock_outline, 'VPN'),
    ShellRouteAction(Icons.settings_outlined, 'Настройки'),
    if (!isMobileBreakpoint) ShellRouteAction(Icons.info_rounded, t.pages.about.title),
  ];

  List<NavigationRailDestination> _navRailDests(List<ShellRouteAction> actions, MokyThemeData mc) =>
      actions.map((e) => NavigationRailDestination(
        icon: Icon(e.icon, color: mc.t3),
        selectedIcon: Icon(e.icon, color: mc.accent),
        label: Text(e.title),
      )).toList();
}

// ── Custom bottom nav matching HTML design ──
class _MokyBottomNav extends StatelessWidget {
  const _MokyBottomNav({required this.mc, required this.currentIndex, required this.onTap});
  final MokyThemeData mc;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66 + MediaQuery.of(context).viewPadding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom, left: 4, right: 4),
      decoration: BoxDecoration(
        color: mc.bg.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: mc.b1)),
      ),
      child: ClipRect(
        child: Row(
          children: [
            _NavItem(
              icon: Icons.lock_outline,
              activeIcon: Icons.lock,
              label: 'VPN',
              isActive: currentIndex == 0,
              mc: mc,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Настройки',
              isActive: currentIndex == 1,
              mc: mc,
              onTap: () => onTap(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.mc,
    required this.onTap,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final MokyThemeData mc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? mc.accentDim : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive ? mc.accent : mc.t3,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: isActive ? mc.accent : mc.t3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
