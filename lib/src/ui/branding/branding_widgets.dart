import 'package:flutter/material.dart';

/// Premium Logo widget using the generated app logo.
class PremiumLogo extends StatelessWidget {
  final double size;
  const PremiumLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'lib/src/ui/branding/logo.png',
          package: 'imad_flutter',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.menu_book_rounded, size: size * 0.6, color: Colors.gold);
          },
        ),
      ),
    );
  }
}

/// Premium Branded Splash Screen (Issue #56).
class BrandedSplash extends StatefulWidget {
  final VoidCallback onFinish;
  const BrandedSplash({super.key, required this.onFinish});

  @override
  State<BrandedSplash> createState() => _BrandedSplashState();
}

class _BrandedSplashState extends State<BrandedSplash> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.elasticOut)),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 1), widget.onFinish);
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
      backgroundColor: const Color(0xFF004D40), // Deep Green
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PremiumLogo(size: 180),
              const SizedBox(height: 32),
              const Text(
                'إتقان',
                style: TextStyle(
                  color: Color(0xFFFFD700), // Gold
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
              const Text(
                'Etqan Mushaf',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
