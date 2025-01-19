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
  final _nameController = TextEditingController();
  final _companyCodeController = TextEditingController();
  String? _errorMessage;

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Firebase Authentication에 사용자 추가
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = userCredential.user;

        // Firestore의 'member' 컬렉션에 데이터 추가
        await FirebaseFirestore.instance.collection('member').add({
          'email': user?.email ?? '',
          'name': _nameController.text.trim(),
          'company': _companyCodeController.text.trim(),
          'isAdmin': false,
          'admin_level': null
        });

        // 회원가입 성공 시 로그인 페이지로 이동
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입이 완료되었습니다. 로그인하세요.')),
        );
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    // 이메일 형식 정규식
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (value == null || value.isEmpty) {
      return '이메일을 입력하세요.';
    } else if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식을 입력하세요.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: '이름'),
                validator: (value) => value?.isEmpty ?? true ? '이름을 입력하세요.' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: '이메일'),
                keyboardType: TextInputType.emailAddress, // 이메일 입력용 키보드
                validator: _validateEmail, // 이메일 검증 함수 추가
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                validator: (value) => value?.isEmpty ?? true ? '비밀번호를 입력하세요.' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _companyCodeController,
                decoration: InputDecoration(labelText: '회사 코드'),
                validator: (value) => value?.isEmpty ?? true ? '회사 코드를 입력하세요.' : null,
              ),
              SizedBox(height: 16),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ElevatedButton(
                onPressed: _signUp,
                child: Text('회원가입'),
              ),
              SizedBox(height: 16),
              Text(
                "회원가입을 하시게 되면, 약관 및 개인정보제공에 동의하게 되는 것 입니다",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
