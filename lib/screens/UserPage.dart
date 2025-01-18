import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'AdminPage.dart';
import 'dart:math';
import 'RestaurantDetailsPage.dart'; // 상세 정보 페이지 추가

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final _auth = FirebaseAuth.instance;
  String? companyCode;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('member')
            .where('email', isEqualTo: user.email)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          setState(() {
            companyCode = data['company'];
            isAdmin = data['isAdmin'] ?? false;
          });
        }
      }
    } catch (e) {
      print('사용자 데이터를 불러오는 중 오류 발생: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFoodList() async {
    try {
      if (companyCode == null) return [];
      final snapshot = await FirebaseFirestore.instance
          .collection('foods')
          .doc(companyCode)
          .collection('foodlist')
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id, // 문서 ID 추가
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('음식 목록을 불러오는 중 오류 발생: $e');
      return [];
    }
  }

  void _recommendRandomFood(List<Map<String, dynamic>> foodList) {
    if (foodList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('추천할 음식점이 없습니다.')),
      );
      return;
    }
    final random = Random();
    final randomFood = foodList[random.nextInt(foodList.length)];
    final foodName = randomFood['name'] ?? '알 수 없음';
    final foodAddress = randomFood['address'] ?? '주소 없음';
    final mainMenu = randomFood['mainmenu'] ?? '메뉴 정보 없음';
    final mainPrice = randomFood['mainprice'] ?? '가격 정보 없음';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('랜덤 추천 결과'),
        content: Text(
          '추천 음식점: $foodName\n'
              '주소: $foodAddress\n'
              '주요 메뉴: $mainMenu\n'
              '가격: $mainPrice원',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('음식 리스트'),
        actions: isAdmin
            ? [
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'admin') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPage()),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'admin',
                child: Text('관리자 페이지'),
              ),
            ],
          ),
        ]
            : null,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchFoodList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('음식 데이터가 없습니다.'));
          }

          final foodList = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: foodList.length,
                  itemBuilder: (context, index) {
                    final food = foodList[index];
                    return ListTile(
                      title: Text(food['name'] ?? '알 수 없음'),
                      subtitle: Text(food['address'] ?? '주소 없음'),
                      trailing: Text('${food['mainprice'] ?? 0}원'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RestaurantDetailsPage(food: food),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => _recommendRandomFood(foodList),
                  child: Text('랜덤 추천'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
