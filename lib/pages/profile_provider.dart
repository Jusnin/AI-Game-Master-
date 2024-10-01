import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ProfileProvider with ChangeNotifier {
  // Profile fields
  String _name = '';
  String _gender = '';
  DateTime? _dateOfBirth;
  String _phoneNumber = '';
  String _description = '';
  String _location = '';
  String? _profileImageUrl;

  User? _currentUser;

  ProfileProvider() {
    _loadUserData();
  }

  // Getters for profile fields
  String get name => _name;
  String get gender => _gender;
  DateTime? get dateOfBirth => _dateOfBirth;
  String get phoneNumber => _phoneNumber;
  String get description => _description;
  String get location => _location;
  String? get profileImageUrl => _profileImageUrl;

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (userDoc.exists) {
          _name = userDoc['name'] ?? '';
          _gender = userDoc['gender'] ?? '';
          _dateOfBirth = (userDoc['dateOfBirth'] as Timestamp?)?.toDate();
          _phoneNumber = userDoc['phoneNumber'] ?? '';
          _description = userDoc['description'] ?? '';
          _location = userDoc['location'] ?? '';
          _profileImageUrl = userDoc['profileImageUrl'] ?? '';
          notifyListeners();
        }
      } catch (e) {
        print("Error loading user data: $e");
      }
    }
  }

  // Save the updated profile to Firestore
  Future<void> saveProfile() async {
    if (_currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set({
          'name': _name,
          'gender': _gender,
          'dateOfBirth': _dateOfBirth != null ? Timestamp.fromDate(_dateOfBirth!) : null,
          'phoneNumber': _phoneNumber,
          'description': _description,
          'location': _location,
          'profileImageUrl': _profileImageUrl,
        }, SetOptions(merge: true));
        notifyListeners();
      } catch (e) {
        print("Error saving profile: $e");
      }
    }
  }

  // Update profile picture in Firebase Storage and Firestore
  Future<void> updateProfilePicture(File image) async {
    if (_currentUser != null) {
      try {
        // Upload image to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profileImages/${_currentUser!.uid}.jpg');

        // Start upload task
        final uploadTask = await storageRef.putFile(image);

        // Get the download URL
        final downloadUrl = await storageRef.getDownloadURL();

        // Update Firestore with the new profile image URL
        await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
          'profileImageUrl': downloadUrl,
        });

        // Update the local variable and notify listeners
        _profileImageUrl = downloadUrl;
        notifyListeners();
        
        print("Profile picture updated successfully!");
      } catch (e) {
        print("Error updating profile picture: $e");
      }
    }
  }

  // Update methods for other profile fields
  void updateName(String newName) {
    _name = newName;
    notifyListeners();
  }

  void updateGender(String newGender) {
    _gender = newGender;
    notifyListeners();
  }

  void updateDateOfBirth(DateTime newDateOfBirth) {
    _dateOfBirth = newDateOfBirth;
    notifyListeners();
  }

  void updatePhoneNumber(String newPhoneNumber) {
    _phoneNumber = newPhoneNumber;
    notifyListeners();
  }

  void updateDescription(String newDescription) {
    _description = newDescription;
    notifyListeners();
  }

  void updateLocation(String newLocation) {
    _location = newLocation;
    notifyListeners();
  }
}
