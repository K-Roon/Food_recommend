import 'package:flutter/material.dart';

class RestaurantDetailsPage extends StatelessWidget {
  final Map<String, dynamic> food;

  RestaurantDetailsPage({required this.food});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(food['name'] ?? '상세 정보'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: isWideScreen
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 1,
              child: _buildImageWithSource(),
            ),
            SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: _buildInfo(),
            ),
          ],
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageWithSource(),
            SizedBox(height: 20),
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  // 📌 이미지 + 이미지 출처 위젯
  Widget _buildImageWithSource() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20), // ✅ 라운딩 적용
          child: AspectRatio(
            aspectRatio: 1, // ✅ 1:1 비율 유지
            child: food['imageURL'] != null
                ? Image.network(food['imageURL'], fit: BoxFit.cover)
                : Container(
              color: Colors.grey[300],
              child: Icon(Icons.image, size: 80, color: Colors.grey[600]),
            ),
          ),
        ),
        if (food['imageSource'] != null && food['imageSource'].toString().trim().isNotEmpty) ...[
          SizedBox(height: 5),
          Text(
            '출처: ${food['imageSource']}',
            style: TextStyle(fontSize: 12, color: Colors.grey), // ✅ 작은 회색 글씨
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // 📌 레스토랑 정보 위젯
  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(food['mainmenu'] ?? '알 수 없음',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Text('가격: ${food['mainprice'] ?? '가격정보 없음'}원'),
        SizedBox(height: 10),
        Text('식당 이름: ${food['name'] ?? '알 수 없음'}'),
        SizedBox(height: 10),
        Text('주소: ${food['address'] ?? '주소 정보 없음'}'),
      ],
    );
  }
}
