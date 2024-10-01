import 'package:flutter/material.dart';
import 'chatroom.dart'; // Ensure the path is correct

class GameCoverPage extends StatelessWidget {
  const GameCoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF4A536B) : const Color(0xFF6B4226), // Adapt to dark/light mode
        title: const Text(
          '',
          style: TextStyle(
            fontFamily: 'MedievalSharp', // TRPG-themed font
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0, // Removes shadow for a cleaner look
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1C) : const Color(0xFFF3E5AB), // Parchment-like background for light mode, dark for dark mode
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color.fromARGB(255, 36, 36, 36) : const Color(0xFFF7F1D1), // Light background for frame in light mode, dark background in dark mode
                borderRadius: BorderRadius.circular(15.0), // Rounded corners for frame
                border: Border.all(
                  color: isDarkMode ? Colors.grey : const Color(0xFF6B4226), // Dark brown border in light mode, grey in dark mode
                  width: 3.0, // Thickness of the frame
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title of the game
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Whispers of the Abandoned',
                      style: TextStyle(
                        fontFamily: 'MedievalSharp', // TRPG-themed font
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : const Color(0xFF6B4226), // Title adapts to theme
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Game description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'You stand before the gates of an old, abandoned hospital. '
                      'Tales of hauntings and sinister cults have kept this place off-limits for years, '
                      'yet something compels you to step inside. The air grows colder, and the shadows shift around you. '
                      'Is it just superstition, or is there something far more dangerous lurking inside?',
                      style: TextStyle(
                        fontFamily: 'MedievalSharp', // TRPG-themed font
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black87, // Text color adapts to theme
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Game cover image with frame
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDarkMode ? Colors.grey : const Color(0xFF6B4226), // Dark brown frame in light mode, grey in dark mode
                        width: 3.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Image.asset(
                      'assets/images/hospital.jpg', // Ensure this matches your image path
                      fit: BoxFit.cover,
                      height: 250,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // "Enter the Game" button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChatRoom()),
                      );
                    },
                    child: Text(
                      'Enter the Game',
                      style: TextStyle(
                        fontFamily: 'MedievalSharp', // TRPG-themed font
                        fontSize: 18,
                        color: isDarkMode ? Colors.black : Colors.white, // Button text adapts to theme
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
