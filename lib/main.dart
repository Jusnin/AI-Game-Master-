import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mygamemaster/pages/auth_page.dart';
import 'package:mygamemaster/pages/profile.dart';
import 'package:mygamemaster/pages/profile_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/login.dart';
import 'pages/register.dart';
import 'pages/forgot_pass.dart';
import 'pages/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'AI Game Master',
          theme: _buildLightTheme(), // Apply light theme
          darkTheme: _buildDarkTheme(), // Apply dark theme
          themeMode:
              themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AuthPage(),
          routes: {
            '/profile': (context) => const Profile(),
            '/registration': (context) => const RegistrationPage(),
            '/login': (context) => const LoginPage(),
            '/forgot_pass': (context) => const ForgotPassPage(),
          },
        );
      },
    );
  }

  // Define light theme
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF6B4226), // Deep brown color
      scaffoldBackgroundColor:
          const Color(0xFFF3E5AB), // Parchment-like background
      fontFamily: 'MedievalSharp', // TRPG font
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF6B4226),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'MedievalSharp',
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: Colors.brown,
          fontFamily: 'MedievalSharp',
        ),
        bodyMedium: TextStyle(
          color: Colors.brown,
          fontFamily: 'MedievalSharp',
        ),
        displayLarge: TextStyle(
          fontFamily: 'MedievalSharp',
          color: Color(0xFF6B4226),
          fontSize: 26,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 4.0, color: Colors.black38, offset: Offset(2, 2))
          ],
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontFamily: 'MedievalSharp',
          fontSize: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          backgroundColor: const Color(0xFF6B4226), // Button color
          foregroundColor: Colors.white,
          shape: BeveledRectangleBorder(
            // Use BeveledRectangleBorder for sharp angles
            borderRadius:
                BorderRadius.circular(10), // Adjust for a sharp medieval look
          ),
          elevation: 6, // Add depth with elevation
          shadowColor: Colors.black54, // Subtle shadow
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        labelStyle: const TextStyle(color: Color(0xFF6B4226)), // Label color
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6B4226)),
        ),
      ),
      // Add TabBar theme for consistent tab styling
      tabBarTheme: const TabBarTheme(
        labelColor: Color.fromARGB(255, 254, 254, 254), // Active tab color
        unselectedLabelColor:
            Color.fromARGB(255, 0, 0, 0), // Inactive tab color
        labelStyle: TextStyle(
          fontFamily: 'MedievalSharp',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'MedievalSharp',
          fontSize: 16,
        ),
        indicator: UnderlineTabIndicator(
          borderSide:
              BorderSide(color: Color.fromARGB(255, 255, 255, 255), width: 2.0),
        ),
      ),
      // Add Radio Button theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all<Color>(
            const Color(0xFF6B4226)), // Radio button color
      ),
    );
  }

  // Define dark theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF4A536B),
      scaffoldBackgroundColor: const Color(0xFF1C1C1C),
      fontFamily: 'MedievalSharp',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4A536B),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'MedievalSharp',
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: Colors.white70,
          fontFamily: 'MedievalSharp',
        ),
        bodyMedium: TextStyle(
          color: Colors.white60,
          fontFamily: 'MedievalSharp',
        ),
        displayLarge: TextStyle(
          fontFamily: 'MedievalSharp',
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 4.0, color: Colors.black87, offset: Offset(2, 2))
          ],
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontFamily: 'MedievalSharp',
          fontSize: 16,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          backgroundColor: const Color(0xFF4A536B), // Button color
          shape: BeveledRectangleBorder(
            // Use BeveledRectangleBorder for sharp angles
            borderRadius:
                BorderRadius.circular(10), // Adjust for a sharp medieval look
          ),
          elevation: 6, // Add depth with elevation
          shadowColor: Colors.black54, // Subtle shadow
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blueGrey[400]!),
        ),
      ),
      // Add TabBar theme for consistent tab styling
      tabBarTheme: const TabBarTheme(
        labelColor: Colors.white, // Active tab color
        unselectedLabelColor: Colors.white70, // Inactive tab color
        labelStyle: TextStyle(
          fontFamily: 'MedievalSharp',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'MedievalSharp',
          fontSize: 16,
        ),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: Colors.white, width: 2.0),
        ),
      ),
      // Add Radio Button theme for dark mode
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all<Color>(Colors.blueGrey[400]!),
      ),
    );
  }
}
