import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_recommend/screens/AdminPage.dart';
import 'package:food_recommend/screens/UserPage.dart';

class HomePage extends StatelessWidget {
  Future<bool> _isAdmin() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return userDoc['role'] == 'admin';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasData && snapshot.data == true) {
          // 관리자 화면
          return AdminPage();
        } else {
          // 일반 사용자 화면
          return UserPage();
        }
      },
    );
  }
}
