import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mygamemaster/pages/get_started.dart';
import 'package:mygamemaster/pages/report.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:mygamemaster/pages/theme_notifier.dart';
import 'package:mygamemaster/pages/edit_profile.dart';
import 'package:mygamemaster/pages/feedback.dart';
import 'package:mygamemaster/pages/settings.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String _userName = 'Unknown User';
  String _description = '';
  String _profileImageUrl = '';
  String _backgroundImageUrl = '';
  String _creationDate = '';
  User? _currentUser;
  bool _isLoading = true;

  // Add ScrollController
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _scrollToBottom(); // Scroll to bottom when the page loads
  }

  Future<void> _fetchUserData() async {
    try {
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['userName'] ?? 'Unknown User';
            _description = userDoc['description'] ?? 'No description available';
            _profileImageUrl = userDoc['profileImageUrl'] ?? '';
            _backgroundImageUrl = userDoc['backgroundImageUrl'] ?? '';
            _creationDate = _currentUser?.metadata.creationTime != null
                ? DateFormat('yMMMd').format(_currentUser!.metadata.creationTime!)
                : 'Unknown';
            _isLoading = false;
          });

          // Scroll to bottom after loading user data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      print('Failed to fetch user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load user data.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to auto-scroll to the bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage(String imageType) async {
    print('Opening image picker for $imageType image.');

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        String imageUrl = await _uploadImageToFirebase(imageFile, imageType);

        setState(() {
          if (imageType == 'profile') {
            _profileImageUrl = imageUrl;
          } else if (imageType == 'background') {
            _backgroundImageUrl = imageUrl;
          }
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update({
          imageType == 'profile' ? 'profileImageUrl' : 'backgroundImageUrl': imageUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${imageType.capitalize()} picture updated successfully!')),
        );
      }
    } catch (e) {
      print('Error updating image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update ${imageType.capitalize()} picture.')),
      );
    }
  }

  Future<String> _uploadImageToFirebase(File imageFile, String imageType) async {
    String folderPath = imageType == 'profile' ? 'profileImages' : 'backgroundImages';

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('$folderPath/${_currentUser!.uid}.jpg');
    await storageRef.putFile(imageFile);
    return await storageRef.getDownloadURL();
  }

  void _showChangeBackgroundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Background Picture'),
        content: const Text('Do you want to change the background picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage('background'); // Change the background picture
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController, // Attach ScrollController
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: _showChangeBackgroundDialog, // Tap to change background
                        child: _backgroundImageUrl.isNotEmpty
                            ? Image.network(
                                _backgroundImageUrl,
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/default_background.jpg',
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        bottom: -60,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 55,
                            backgroundImage: _profileImageUrl.isNotEmpty
                                ? NetworkImage(_profileImageUrl)
                                : const AssetImage('assets/images/default_avatar.jpg')
                                    as ImageProvider,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Joined: $_creationDate',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _description,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildToolsGrid(context, themeNotifier),
                ],
              ),
            ),
    );
  }

@override
Widget _buildToolsGrid(BuildContext context, ThemeNotifier themeNotifier) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
    child: Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black54 : const Color(0xFFF7F1D1), // Background color based on theme
        borderRadius: BorderRadius.circular(15.0), // Rounded corners for frame
        border: Border.all(
          color: isDarkMode ? Colors.grey : const Color(0xFF6B4226), // Dark brown border in light mode, grey in dark mode
          width: 3.0,
        ),
      ),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildToolItemSvg('assets/icons/editProfile.svg', 'Edit Profile'),
          _buildToolItemSvg('assets/icons/setting.svg', 'Settings'),
          _buildToolItemSvg('assets/icons/report.svg', 'Report'),
          _buildToolItemSvg('assets/icons/feedback.svg', 'Feedback'),
          _buildToolItemWithActionSvg(
            themeNotifier.isDarkMode ? 'assets/icons/sun.svg' : 'assets/icons/moon.svg',
            themeNotifier.isDarkMode ? 'Light Mode' : 'Dark Mode', // Dynamically change the text
            themeNotifier.toggleTheme,
          ),
          _buildToolItemWithActionSvg(
            'assets/icons/logout.svg',
            'Log Out',
            () => _logout(context),
          ),
        ],
      ),
    ),
  );
}


  // Function to build items with SVG icons
  Widget _buildToolItemSvg(String svgPath, String label) {
    return GestureDetector(
      onTap: () {
        if (label == 'Settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        } else if (label == 'Edit Profile') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditProfile()),
          );
        } else if (label == 'Feedback') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FeedbackPage()),
          );
        } else if (label == 'Report') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportPage()),
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            svgPath,
            height: 50,
            width: 50,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Function to build items with SVG icons and actions
  Widget _buildToolItemWithActionSvg(String svgPath, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            svgPath,
            height: 50,
            width: 50,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        if (label == 'Settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        } else if (label == 'Edit Profile') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditProfile()),
          );
        } else if (label == 'Feedback') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FeedbackPage()),
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 50,
            color: Colors.orange,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolItemWithAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 50,
            color: Colors.orange,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GetStartedPage()),
      );
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out. Please try again.')),
      );
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
