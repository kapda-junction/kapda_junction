import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/storage/local_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _sheetCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _sheetFade;
  late final Animation<Offset> _sheetSlide;

  bool _minDelayDone = false;
  bool _authDone = false;
  bool _notifHandled = false;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _logoScale = Tween<double>(begin: 0.55, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _sheetCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _sheetFade = CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOut);
    _sheetSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic));

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _textCtrl.forward();
    });

    context.read<AuthBloc>().add(AuthCheckRequested());

    // If the user already responded to the permission card on a previous launch,
    // skip it entirely so we never ask again.
    final storage = sl<LocalStorage>();
    if (storage.notifPermissionShown) {
      _notifHandled = true;
      // Re-init FCM so onMessageOpenedApp + getInitialMessage are wired up on
      // every launch (not just the first time the user grants permission).
      if (storage.notifPermissionGranted) {
        FcmService.init();
      }
    } else {
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) _sheetCtrl.forward();
      });
    }

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _minDelayDone = true);
      _tryNavigate();
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  void _tryNavigate() {
    if (_minDelayDone && _authDone && _notifHandled && mounted) {
      final pushRoute = FcmService.consumeInitialRouteOverride();
      if (pushRoute != null) {
        final isAuth = context.read<AuthBloc>().state is AuthAuthenticated;
        final needsAuth = pushRoute.startsWith('/orders') || pushRoute.startsWith('/returns');
        context.go(needsAuth && !isAuth ? '/login' : pushRoute);
      } else {
        context.go('/');
      }
    }
  }

  Future<void> _handleNotif(bool allow) async {
    await sl<LocalStorage>().saveNotifPermission(granted: allow);
    if (allow) await FcmService.init();
    if (!mounted) return;
    await _sheetCtrl.reverse();
    setState(() => _notifHandled = true);
    _tryNavigate();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthUnauthenticated) {
          _authDone = true;
          _tryNavigate();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF080F1E),
        body: Stack(
          children: [
            // ── Background gradient ─────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F1B2D), Color(0xFF060D18)],
                ),
              ),
            ),

            // ── Amber glow behind logo ──────────────────────────────
            Positioned(
              top: size.height * 0.18,
              left: size.width / 2 - 100,
              child: FadeTransition(
                opacity: _logoFade,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withAlpha(35),
                        blurRadius: 90,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Main content ────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo card
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(120),
                              blurRadius: 40,
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: AppColors.accent.withAlpha(55),
                              blurRadius: 50,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Image.asset(
                            'assets/images/kapda_junction_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.accent,
                              child: const Icon(Icons.checkroom, size: 56, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Brand name + tagline
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          const Text(
                            'KAPDA JUNCTION',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 3.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 44,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "MEN'S FASHION & LIFESTYLE",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withAlpha(140),
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Bottom progress bar
                  FadeTransition(
                    opacity: _logoFade,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 72),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withAlpha(15),
                          color: AppColors.accent.withAlpha(200),
                          minHeight: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                ],
              ),
            ),

            // ── Notification permission card ────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _sheetSlide,
                child: FadeTransition(
                  opacity: _sheetFade,
                  child: _NotifCard(
                    onAllow: () => _handleNotif(true),
                    onSkip: () => _handleNotif(false),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  const _NotifCard({required this.onAllow, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 50,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accent.withAlpha(30),
                  AppColors.accent.withAlpha(15),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              size: 34,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Stay in the Loop!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Allow notifications to get updates on\nnew arrivals, deals & your orders.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onAllow,
              icon: const Icon(Icons.notifications_none_rounded, size: 20, color: Colors.white),
              label: const Text(
                'Allow Notifications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Not Now',
              style: TextStyle(fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
