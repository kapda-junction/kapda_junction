import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/wishlist/wishlist_bloc.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    if (!mounted) return false;

    // Non-home tab → go to Home first.
    if (_currentIndex != 0) {
      context.go('/');
      return true;
    }

    // Home tab → show exit confirmation dialog.
    final exit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Close App?'),
        content: const Text('Are you sure you want to close the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return true;
    if (exit == true) SystemNavigator.pop();
    return true;
  }

  int _locationIndex(String location) {
    if (location.startsWith('/wishlist')) return 1;
    if (location.startsWith('/cart'))    return 2;
    if (location.startsWith('/orders'))  return 3;
    if (location.startsWith('/profile') ||
        location.startsWith('/addresses') ||
        location.startsWith('/returns')) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    _currentIndex = _locationIndex(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          final cs = Theme.of(context).colorScheme;
          return NavigationBar(
            selectedIndex: _currentIndex,
            backgroundColor: cs.surface,
            indicatorColor: cs.secondary.withAlpha(24),
            onDestinationSelected: (i) {
              switch (i) {
                case 0: context.go('/'); break;
                case 1: context.go('/wishlist'); break;
                case 2: context.go('/cart'); break;
                case 3: context.go('/orders'); break;
                case 4: context.go('/profile'); break;
              }
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BlocBuilder<WishlistBloc, WishlistState>(
                builder: (_, w) => NavigationDestination(
                  icon: Badge(
                    isLabelVisible: w.ids.isNotEmpty,
                    label: Text('${w.ids.length}'),
                    child: const Icon(Icons.favorite_border),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: w.ids.isNotEmpty,
                    label: Text('${w.ids.length}'),
                    child: const Icon(Icons.favorite),
                  ),
                  label: 'Wishlist',
                ),
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: cartState.totalItems > 0,
                  label: Text('${cartState.totalItems}'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: cartState.totalItems > 0,
                  label: Text('${cartState.totalItems}'),
                  child: const Icon(Icons.shopping_bag),
                ),
                label: 'Cart',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
