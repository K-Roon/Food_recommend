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
  final _companyCodeController = TextEditingController();
  String? _errorMessage;

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Verify company code in Firestore
        final companyDoc = await FirebaseFirestore.instance
            .collection('company')
            .doc(_companyCodeController.text.trim())
            .get();

        if (!companyDoc.exists) {
          setState(() {
            _errorMessage = '유효하지 않은 회사 코드입니다.';
          });
          return;
        }

        // Register user in Firebase Authentication
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Add user data to Firestore
        await FirebaseFirestore.instance.collection('member').add({
          'email': _emailController.text.trim(),
          'company': _companyCodeController.text.trim(),
          'name': userCredential.user?.displayName ?? '사용자',
        });

        Navigator.pop(context); // Return to login page on success
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
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
                controller: _emailController,
                decoration: InputDecoration(labelText: '이메일'),
                validator: (value) => value?.isEmpty ?? true ? '이메일을 입력하세요.' : null,
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
            ],
          ),
        ),
      ),
    );
  }
}
