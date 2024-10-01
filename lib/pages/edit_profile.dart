import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'profile_provider.dart'; // Import the ProfileProvider

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  File? _imageFile;

  // Image picker function with UI update and error handling
  Future<void> _pickImage(BuildContext context) async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await profileProvider.updateProfilePicture(_imageFile!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await profileProvider.saveProfile();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile saved successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save profile: $e')),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Profile Picture Section
            Center(
              child: GestureDetector(
                onTap: () => _pickImage(context),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (profileProvider.profileImageUrl != null && profileProvider.profileImageUrl!.isNotEmpty
                          ? NetworkImage(profileProvider.profileImageUrl!)
                          : const AssetImage('assets/images/default_avatar.jpg')
                              as ImageProvider),
                  child: const Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.edit, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildListTile(
              context,
              'Name',
              profileProvider.name,
              onSave: (newValue) {
                profileProvider.updateName(newValue);
              },
            ),
            _buildListTile(
              context,
              'Gender',
              profileProvider.gender.isEmpty ? 'Not set' : profileProvider.gender,
              onTap: () => _selectGender(context),
            ),
            _buildListTile(
              context,
              'Date of Birth',
              profileProvider.dateOfBirth == null
                  ? 'Not set'
                  : DateFormat('yMMMd').format(profileProvider.dateOfBirth!),
              onTap: () => _selectDateOfBirth(context),
            ),
            _buildListTile(
              context,
              'Phone Number',
              profileProvider.phoneNumber,
              onSave: (newValue) {
                if (_validatePhoneNumber(newValue)) {
                  profileProvider.updatePhoneNumber(newValue);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid phone number')),
                  );
                }
              },
            ),
            _buildListTile(
              context,
              'Description',
              profileProvider.description,
              onSave: (newValue) {
                profileProvider.updateDescription(newValue);
              },
            ),
            _buildListTile(
              context,
              'Location',
              profileProvider.location,
              onSave: (newValue) {
                profileProvider.updateLocation(newValue);
              },
            ),
            // Add a Save button at the bottom of the screen
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await profileProvider.saveProfile();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile saved successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save profile: $e')),
                    );
                  }
                },
                child: const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String title,
    String subtitle, {
    Function(String)? onSave,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle.isEmpty ? 'Not set' : subtitle),
      trailing: const Icon(Icons.edit),
      onTap: onSave != null ? () => _showEditDialog(context, title, onSave) : onTap,
    );
  }

  // Dialog for editing text fields with pre-filled text
  void _showEditDialog(BuildContext context, String title, Function(String) onSave) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Enter your $title"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onSave(controller.text);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Validate phone number format (basic validation)
  bool _validatePhoneNumber(String phoneNumber) {
    // Basic validation: check if phone number is numeric and 10-15 characters long
    final validPhoneRegex = RegExp(r'^\d{10,15}$');
    return validPhoneRegex.hasMatch(phoneNumber);
  }

  // Select Gender
  void _selectGender(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Gender'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text('Male'),
                value: 'Male',
                groupValue: profileProvider.gender,
                onChanged: (value) {
                  profileProvider.updateGender(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile(
                title: const Text('Female'),
                value: 'Female',
                groupValue: profileProvider.gender,
                onChanged: (value) {
                  profileProvider.updateGender(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile(
                title: const Text('Other'),
                value: 'Other',
                groupValue: profileProvider.gender,
                onChanged: (value) {
                  profileProvider.updateGender(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Select Date of Birth with validation
  Future<void> _selectDateOfBirth(BuildContext context) async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != profileProvider.dateOfBirth) {
      profileProvider.updateDateOfBirth(picked);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date of birth updated!')),
      );
    }
  }
}
