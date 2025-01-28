import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:food_recommend/palette.dart';
import 'package:food_recommend/screens/LoginPage.dart';
import 'package:food_recommend/services/AuthenticationWrapper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MobileAds.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '랜덤 음식 추천 앱',
      locale: Locale('ko', 'KR'),
      supportedLocales: [
        Locale('ko', 'KR'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: customRed,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: customRed,
          surface: Colors.grey[200]!, // 흰색보다 어두운 색
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: customRed,
          textTheme: ButtonTextTheme.primary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: customRed,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: customRed,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black54,
        colorScheme: ColorScheme.dark(
          primary: customRed,
          surface: Colors.grey[800]!, // 어두운 테마용 surface 색상
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: customRed,
          textTheme: ButtonTextTheme.primary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: customRed,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system,
      home: AuthenticationWrapper(),
      routes: {
        '/login': (context) => LoginPage(),
      },
    );
  }
}
