import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:food_recommend/AuthenticationWrapper.dart';
import 'package:food_recommend/services/AuthenticationWrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '랜덤 음식 추천 앱',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthenticationWrapper(),
    );
  }
}
