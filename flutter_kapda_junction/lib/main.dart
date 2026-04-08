import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection.dart';
import 'core/error/app_error_handler.dart';
import 'core/router/app_router.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/cart/cart_bloc.dart';
import 'presentation/bloc/wishlist/wishlist_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase — safe to fail if google-services.json not yet added
  try {
    await Firebase.initializeApp();
    FcmService.markReady();
    // FcmService.init() (requestPermission) is called from SplashPage
  } catch (_) {}

  await initDependencies();
  runApp(const KapdaJunctionApp());
}

class KapdaJunctionApp extends StatefulWidget {
  const KapdaJunctionApp({super.key});

  @override
  State<KapdaJunctionApp> createState() => _KapdaJunctionAppState();
}

class _KapdaJunctionAppState extends State<KapdaJunctionApp> {
  late final AuthBloc _authBloc;
  late final CartBloc _cartBloc;
  late final WishlistBloc _wishlistBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>();
    _cartBloc = sl<CartBloc>()..add(CartLoaded());
    _wishlistBloc = sl<WishlistBloc>();
    _router = createRouter(_authBloc);
    AppErrorHandler.init(rootNavigatorKey);
    FcmService.setRouteFromPushHandler((data) {
      if (_authBloc.state is! AuthAuthenticated) {
        _router.go('/login');
        return;
      }
      final screen = data['screen'] ?? '';
      if (screen == 'order') {
        final id = data['orderId'] ?? '';
        if (id.isNotEmpty) {
          _router.go('/orders/$id');
          return;
        }
        _router.go('/orders');
        return;
      }
      if (screen == 'returns') {
        _router.go('/returns');
        return;
      }
    });

    FcmService.setOpenProductHandler((productId) {
      if (_authBloc.state is! AuthAuthenticated) {
        _router.go('/login');
        return;
      }
      _router.go('/product/$productId?fromPush=1');
    });

    // Load wishlist when user authenticates
    _authBloc.stream.listen((state) {
      if (state is AuthAuthenticated) {
        _wishlistBloc.add(const WishlistLoadRequested());
        FcmService.registerToken();
      } else if (state is AuthUnauthenticated) {
        _wishlistBloc.add(const WishlistCleared());
      }
    });
  }

  @override
  void dispose() {
    _authBloc.close();
    _cartBloc.close();
    _wishlistBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _cartBloc),
        BlocProvider.value(value: _wishlistBloc),
      ],
      child: MaterialApp.router(
        title: 'Kapda Junction',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
