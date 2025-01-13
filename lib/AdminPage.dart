import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _companyNameController = TextEditingController();
  final _authCodeController = TextEditingController();
  final CollectionReference companies =
  FirebaseFirestore.instance.collection('companies');

  Future<void> _addCompany() async {
    if (_companyNameController.text.isNotEmpty &&
        _authCodeController.text.isNotEmpty) {
      try {
        await companies.add({
          'name': _companyNameController.text.trim(),
          'authCode': _authCodeController.text.trim(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회사 추가 완료')),
        );
        _companyNameController.clear();
        _authCodeController.clear();
      } catch (e) {
        print('회사 추가 중 오류 발생: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회사 추가 실패: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 입력하세요')),
      );
    }
  }

  Future<void> _updateCompany(String id, String newName, String newAuthCode) async {
    try {
      await companies.doc(id).update({
        'name': newName,
        'authCode': newAuthCode,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회사 정보 수정 완료')),
      );
    } catch (e) {
      print('회사 정보 수정 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회사 정보 수정 실패: $e')),
      );
    }
  }

  Future<void> _deleteCompany(String id) async {
    try {
      await companies.doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회사 삭제 완료')),
      );
    } catch (e) {
      print('회사 삭제 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회사 삭제 실패: $e')),
      );
    }
  }

  void _showEditDialog(DocumentSnapshot doc) {
    _companyNameController.text = doc['name'];
    _authCodeController.text = doc['authCode'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('회사 정보 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _companyNameController,
              decoration: InputDecoration(labelText: '회사 이름'),
            ),
            TextField(
              controller: _authCodeController,
              decoration: InputDecoration(labelText: '인증 코드'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _updateCompany(
                doc.id,
                _companyNameController.text.trim(),
                _authCodeController.text.trim(),
              );
              Navigator.of(context).pop();
            },
            child: Text('수정'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('취소'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회사 관리')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _companyNameController,
              decoration: InputDecoration(labelText: '회사 이름'),
            ),
            TextField(
              controller: _authCodeController,
              decoration: InputDecoration(labelText: '인증 코드'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addCompany,
              child: Text('회사 추가'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: companies.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return ListTile(
                        title: Text(doc['name']),
                        subtitle: Text('인증 코드: ${doc['authCode']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _showEditDialog(doc),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteCompany(doc.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
