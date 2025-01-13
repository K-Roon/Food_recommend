import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3개의 탭
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('관리자 페이지'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '식당 관리'),
            Tab(text: '회원 관리'),
            Tab(text: '회사 관리'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RestaurantManagementTab(),
          _MemberManagementTab(),
          _CompanyManagementTab(),
        ],
      ),
    );
  }
}

// 식당 관리 탭
class _RestaurantManagementTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('foods').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('등록된 식당이 없습니다.'));
        }
        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name'] ?? '알 수 없음'),
              subtitle: Text(data['address'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      // 수정 기능
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      // 삭제 기능
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// 회원 관리 탭
class _MemberManagementTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('member').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('등록된 회원이 없습니다.'));
        }
        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name'] ?? '알 수 없음'),
              subtitle: Text(data['email'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      // 수정 기능
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      // 삭제 기능
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// 회사 관리 탭
class _CompanyManagementTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('company').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('등록된 회사가 없습니다.'));
        }
        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name'] ?? '알 수 없음'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      // 수정 기능
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      // 삭제 기능
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
