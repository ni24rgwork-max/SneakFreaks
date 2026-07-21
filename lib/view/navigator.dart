import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/view/bag/bag_screen.dart';
import 'package:sneakers_app/view/home/home_screen.dart';
import 'package:sneakers_app/view/profile/profile_screen.dart';
import 'package:sneakers_app/widget/theme_switcher.dart';

class MainNavigator extends ConsumerStatefulWidget {
  const MainNavigator({super.key});

  @override
  ConsumerState<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends ConsumerState<MainNavigator> {
  static const _initialTab = int.fromEnvironment('TAB');

  final PageController _pageController =
      PageController(initialPage: _initialTab);
  int _selectedIndex = _initialTab;

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
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _selectedIndex = i),
            children: _screens,
          ),
          // Comparison affordance while the two brand directions are still
          // being evaluated. Delete once a palette is chosen.
          const Positioned(right: 10, top: 6, child: ThemeSwitcher()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Bag',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
