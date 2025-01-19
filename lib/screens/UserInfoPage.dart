import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserInfoPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> _deleteAccount(BuildContext context, String memberId) async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        // Firestore 데이터 삭제
        await FirebaseFirestore.instance
            .collection('member')
            .doc(memberId)
            .delete();

        // Firebase Authentication 계정 삭제
        await user.delete();

        // 로그아웃 처리
        await _auth.signOut();

        // 메인 페이지로 이동
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      // Firebase Authentication 에러 처리
      if (e.toString().contains('requires-recent-login')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오래된 인증입니다. 다시 로그인 후 시도해주세요.')),
        );
        // 사용자에게 재인증을 요청
        await _reauthenticateUser(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원 탈퇴 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _reauthenticateUser(BuildContext context) async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        final email = user.email!;
        final credential = EmailAuthProvider.credential(
          email: email,
          password: '비밀번호를 재인증해야 합니다.',
        );

        await user.reauthenticateWithCredential(credential);

        // 재인증 후 회원 탈퇴 재시도
        final snapshot = await FirebaseFirestore.instance
            .collection('member')
            .where('email', isEqualTo: email)
            .get();

        if (snapshot.docs.isNotEmpty) {
          await _deleteAccount(context, snapshot.docs.first.id);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('재인증 실패: $e')),
      );
    }
  }

  void _confirmAccountDeletion(BuildContext context, String memberId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('회원 탈퇴'),
        content: Text('회원 탈퇴 시 회원의 모든 데이터가 삭제되며 복구할 수 없습니다.\n계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context, memberId);
            },
            child: Text('회원 탈퇴'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Text('이름: ${userInfo['name'] ?? '알 수 없음'}',
                    style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text('이메일: ${userInfo['email'] ?? '알 수 없음'}'),
                SizedBox(height: 10),
                Text('소속 회사: ${userInfo['company'] ?? '알 수 없음'}'),
                SizedBox(height: 10),
                Text(
                    '관리자 여부: ${userInfo['isAdmin'] == true ? '관리자' : '일반 사용자'}'),
                Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    _confirmAccountDeletion(context, userInfo['id']);
                  },
                  child: Text('회원 탈퇴'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
