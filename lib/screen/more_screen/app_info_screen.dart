import 'package:flutter/material.dart';

class AppInfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('앱 정보')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('어디대?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('버전: v1.0.0', style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Text('제작자: 주차 혁명단', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00A896)),
              child: Text('이용약관 보기'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00A896)),
              child: Text('개인정보 처리방침'),
            )
          ],
        ),
      ),
    );
  }
}