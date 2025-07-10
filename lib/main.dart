import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:capstone_design/screen/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 상태 표시줄 색상 설정
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 디버그 배너 숨기기
      theme: ThemeData(
        primaryColor: Color(0xFF4CAF50),
        scaffoldBackgroundColor: Color(0xFFE8F5E9),
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
      ),
      home: SplashScreen(), // SplashScreen을 시작 화면으로 설정
    );
  }
}