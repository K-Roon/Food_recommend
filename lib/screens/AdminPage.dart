import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? companyCode;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
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
            companyCode = data['company'];
            isAdmin = data['isAdmin'] ?? false;
          });
        }
      }
    } catch (e) {
      print('사용자 정보를 불러오는 중 오류 발생: $e');
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text('관리자 페이지')),
        body: Center(child: Text('해당 권한이 없습니다.')),
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

//음식 관리 기능(CRUD)
class _RestaurantManagementTab extends StatefulWidget {
  final String companyCode;

  const _RestaurantManagementTab({required this.companyCode});

  @override
  _RestaurantManagementTabState createState() => _RestaurantManagementTabState();
}

class _RestaurantManagementTabState extends State<_RestaurantManagementTab> {
  bool isUploading = false;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mainMenuController = TextEditingController();
  final _mainPriceController = TextEditingController();
  final _imageSourceController = TextEditingController();
  File? _imageFile;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
          'food_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print("이미지 업로드 오류: $e");
      return null;
    }
  }

  Future<void> _addRestaurant() async {
    if (_nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _mainMenuController.text.isEmpty ||
        _mainPriceController.text.isEmpty ||
        _imageFile == null ||
        _imageSourceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 입력하세요.')),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    String? imageUrl = await _uploadImage(_imageFile!);

    setState(() {
      isUploading = false;
    });

    if (imageUrl != null) {
      await FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.companyCode)
          .collection('foodlist')
          .add({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'mainmenu': _mainMenuController.text.trim(),
        'mainprice': int.tryParse(_mainPriceController.text.trim()) ?? 0,
        'imageURL': imageUrl,
        'imageSource': _imageSourceController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('음식 추가 완료!')),
      );
      _clearFields();
    }
  }

  Future<void> _showEditDialog(String id, Map<String, dynamic> currentData) async {
    final TextEditingController editNameController = TextEditingController(text: currentData['name']);
    final TextEditingController editAddressController = TextEditingController(text: currentData['address']);
    final TextEditingController editMenuController = TextEditingController(text: currentData['mainmenu']);
    final TextEditingController editPriceController = TextEditingController(text: currentData['mainprice'].toString());
    final TextEditingController editSourceController = TextEditingController(text: currentData['imageSource']);

    File? newImage;
    String? newImageUrl = currentData['imageURL'];
    bool isUploading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('식당 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: editNameController, decoration: InputDecoration(labelText: '식당 이름')),
                TextField(controller: editAddressController, decoration: InputDecoration(labelText: '주소')),
                TextField(controller: editMenuController, decoration: InputDecoration(labelText: '주요 메뉴')),
                TextField(controller: editPriceController, decoration: InputDecoration(labelText: '가격'), keyboardType: TextInputType.number),
                TextField(controller: editSourceController, decoration: InputDecoration(labelText: '이미지 출처')),
                SizedBox(height: 8),
                newImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(newImage!, height: 100, width: 100, fit: BoxFit.cover),
                )
                    : (newImageUrl != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(newImageUrl!, height: 100, width: 100, fit: BoxFit.cover),
                )
                    : Text("이미지가 없습니다.")),
                TextButton.icon(
                  icon: Icon(Icons.image),
                  label: Text("이미지 변경"),
                  onPressed: () async {
                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        newImage = File(pickedFile.path);
                      });
                    }
                  },
                ),
                if (isUploading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 10),
                        Text("업로드 중...", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                setState(() {
                  isUploading = true;
                });

                if (newImage != null) {
                  newImageUrl = await _uploadImage(newImage!);
                }

                final updatedData = {
                  'name': editNameController.text.trim(),
                  'address': editAddressController.text.trim(),
                  'mainmenu': editMenuController.text.trim(),
                  'mainprice': int.tryParse(editPriceController.text.trim()) ?? 0,
                  'imageURL': newImageUrl ?? currentData['imageURL'],
                  'imageSource': editSourceController.text.trim(),
                };

                await FirebaseFirestore.instance
                    .collection('foods')
                    .doc(widget.companyCode)
                    .collection('foodlist')
                    .doc(id)
                    .update(updatedData);

                setState(() {
                  isUploading = false;
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('수정 완료!')),
                );
              },
              child: isUploading ? CircularProgressIndicator(color: Colors.white) : Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRestaurant(String id) async {
    await FirebaseFirestore.instance
        .collection('foods')
        .doc(widget.companyCode)
        .collection('foodlist')
        .doc(id)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('삭제 완료!')),
    );
  }

  void _clearFields() {
    _nameController.clear();
    _addressController.clear();
    _mainMenuController.clear();
    _mainPriceController.clear();
    _imageSourceController.clear();
    setState(() {
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: '식당 이름'),
              ),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: '주소'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mainMenuController,
                      decoration: InputDecoration(labelText: '주요 메뉴'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _mainPriceController,
                      decoration: InputDecoration(labelText: '가격'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _imageSourceController,
                decoration: InputDecoration(labelText: '이미지 출처'),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_imageFile!, height: 60),
                  )
                      : Text("이미지를 선택하세요"),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.image),
                        label: Text("이미지 선택"),
                        onPressed: _pickImage,
                      ),
                      SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('추가'),
                        onPressed: _addRestaurant,
                      ),
                    ],
                  ),
                ],
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
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('등록된 식당이 없습니다.'));
              }
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: data['imageURL'] != null
                                ? Image.network(data['imageURL'],
                                width: 80, height: 80, fit: BoxFit.cover)
                                : Icon(Icons.image, size: 80),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? '알 수 없음',
                                    style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 5),
                                Text('${data['address']}'),
                                Text('${data['mainmenu']} | ${data['mainprice']}원'),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(icon: Icon(Icons.edit), onPressed: () => _showEditDialog(doc.id, data)),
                              IconButton(icon: Icon(Icons.delete), onPressed: () => _deleteRestaurant(doc.id)),
                            ],
                          ),
                        ],
                      ),
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

// 회원 관리 탭 (RUD)
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
              subtitle: Text('이메일: ${data['email'] ?? ''}'),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () async {
                  bool confirmDelete = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('회원 삭제'),
                      content: Text('이 회원을 정말 삭제하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('취소'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('삭제'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                        ),
                      ],
                    ),
                  );

                  if (confirmDelete == true) {
                    await FirebaseFirestore.instance
                        .collection('member')
                        .doc(doc.id)
                        .delete();
                  }
                },
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
    if (companyCodeController.text.isEmpty ||
        companyNameController.text.isEmpty) {
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
            stream:
                FirebaseFirestore.instance.collection('company').snapshots(),
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
                      onPressed: () async {
                        bool confirmDelete = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('회사 삭제'),
                            content: Text('이 회사를 정말 삭제하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('취소'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('삭제'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                              ),
                            ],
                          ),
                        );

                        if (confirmDelete == true) {
                          await FirebaseFirestore.instance
                              .collection('company')
                              .doc(doc.id)
                              .delete();
                        }
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
