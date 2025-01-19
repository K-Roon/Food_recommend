import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'UserPage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? companyCode;

  @override
  void initState() {
    super.initState();
    _fetchCompanyCode();
  }

  Future<void> _fetchCompanyCode() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('member')
          .where('email', isEqualTo: user.email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          companyCode = snapshot.docs.first.data()['company'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (companyCode == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()), // 회사 코드 로딩 중
      );
    }

    return UserPage(); // companyCode 전달
  }
}
