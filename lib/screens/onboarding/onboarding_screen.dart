import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

class _OnboardData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  final List<_OnboardData> _slides = const [
    _OnboardData(
      icon: Icons.explore_rounded,
      title: 'What career is\nsuitable for me?',
      description:
          'Get AI-powered career recommendations tailored to your skills, interests and academic background.',
    ),
    _OnboardData(
      icon: Icons.bar_chart_rounded,
      title: 'Which skills do I\nneed to improve?',
      description:
          'Discover your skill gaps instantly and follow a guided roadmap of courses to close them.',
    ),
    _OnboardData(
      icon: Icons.diversity_3_rounded,
      title: 'Who can help me\nreach my goal?',
      description:
          'Connect with alumni & mentors, practice mock interviews, and land the opportunity you deserve.',
    ),
  ];

  void _next() {
    if (_page == _slides.length - 1) {
      _goToLogin();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: TextButton(
                  onPressed: _goToLogin,
                  child: const Text('Skip'),
                ),
              ),
            ),

            // Main onboarding content
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) {
                  setState(() {
                    _page = i;
                  });
                },
                itemBuilder: (context, i) {
                  final s = _slides[i];

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallHeight = constraints.maxHeight < 550;

                      final iconSize = isSmallHeight ? 140.0 : 180.0;
                      final iconPadding =
                          isSmallHeight ? 28.0 : 44.0;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: iconSize,
                                  height: iconSize,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.heroGradient,
                                    borderRadius: BorderRadius.circular(44),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withOpacity(0.28),
                                        blurRadius: 34,
                                        offset: const Offset(0, 16),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    s.icon,
                                    size: isSmallHeight ? 68 : 84,
                                    color: Colors.white,
                                  ),
                                ),

                                SizedBox(height: iconPadding),

                                Text(
                                  s.title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),

                                const SizedBox(height: 14),

                                Text(
                                  s.description,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                20,
                24,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(
                    _page == _slides.length - 1
                        ? 'Get Started'
                        : 'Next',
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