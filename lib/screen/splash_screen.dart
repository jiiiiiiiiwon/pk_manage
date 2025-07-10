import 'dart:async';
import 'package:flutter/material.dart';
import 'package:capstone_design/screen/home_screen.dart';
import 'login_screen.dart'; // 로그인 화면 임포트

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // 디버깅을 위한 로그 추가
    print("스플래시 화면 로딩됨");
    
    // 2초 후에 로그인 상태 확인 후 화면 이동
    Timer(Duration(seconds: 2), () {
      print("타이머 완료 - 로그인 상태 확인");
      
      if (mounted) {  // mounted 체크 추가
        _checkLoginStatus();
      } else {
        print("위젯이 이미 dispose됨");
      }
    });
  }

  // 로그인 상태 확인 (메모리 기반)
  void _checkLoginStatus() {
    try {
      // LoginManager를 통해 로그인 상태 확인
      bool isLoggedIn = LoginManager.isLoggedIn;
      String? token = LoginManager.userToken;
      
      print("로그인 상태: $isLoggedIn, 토큰 존재: ${token != null}");
      
      if (mounted) {
        if (isLoggedIn && token != null) {
          // 이미 로그인된 상태라면 메인 화면으로 이동
          print("이미 로그인됨 - 메인 화면으로 이동");
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        } else {
          // 로그인되지 않은 상태라면 로그인 화면으로 이동
          print("로그인 필요 - 로그인 화면으로 이동");
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
      }
    } catch (e) {
      print("로그인 상태 확인 실패: $e");
      
      if (mounted) {
        // 오류 발생 시 로그인 화면으로 이동
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 124, 176, 126),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지
            Image.asset(
              'assets/img/splash_logo.png',
              width: 200,
              // 이미지 오류 처리 추가
              errorBuilder: (context, error, stackTrace) {
                print("이미지 로드 오류: $error");
                return Icon(
                  Icons.local_parking, 
                  size: 100, 
                  color: Colors.white,
                );
              },
            ),
            SizedBox(height: 20),
            
            // 앱 이름
            Text(
              '어디대',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            
            // 부제목
            Text(
              '스마트 주차장 관리 시스템',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 40),
            
            // 로딩 인디케이터
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}