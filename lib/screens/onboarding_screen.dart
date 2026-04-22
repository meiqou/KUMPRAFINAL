import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'rider_login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _current = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Kumpra Market',
      'desc': 'Buy groceries in clusters and save on delivery fees.',
      'image': 'assets/images/onboarding1.png'
    },
    {
      'title': 'Hyper-Local',
      'desc': 'Coordinate with your neighbors for a more efficient shopping experience.',
      'image': 'assets/images/onboarding2.png'
    },
    {
      'title': 'Fast Delivery',
      'desc': 'Bacolod\'s community-driven delivery system at your doorstep.',
      'image': 'assets/images/onboarding3.png'
    },
  ];

  void _next() {
    if (_current < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _showRoleSelection();
    }
  }

  void _showRoleSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome to Kumpra',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select how you want to use the app',
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('CONTINUE AS CUSTOMER'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RiderLoginScreen()),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: AppColors.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'LOG IN AS RIDER',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (v) => setState(() => _current = v),
            itemCount: _pages.length,
            itemBuilder: (_, i) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image placeholder
                const Icon(Icons.shopping_bag_outlined, size: 120, color: AppColors.primary),
                const SizedBox(height: 40),
                Text(
                  _pages[i]['title']!,
                  style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _pages[i]['desc']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 32,
            right: 32,
            child: Column(
              children: [
                SmoothPageIndicator(
                  controller: _controller,
                  count: _pages.length,
                  effect: const ExpandingDotsEffect(
                    activeDotColor: AppColors.primary,
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _current == _pages.length - 1 ? 'GET STARTED' : 'NEXT',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
