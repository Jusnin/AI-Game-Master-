import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  _AccountManagementPageState createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _usernameController.text = _currentUser!.displayName ?? '';
      _emailController.text = _currentUser!.email ?? '';
    }
  }

  Future<void> _reauthenticateUser() async {
    try {
      if (_currentUser != null) {
        final credential = EmailAuthProvider.credential(
          email: _currentUser!.email!,
          password: _currentPasswordController.text,
        );

        // Reauthenticate the user
        await _currentUser!.reauthenticateWithCredential(credential);

        // If successful, proceed to update the profile
        await _updateProfile();
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reauthentication failed: ${e.message}')),
      );
    }
  }

  Future<void> _updateProfile() async {
    try {
      if (_currentUser != null) {
        // Update display name
        await _currentUser!.updateDisplayName(_usernameController.text);

        // Update email
        await _currentUser!.updateEmail(_emailController.text);

        // Update password if the user entered a new one
        if (_passwordController.text.isNotEmpty) {
          await _currentUser!.updatePassword(_passwordController.text);
        }

        // Reload the user to ensure changes are reflected
        await _currentUser!.reload();
        _currentUser = _auth.currentUser;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account details updated successfully')),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black87 : const Color(0xFFF3E5AB); 

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black54 : Colors.brown[300], 
        title: const Text(
          'Account Management',
          style: TextStyle(fontFamily: 'MedievalSharp', fontSize: 20),
        ),
        centerTitle: true,
      ),
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Account Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'MedievalSharp', 
              ),
            ),
            const SizedBox(height: 20),

            // Username field
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.brown[800],
                  fontFamily: 'MedievalSharp',
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.blueGrey[300]! : Colors.brown[400]!,
                  ),
                ),
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.brown[800]),
            ),
            const SizedBox(height: 20),

            // Email field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.brown[800],
                  fontFamily: 'MedievalSharp',
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.blueGrey[300]! : Colors.brown[400]!,
                  ),
                ),
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.brown[800]),
            ),
            const SizedBox(height: 20),

            // New password field
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.brown[800],
                  fontFamily: 'MedievalSharp',
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.blueGrey[300]! : Colors.brown[400]!,
                  ),
                ),
              ),
              obscureText: true,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.brown[800]),
            ),
            const SizedBox(height: 20),

            // Current password field
            TextFormField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.brown[800],
                  fontFamily: 'MedievalSharp',
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.blueGrey[300]! : Colors.brown[400]!,
                  ),
                ),
              ),
              obscureText: true,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.brown[800]),
            ),
            const SizedBox(height: 30),

            // Save changes button
            ElevatedButton(
              onPressed: _reauthenticateUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.blueGrey[800] : Colors.brown[700], 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontFamily: 'MedievalSharp', 
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
