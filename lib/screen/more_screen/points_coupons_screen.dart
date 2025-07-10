import 'package:flutter/material.dart';

class PointsCouponsScreen extends StatelessWidget {
  final int points = 3200;
  final List<Map<String, String>> coupons = [
    {
      'title': '주차요금 2천 원 할인',
      'valid': '2025.04.30까지'
    },
    {
      'title': '첫 예약 100% 할인',
      'valid': '2025.05.10까지'
    },
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('포인트 및 쿠폰')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF00A896),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('내 포인트', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 4),
                Text('${points}P', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text('사용 가능 쿠폰', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          ...coupons.map((coupon) => Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coupon['title']!, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(coupon['valid']!, style: TextStyle(color: Colors.grey[600]))
              ],
            ),
          ))
        ],
      ),
    );
  }
}