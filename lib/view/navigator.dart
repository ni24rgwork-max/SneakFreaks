import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/providers/cart_provider.dart';
import 'package:sneakers_app/view/bag/bag_screen.dart';
import 'package:sneakers_app/view/home/home_screen.dart';
import 'package:sneakers_app/view/profile/profile_screen.dart';

class MainNavigator extends ConsumerStatefulWidget {
  const MainNavigator({super.key});

  @override
  ConsumerState<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends ConsumerState<MainNavigator> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  static const _screens = [HomeScreen(), MyBagScreen(), Profile()];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // jumpToPage rather than animateToPage is deliberate: sliding through an
  // intermediate tab is disorienting. A cross-fade is the right motion here.
  void _onDestinationSelected(int index) => _pageController.jumpToPage(index);

  @override
  Widget build(BuildContext context) {
    // The badge is now possible at all because the cart is observable. Under
    // the old global list nothing could watch it.
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _selectedIndex = i),
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: cartCount,
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge.count(
              count: cartCount,
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_bag),
            ),
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
