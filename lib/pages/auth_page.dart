// lib/pages/auth_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mygamemaster/pages/get_started.dart';
import 'package:mygamemaster/pages/mainscreen.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Check if the user is logged in
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While waiting for the authentication state, show a loading indicator
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData) {
          // If the user is logged in, show the homepage
          return const MainScreen();
        } else {
          // If the user is not logged in, show the login page
          return const GetStartedPage();
        }
      },
    );
  }
}
