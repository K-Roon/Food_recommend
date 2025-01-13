import 'package:flutter/material.dart';

class SignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 기존 회원가입 입력 필드와 버튼
            TextField(
              decoration: InputDecoration(
                labelText: '이메일',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: '비밀번호',
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 회원가입 로직 실행
              },
              child: Text('회원가입'),
            ),
            SizedBox(height: 16),

            // 추가된 인증코드 생성 버튼
            ElevatedButton(
              onPressed: () {
                final code = _generateAuthCode();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('인증코드'),
                    content: Text('인증코드: $code'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('확인'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('유베이스 인증코드 생성'),
            ),
          ],
        ),
      ),
    );
  }

  // 인증코드 생성 함수
  String _generateAuthCode() {
    const allowedChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => allowedChars[(allowedChars.length * index / 6).toInt()])
        .join();
  }
}
