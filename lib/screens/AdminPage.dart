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
class _RestaurantManagementTab extends StatefulWidget {
  @override
  _RestaurantManagementTabState createState() => _RestaurantManagementTabState();
}

class _RestaurantManagementTabState extends State<_RestaurantManagementTab> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  Future<void> _addRestaurant() async {
    if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 입력하세요.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('foods').add({
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
    });

    _nameController.clear();
    _addressController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: '식당 이름'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: '주소'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: _addRestaurant,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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
                            _editRestaurant(doc.id, data['name'], data['address']);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _deleteRestaurant(doc.id);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _editRestaurant(String id, String currentName, String currentAddress) async {
    _nameController.text = currentName;
    _addressController.text = currentAddress;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('식당 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: '식당 이름'),
            ),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: '주소'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('foods').doc(id).update({
                'name': _nameController.text.trim(),
                'address': _addressController.text.trim(),
              });
              Navigator.pop(context);
            },
            child: Text('수정'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRestaurant(String id) async {
    await FirebaseFirestore.instance.collection('foods').doc(id).delete();
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
              title: Text(data['email'] ?? '알 수 없음'),
              subtitle: Text(data['company'] ?? '소속 없음'),
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
            );
          }).toList(),
        );
      },
    );
  }
}
