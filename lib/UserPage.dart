import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    } catch (e) {
      // 에러 처리
      print('음식 목록을 불러오는 중 오류 발생: $e');
    }
  }

  void _recommendRandomFood() {
    if (_foodList.isNotEmpty) {
      final random = Random();
      setState(() {
        _recommendedFood = _foodList[random.nextInt(_foodList.length)];
      });
    } else {
      setState(() {
        _recommendedFood = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('랜덤 음식 추천'),
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
              child: Text('음식 추천 받기'),
            ),
          ],
        ),
      ),
    );
  }
}
