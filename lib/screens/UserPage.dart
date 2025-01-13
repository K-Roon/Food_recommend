import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_recommend/AdminPage.dart';

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _foodList = [];
  String? _recommendedFood;

  @override
  void initState() {
    super.initState();
    _fetchFoodList();
  }

  Future<void> _fetchFoodList() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('foods').get();
      setState(() {
        _foodList = snapshot.docs
            .map((doc) => doc['name'] as String)
            .toList();
      });
      _recommendRandomFood(); // 초기 추천
    } catch (e) {
      print('음식 목록을 불러오는 중 오류 발생: $e');
    }
  }

  void _recommendRandomFood() {
    if (_foodList.isNotEmpty) {
      final random = Random();
      String newRecommendation;
      do {
        newRecommendation = _foodList[random.nextInt(_foodList.length)];
      } while (newRecommendation == _recommendedFood);

      setState(() {
        _recommendedFood = newRecommendation;
      });
    } else {
      setState(() {
        _recommendedFood = null;
      });
    }
  }

  Future<bool> _isAdmin() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc['role'] == 'admin';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('랜덤 음식 추천'),
        actions: [
          FutureBuilder<bool>(
            future: _isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return IconButton(
                  icon: Icon(Icons.admin_panel_settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminPage()),
                    );
                  },
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_recommendedFood != null)
              Text(
                '추천 음식: $_recommendedFood',
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              )
            else
              Text(
                '음식 목록이 비어있습니다.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _recommendRandomFood,
              child: Text('다른 식당 추천'),
            ),
          ],
        ),
      ),
    );
  }
}
