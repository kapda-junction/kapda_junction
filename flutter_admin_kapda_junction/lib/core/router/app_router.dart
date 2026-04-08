import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/pages/login/login_page.dart';
import '../../presentation/pages/dashboard/dashboard_page.dart';
import '../../presentation/pages/products/products_page.dart';
import '../../presentation/pages/products/product_form_page.dart';
import '../../presentation/pages/categories/categories_page.dart';
import '../../presentation/pages/orders/orders_page.dart';
import '../../presentation/pages/banners/banners_page.dart';
import '../../presentation/pages/options/options_page.dart';
import '../../presentation/pages/notifications/notifications_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/coupons/coupons_page.dart';
import '../../presentation/pages/returns/returns_page.dart';
import '../../presentation/pages/reviews/reviews_moderation_page.dart';
import '../../presentation/pages/inventory/inventory_page.dart';
import '../../presentation/widgets/common/admin_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: _AuthNotifier(authBloc),
    redirect: (context, state) {
      final isAuthenticated = authBloc.state.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
          GoRoute(
            path: '/products',
            builder: (_, __) => const ProductsPage(),
            routes: [
              GoRoute(path: 'new', builder: (_, __) => const ProductFormPage()),
              GoRoute(
                path: ':id/edit',
                builder: (_, state) => ProductFormPage(productId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(path: '/categories', builder: (_, __) => const CategoriesPage()),
          GoRoute(path: '/orders', builder: (_, __) => const OrdersPage()),
          GoRoute(path: '/banners', builder: (_, __) => const BannersPage()),
          GoRoute(path: '/options', builder: (_, __) => const OptionsPage()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
          GoRoute(path: '/inventory', builder: (_, __) => const InventoryPage()),
          GoRoute(path: '/coupons', builder: (_, __) => const CouponsPage()),
          GoRoute(path: '/returns', builder: (_, __) => const AdminReturnsPage()),
          GoRoute(path: '/reviews', builder: (_, __) => const ReviewsModerationPage()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),
    ],
  );
}

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(AuthBloc bloc) {
    bloc.stream.listen((_) => notifyListeners());
  }
}
