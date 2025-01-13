import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_recommend/AdminPage.dart';
import 'package:food_recommend/HomePage.dart';
import 'package:food_recommend/LoginPage.dart';
import 'package:food_recommend/UserPage.dart';

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return LoginPage();
          } else {
            return HomePage();
          }
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}
