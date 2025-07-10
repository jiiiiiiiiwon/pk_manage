import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:capstone_design/screen/home_screen.dart';

// 간단한 메모리 기반 로그인 상태 관리
class LoginManager {
  static bool _isLoggedIn = false;
  static String? _userToken;
  static String? _userEmail;
  static String? _userName;
  static int? _userId;

  static bool get isLoggedIn => _isLoggedIn;
  static String? get userToken => _userToken;
  static String? get userEmail => _userEmail;
  static String? get userName => _userName;
  static int? get userId => _userId;

  static void login(String token, String email, String name, int id) {
    _isLoggedIn = true;
    _userToken = token;
    _userEmail = email;
    _userName = name;
    _userId = id;
  }

  static void logout() {
    _isLoggedIn = false;
    _userToken = null;
    _userEmail = null;
    _userName = null;
    _userId = null;
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 로그인 API 호출
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://172.20.10.7:3000/api/users/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // 로그인 성공
        _saveLoginInfo(responseData);
        
        // 홈 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        // 로그인 실패
        _showErrorDialog(responseData['message'] ?? '로그인에 실패했습니다.');
      }
    } catch (e) {
      print('로그인 오류: $e');
      _showErrorDialog('네트워크 오류가 발생했습니다. 서버 연결을 확인해주세요.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 로그인 정보 저장 (메모리 기반)
  void _saveLoginInfo(Map<String, dynamic> responseData) {
    try {
      LoginManager.login(
        responseData['token'],
        responseData['user']['email'],
        responseData['user']['name'],
        responseData['user']['id'],
      );
      print('로그인 정보 저장 완료');
    } catch (e) {
      print('로그인 정보 저장 오류: $e');
    }
  }

  // 에러 다이얼로그 표시
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('로그인 오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  // 회원가입 화면으로 이동
  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(height: 60),
              
              // 로고
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/img/splash_logo.png',
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.local_parking,
                          size: 120,
                          color: Color(0xFF00A896),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    Text(
                      '어디대',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A896),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '스마트 주차장 관리 시스템',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40),
              
              // 로그인 폼
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 이메일 입력
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: '이메일을 입력하세요',
                          prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF00A896)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '이메일을 입력해주세요';
                          }
                          if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                            return '올바른 이메일 형식을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // 비밀번호 입력
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '비밀번호를 입력하세요',
                          prefixIcon: Icon(Icons.lock_outlined, color: Color(0xFF00A896)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Color(0xFF00A896),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '비밀번호를 입력해주세요';
                          }
                          if (value.length < 6) {
                            return '비밀번호는 6자 이상이어야 합니다';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // 로그인 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00A896),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                '로그인',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // 회원가입 링크
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '계정이 없으신가요? ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        GestureDetector(
                          onTap: _goToRegister,
                          child: Text(
                            '회원가입',
                            style: TextStyle(
                              color: Color(0xFF00A896),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 40),
                    
                    // 임시 로그인 (개발용)
                    TextButton(
                      onPressed: () {
                        // 개발용 임시 로그인
                        LoginManager.login('temp_token', 'temp@email.com', '임시사용자', 1);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MainScreen()),
                        );
                      },
                      child: Text(
                        '임시 로그인 (개발용)',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 회원가입 화면
class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 회원가입 API 호출
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://172.20.10.7:3000/api/users/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'phone': _phoneController.text.trim(),
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // 회원가입 성공
        _showSuccessDialog();
      } else {
        // 회원가입 실패
        _showErrorDialog(responseData['message'] ?? '회원가입에 실패했습니다.');
      }
    } catch (e) {
      print('회원가입 오류: $e');
      _showErrorDialog('네트워크 오류가 발생했습니다.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('회원가입 완료'),
        content: Text('회원가입이 완료되었습니다. 로그인해주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 회원가입 화면 닫기
            },
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('회원가입 오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('회원가입'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 20),
                
                // 이름 입력
                _buildInputField(
                  controller: _nameController,
                  hintText: '이름을 입력하세요',
                  icon: Icons.person_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 16),
                
                // 이메일 입력
                _buildInputField(
                  controller: _emailController,
                  hintText: '이메일을 입력하세요',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                      return '올바른 이메일 형식을 입력해주세요';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 16),
                
                // 비밀번호 입력
                _buildInputField(
                  controller: _passwordController,
                  hintText: '비밀번호를 입력하세요 (6자 이상)',
                  icon: Icons.lock_outlined,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Color(0xFF00A896),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 16),
                
                // 전화번호 입력 (선택사항)
                _buildInputField(
                  controller: _phoneController,
                  hintText: '전화번호를 입력하세요 (선택사항)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                
                SizedBox(height: 32),
                
                // 회원가입 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00A896),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: Color(0xFF00A896)),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}