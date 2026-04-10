import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/product.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/cart/cart_page.dart';
import '../../presentation/pages/checkout/checkout_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/orders/order_detail_page.dart';
import '../../presentation/pages/orders/orders_page.dart';
import '../../presentation/pages/products/product_detail_page.dart';
import '../../presentation/pages/products/product_reviews_page.dart';
import '../../presentation/pages/products/products_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/profile/size_guide_page.dart';
import '../../presentation/pages/returns/returns_page.dart';
import '../../presentation/pages/profile/addresses_page.dart';
import '../../presentation/pages/search/search_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/wishlist/wishlist_page.dart';
import '../../presentation/widgets/common/main_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authBloc.state is AuthAuthenticated;
      final loc = state.matchedLocation;
      if (loc == '/splash') return null;
      if (loc == '/login' || loc == '/register') return isAuth ? '/' : null;
      if (!isAuth && (loc == '/checkout' || loc == '/orders' ||
          loc == '/profile' || loc == '/wishlist' || loc == '/returns')) {
        return '/login';
      }
      return null;
    },
    refreshListenable: GoRouterAuthNotifier(authBloc),
    routes: [
      GoRoute(path: '/splash',   builder: (c, s) => const SplashPage()),
      GoRoute(path: '/login',    builder: (c, s) => const LoginPage()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterPage()),
      GoRoute(
        path: '/product/:id/reviews',
        builder: (c, s) => ProductReviewsPage(
          productId: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (c, s) => ProductDetailPage(
          productId: s.pathParameters['id']!,
          initialProduct: s.extra is Product ? s.extra as Product : null,
          openedFromPush: s.uri.queryParameters['fromPush'] == '1',
        ),
      ),
      GoRoute(
        path: '/share/product/:id',
        builder: (c, s) => ProductDetailPage(
          productId: s.pathParameters['id']!,
          openedFromPush: true,
        ),
      ),
      GoRoute(path: '/checkout', builder: (c, s) => const CheckoutPage()),
      GoRoute(path: '/size-guide', builder: (c, s) => const SizeGuidePage()),
      GoRoute(path: '/addresses', builder: (c, s) => const AddressesPage()),
      GoRoute(
        path: '/orders/:id',
        builder: (c, s) => OrderDetailPage(orderId: s.pathParameters['id']!),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (c, s, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/',         builder: (c, s) => const HomePage()),
          GoRoute(path: '/wishlist', builder: (c, s) => const WishlistPage()),
          GoRoute(path: '/search',   builder: (c, s) => const SearchPage()),
          GoRoute(path: '/cart',     builder: (c, s) => const CartPage()),
          GoRoute(path: '/orders',   builder: (c, s) => const OrdersPage()),
          GoRoute(path: '/returns',   builder: (c, s) => const ReturnsPage()),
          GoRoute(path: '/profile',  builder: (c, s) => const ProfilePage()),
          GoRoute(
            path: '/products',
            builder: (c, s) => ProductsPage(
              categoryId: s.uri.queryParameters['category'],
              initialSearch: s.uri.queryParameters['search'],
            ),
          ),
        ],
      ),
    ],
  );
}

class GoRouterAuthNotifier extends ChangeNotifier {
  final AuthBloc _authBloc;
  GoRouterAuthNotifier(this._authBloc) {
    _authBloc.stream.listen((_) => notifyListeners());
  }
}
