import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'AdminPage.dart';
import 'UserInfoPage.dart';
import 'RestaurantDetailsPage.dart';
import 'package:food_recommend/ad_helper.dart';

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final _auth = FirebaseAuth.instance;
  String? companyCode;
  bool isAdmin = false;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
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

      return snapshot.docs
          .map((doc) => {
        'id': doc.id,
        ...doc.data(),
      })
          .toList();
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
    final imageUrl = randomFood['imageURL']; // 이미지 URL 가져오기

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            // 이미지가 있으면 표시, 없으면 기본 아이콘
            imageUrl != null
                ? Image.network(
              imageUrl,
              height: 150,
              fit: BoxFit.cover,
            )
                : Icon(Icons.image, size: 100),
            SizedBox(height: 8),
            Text('이 음식을 추천할게요!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '추천 메뉴: $mainMenu\n'
                  '가격: $mainPrice원\n'
                  '음식점: $foodName\n'
                  '주소: $foodAddress',
              textAlign: TextAlign.center,
            ),
          ],
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

  Future<void> _refreshPage() async {
    await _fetchUserData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('음식 리스트'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshPage,
          ),
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'admin' && isAdmin) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPage()),
                );
              } else if (value == 'userinfo') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserInfoPage()),
                );
              }
            },
            itemBuilder: (context) => [
              if (isAdmin)
                PopupMenuItem(
                  value: 'admin',
                  child: Text('관리자 페이지'),
                ),
              PopupMenuItem(
                value: 'userinfo',
                child: Text('사용자 정보'),
              ),
            ],
          ),
        ],
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

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RestaurantDetailsPage(food: food),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 왼쪽: 이미지
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: food['imageURL'] != null
                                  ? Image.network(
                                food['imageURL'],
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.image, size: 40, color: Colors.grey[600]),
                              ),
                            ),
                            SizedBox(width: 12),
                            // 오른쪽: 텍스트 정보
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food['mainmenu'] ?? '알 수 없음',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '가격: ${food['mainprice'] ?? 0}원',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  Text(
                                    '식당: ${food['name'] ?? '알 수 없음'}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    '주소: ${food['address'] ?? '주소 없음'}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
              // 광고 배너 추가
              if (_bannerAd != null)
                Padding(
                  padding: Platform.isIOS
                      ? const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0, bottom: 32.0)
                      : const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

}
