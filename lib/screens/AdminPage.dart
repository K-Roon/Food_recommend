import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? companyCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchCompanyCode(); // 로그인한 사용자의 회사 코드 가져오기
  }

  Future<void> _fetchCompanyCode() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('member')
            .where('email', isEqualTo: user.email)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          setState(() {
            companyCode = data['company']; // 회사 코드 설정
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그인된 사용자의 회사 정보를 찾을 수 없습니다.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회사 코드 불러오기 오류: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (companyCode == null) {
      return Scaffold(
        appBar: AppBar(title: Text('관리자 페이지')),
        body: Center(child: CircularProgressIndicator()), // 회사 코드 로딩 중
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('관리자 페이지'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '음식 관리'),
            Tab(text: '회원 관리'),
            Tab(text: '회사 관리'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RestaurantManagementTab(companyCode: companyCode!),
          _MemberManagementTab(),
          _CompanyManagementTab(),
        ],
      ),
    );
  }
}

// 음식 관리 탭 (CRUD)
class _RestaurantManagementTab extends StatefulWidget {
  final String companyCode;

  const _RestaurantManagementTab({required this.companyCode});

  @override
  _RestaurantManagementTabState createState() =>
      _RestaurantManagementTabState();
}

class _RestaurantManagementTabState extends State<_RestaurantManagementTab> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mainMenuController = TextEditingController();
  final _mainPriceController = TextEditingController();

  Future<void> _addRestaurant() async {
    if (_nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _mainMenuController.text.isEmpty ||
        _mainPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 입력하세요.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.companyCode)
          .collection('foodlist')
          .add({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'mainmenu': _mainMenuController.text.trim(),
        'mainprice': int.tryParse(_mainPriceController.text.trim()) ?? 0,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('음식 추가 완료!')),
      );
      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  Future<void> _editRestaurant(String id, Map<String, dynamic> currentData) async {
    _nameController.text = currentData['name'] ?? '';
    _addressController.text = currentData['address'] ?? '';
    _mainMenuController.text = currentData['mainmenu'] ?? '';
    _mainPriceController.text = currentData['mainprice']?.toString() ?? '';

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
            TextField(
              controller: _mainMenuController,
              decoration: InputDecoration(labelText: '주요 메뉴'),
            ),
            TextField(
              controller: _mainPriceController,
              decoration: InputDecoration(labelText: '가격'),
              keyboardType: TextInputType.number,
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
              try {
                await FirebaseFirestore.instance
                    .collection('foods')
                    .doc(widget.companyCode)
                    .collection('foodlist')
                    .doc(id)
                    .update({
                  'name': _nameController.text.trim(),
                  'address': _addressController.text.trim(),
                  'mainmenu': _mainMenuController.text.trim(),
                  'mainprice': int.tryParse(_mainPriceController.text.trim()) ?? 0,
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('수정 완료!')),
                );
                Navigator.pop(context);
                _clearFields();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('오류 발생: $e')),
                );
              }
            },
            child: Text('수정'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRestaurant(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.companyCode)
          .collection('foodlist')
          .doc(id)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 완료!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  void _clearFields() {
    _nameController.clear();
    _addressController.clear();
    _mainMenuController.clear();
    _mainPriceController.clear();
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
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _mainMenuController,
                  decoration: InputDecoration(labelText: '주요 메뉴'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _mainPriceController,
                  decoration: InputDecoration(labelText: '가격'),
                  keyboardType: TextInputType.number,
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
            stream: FirebaseFirestore.instance
                .collection('foods')
                .doc(widget.companyCode)
                .collection('foodlist')
                .snapshots(),
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
                    subtitle: Text(
                        '주소: ${data['address'] ?? ''}\n메뉴: ${data['mainmenu'] ?? ''}\n가격: ${data['mainprice'] ?? 0}원'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _editRestaurant(doc.id, data);
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
}

// 회원 관리 (RUD)
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
              subtitle: Text(
                  '이메일: ${data['email'] ?? ''}\n회사 코드: ${data['company'] ?? ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      // 수정 로직 추가
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      FirebaseFirestore.instance.collection('member').doc(doc.id).delete();
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

// 회사 관리 탭 (CRUD)
class _CompanyManagementTab extends StatelessWidget {
  final TextEditingController companyCodeController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();

  Future<void> _addCompany() async {
    if (companyCodeController.text.isEmpty || companyNameController.text.isEmpty) {
      return;
    }
    await FirebaseFirestore.instance
        .collection('company')
        .doc(companyCodeController.text.trim())
        .set({
      'name': companyNameController.text.trim(),
    });
    companyCodeController.clear();
    companyNameController.clear();
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
                  controller: companyCodeController,
                  decoration: InputDecoration(labelText: '회사 코드'),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: companyNameController,
                  decoration: InputDecoration(labelText: '회사 이름'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: _addCompany,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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
                    subtitle: Text('코드: ${doc.id}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        FirebaseFirestore.instance.collection('company').doc(doc.id).delete();
                      },
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
}
