import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';
import 'package:book_event/Routes/AppRoute.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Fade animation setup
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start the process
    _startLoadingSequence();
  }

  Future<void> _startLoadingSequence() async {
    // Wait for 6 seconds (adjust as needed)
    await Future.delayed(const Duration(seconds: 6));

    // Start fade out animation
    await _animationController.forward();

    // Navigate after animation completes
    Get.offNamed(AppRoute.login);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.grey[900]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Lottie.asset(
              'assets/animations/startup_animation.json',
              width: 200,
              height: 200,
              controller: _animationController,
              onLoaded: (composition) {
                // Optional: Sync Lottie animation duration
                _animationController.duration = composition.duration;
              },
            ),
          ),
        ),
      ),
    );
  }
}