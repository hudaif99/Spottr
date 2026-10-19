import 'package:spottr/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/datasources/local_database_service.dart';
import 'home_screen.dart';
import 'onboarding/onboarding_flow_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          final isCompleted = GetIt.I<LocalDatabaseService>()
              .isOnboardingCompleted();
          final destination = isCompleted
              ? const HomeScreen()
              : const OnboardingFlowScreen();

          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, _, _) => destination,
              transitionDuration: const Duration(milliseconds: 400),
              transitionsBuilder: (_, animation, _, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/ic/spottr_icon.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Spottr',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: context.accentForeground,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
