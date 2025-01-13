import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authCodeController = TextEditingController();
  final _nameController = TextEditingController();

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 입력된 인증 코드 확인
        String inputAuthCode = _authCodeController.text.trim();
        QuerySnapshot companySnapshot = await FirebaseFirestore.instance
            .collection('companies')
            .where('authCode', isEqualTo: inputAuthCode)
            .get();

        if (companySnapshot.docs.isNotEmpty) {
          // 인증 코드가 유효한 경우 회원가입 진행
          UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

          // Firestore에 사용자 정보 저장
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'email': _emailController.text,
            'name': _nameController.text,
            'companyId': companySnapshot.docs.first.id,
            'role': 'user', // 기본 역할을 'user'로 설정
          });

          Navigator.pop(context);
        } else {
          // 인증 코드가 유효하지 않은 경우
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('유효하지 않은 인증 코드입니다.')),
          );
        }
      } catch (e) {
        // 에러 처리
        print('회원가입 중 오류 발생: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회원가입')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: '이름'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력하세요';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: '이메일'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력하세요';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력하세요';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _authCodeController,
                decoration: InputDecoration(labelText: '회사 인증 코드'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '인증 코드를 입력하세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signUp,
                child: Text('회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
