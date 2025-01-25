import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
        brightness: Brightness.light, // 라이트 모드 설정
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark, // 다크 모드 설정
        primarySwatch: Colors.blue,
      ),
      themeMode: ThemeMode.system, // 시스템 설정에 따라 자동 변경
      home: AuthenticationWrapper(),
    );
  }
}
