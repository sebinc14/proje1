import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/string_extensions.dart';

class UserProvider extends ChangeNotifier {
  String _formattedName = 'Misafir';
  String _avatarLetter = 'M';
  String _firstName = '';
  String _lastName = '';
  String _email = '';

  String get formattedName => _formattedName;
  String get avatarLetter => _avatarLetter;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get email => _email;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  UserProvider() {
    _init();
  }

  void _init() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _email = user.email ?? '';
        _listenToUserDocument(user.uid);
      } else {
        _clearUser();
      }
    });
  }

  void _listenToUserDocument(String uid) {
    _userDocSubscription?.cancel();
    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        _firstName = data['firstName'] ?? data['name'] ?? '';
        _lastName = data['lastName'] ?? '';
        
        _updateFormattedName();
      } else {
        // Doküman yoksa (örneğin Google ile ilk kez giriş ve doküman henüz oluşturulmamışsa)
        // Firebase Auth'un displayName'ini veya email'i kullanalım.
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          if (user.displayName != null && user.displayName!.isNotEmpty) {
            final parts = user.displayName!.split(' ');
            _firstName = parts.first;
            _lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          }
        }
        _updateFormattedName();
      }
    }, onError: (error) {
      debugPrint("Error listening to user document: $error");
    });
  }

  void _updateFormattedName() {
    _formattedName = NameFormatter.formatName(
      firstName: _firstName,
      lastName: _lastName,
      email: _email,
    );
    _avatarLetter = NameFormatter.getAvatarInitial(_formattedName);
    notifyListeners();
  }

  void _clearUser() {
    _userDocSubscription?.cancel();
    _firstName = '';
    _lastName = '';
    _email = '';
    _formattedName = 'Misafir';
    _avatarLetter = 'M';
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }
}
