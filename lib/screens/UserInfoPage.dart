import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class UserInfoPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<Map<String, dynamic>> _fetchUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('member')
          .where('email', isEqualTo: user.email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return {
          'id': snapshot.docs.first.id,
          ...snapshot.docs.first.data(),
        };
      }
    }
    return {};
  }

  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: _scaffoldKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text('로그아웃'),
        content: Text('로그아웃을 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            onLongPress: () async {
              await _auth.signOut();
              Navigator.of(_scaffoldKey.currentContext!)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: Text('여기를 길게 눌러 로그아웃'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, String memberId) async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('member')
            .doc(memberId)
            .delete();
        await user.delete();
        await _auth.signOut();
        Navigator.of(_scaffoldKey.currentContext!)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(content: Text('회원탈퇴 중 오류가 발생했습니다: $e')),
      );
    }
  }

  void _confirmAccountDeletion(BuildContext context, String memberId) {
    showDialog(
      context: _scaffoldKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text('회원 탈퇴'),
        content: Text('회원 탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            onLongPress: () async {
              Navigator.pop(context);
              await _deleteAccount(context, memberId);
            },
            child: Text('여기를 길게 눌러 회원 탈퇴'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmNewPasswordController =
        TextEditingController();

    showDialog(
      context: _scaffoldKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text('비밀번호 변경'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: InputDecoration(labelText: '현재 비밀번호 입력'),
              obscureText: true,
            ),
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(labelText: '새 비밀번호 입력'),
              obscureText: true,
            ),
            TextField(
              controller: confirmNewPasswordController,
              decoration: InputDecoration(labelText: '새 비밀번호 확인'),
              obscureText: true,
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
              final currentPassword = currentPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmNewPassword =
                  confirmNewPasswordController.text.trim();

              if (currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmNewPassword.isEmpty) {
                ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                  SnackBar(content: Text('모든 필드를 입력하세요.')),
                );
                return;
              }

              if (newPassword != confirmNewPassword) {
                ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                  SnackBar(content: Text('새 비밀번호가 일치하지 않습니다.')),
                );
                return;
              }

              if (newPassword.length < 6) {
                ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                  SnackBar(content: Text('비밀번호는 최소 6자 이상이어야 합니다.')),
                );
                return;
              }

              try {
                final user = _auth.currentUser;
                final email = user?.email;

                final credential = EmailAuthProvider.credential(
                  email: email!,
                  password: currentPassword,
                );

                await user?.reauthenticateWithCredential(credential);
                await user?.updatePassword(newPassword);
                Navigator.pop(context);
                ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                  SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                  SnackBar(content: Text('비밀번호 변경 중 오류가 발생했습니다: $e')),
                );
              }
            },
            child: Text('변경'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Scaffold에 GlobalKey 추가
      appBar: AppBar(
        title: Text('내 정보'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('사용자 정보를 불러올 수 없습니다.'));
          }

          final userInfo = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이름: ${userInfo['name'] ?? '알 수 없음'}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '이메일: ${userInfo['email'] ?? '알 수 없음'}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _changePassword(context);
                  },
                  child: Text('비밀번호 변경'),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    _logout(context);
                  },
                  child: Text('로그아웃'),
                ),
                SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    text: "회원 탈퇴를 원하신다면 ",
                    children: [
                      TextSpan(
                        text: "여기",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _confirmAccountDeletion(context, userInfo['id']);
                          },
                      ),
                      TextSpan(text: "를 눌러주세요."),
                    ],
                  ),
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
