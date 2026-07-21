import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sneakers_app/providers/cart_provider.dart';
import 'package:sneakers_app/theme/motion.dart';

/// Bottom-nav shell.
///
/// Replaces the `PageView` + local index. `StatefulNavigationShell` keeps a
/// separate navigator per branch, so each tab remembers its own stack.
class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          // Tapping the active tab pops that branch to its root — the standard
          // platform behaviour users expect from a bottom nav.
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            // Pulses on count change: the confirmation for adding from a
            // product page happens down here, on a different screen.
            icon: Badge.count(
              count: cartCount,
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_bag_outlined),
            ).pulse(context, trigger: cartCount),
            selectedIcon: Badge.count(
              count: cartCount,
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_bag),
            ).pulse(context, trigger: cartCount),
            label: 'Bag',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
