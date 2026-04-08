import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/wishlist/wishlist_bloc.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

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
    final currentIndex = _locationIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          final cs = Theme.of(context).colorScheme;
          return NavigationBar(
            selectedIndex: currentIndex,
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
