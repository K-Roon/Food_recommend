import 'package:flutter/material.dart';

class RestaurantDetailsPage extends StatelessWidget {
  final Map<String, dynamic> food;

  RestaurantDetailsPage({required this.food});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(food['name'] ?? '상세 정보'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('식당 이름: ${food['name'] ?? '알 수 없음'}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('주소: ${food['address'] ?? '주소 없음'}'),
            SizedBox(height: 10),
            Text('주요 메뉴: ${food['mainmenu'] ?? '메뉴 정보 없음'}'),
            SizedBox(height: 10),
            Text('가격: ${food['mainprice'] ?? '가격 정보 없음'}원'),
          ],
        ),
      ),
    );
  }
}
