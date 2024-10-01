import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:mygamemaster/pages/login.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black,  // Set text color to black for readability without a background color
        fontFamily: 'MedievalSharp',
      ),
      bodyTextStyle: TextStyle(
        fontSize: 20,
        color: Colors.black87,  // Slightly lighter black for body text
        fontFamily: 'Merriweather',
        height: 1.5,  // Increased line height for readability
      ),
      imagePadding: EdgeInsets.all(24),  // Added padding to image
      pageColor: Colors.transparent,
    );

    return Scaffold(
      body: IntroductionScreen(
        pages: [
          PageViewModel(
            title: "Welcome to AI GAME MASTER",
            body: "Your ultimate tool to create and manage TRPG experiences with ease.",
            image: Center(
              child: Image.asset(
                'assets/images/welcome.png',
                width: 300,
                fit: BoxFit.contain,  // Adjusted image fit to prevent squishing
              ),
            ),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Create Immersive Worlds",
            body: "Design your own maps, characters, and stories to captivate your players.",
            image: Center(
              child: Image.asset(
                'assets/images/world_building.png',
                width: 300,
                fit: BoxFit.contain,  // Adjusted image fit to prevent squishing
              ),
            ),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "AI-Powered Storytelling",
            body: "Leverage AI to generate dynamic and responsive narratives on the fly.",
            image: Center(
              child: Image.asset(
                'assets/images/ai_storytelling.png',
                width: 300,
                fit: BoxFit.contain,  // Adjusted image fit to prevent squishing
              ),
            ),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Get Started Now",
            body: "Sign up and start your journey into the world of AI-driven TRPG.",
            image: Center(
              child: Image.asset(
                'assets/images/get_started.png',
                width: 300,
                fit: BoxFit.contain,  // Adjusted image fit to prevent squishing
              ),
            ),
            decoration: pageDecoration,
          ),
        ],
        onDone: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },
        onSkip: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },
        showSkipButton: true,
        skip: const Text(
          'Skip',
          style: TextStyle(color: Colors.black87, fontFamily: 'Merriweather'),
        ),
        next: const Icon(
          Icons.navigate_next,
          color: Colors.black,
          size: 28,  // Slightly larger icon
        ),
        done: const Text(
          "Done",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontFamily: 'Merriweather'),
        ),
        dotsDecorator: DotsDecorator(
          size: const Size.square(10.0),
          activeSize: const Size(20.0, 10.0),
          activeColor: Colors.black,
          color: Colors.black26,
          spacing: const EdgeInsets.symmetric(horizontal: 3.0),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        animationDuration: 300,
      ),
    );
  }
}
