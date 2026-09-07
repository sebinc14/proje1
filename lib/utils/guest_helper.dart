import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool checkGuestAndWarn() {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && user.isAnonymous) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Üye girişi yapınız. ☕"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    return true; // is guest
  }
  return false;
}
