import 'package:flutter/material.dart';
import 'package:capstone_design/screen/my_page_screen.dart';
import 'package:capstone_design/screen/more_screen/app_info_screen.dart';
import 'package:capstone_design/screen/more_screen/points_coupons_screen.dart';
import 'package:capstone_design/screen/more_screen/faq_screen.dart';

class MoreScreen extends StatelessWidget {
  final bool hasCarImage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('더보기', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // 사용자 정보 카드
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyPageScreen()),
              );
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: hasCarImage
                        ? AssetImage('assets/my_car.jpg')
                        : null,
                    backgroundColor: hasCarImage ? Colors.transparent : Colors.grey[300],
                    child: hasCarImage ? null : Icon(Icons.directions_car, size: 32, color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('12가 3456', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('2024년 1월부터 함께하고 있어요', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // 서비스 섹션
          _buildSectionTitle('서비스'),
          _buildListItem(context, Icons.history, '이용 내역', '예약 및 주차 사용 내역'),
          _buildListItem(context, Icons.favorite, '즐겨찾기', '자주 이용하는 주차장'),
          _buildListItem(context, Icons.discount, '쿠폰함', '사용 가능한 할인 쿠폰', 
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PointsCouponsScreen()),
              );
            }
          ),
          
          SizedBox(height: 16),
          
          // 정보 섹션
          _buildSectionTitle('정보'),
          _buildListItem(context, Icons.notifications, '공지사항', '서비스 업데이트 및 안내'),
          _buildListItem(context, Icons.info, '서비스 소개', '어디대 서비스 이용 방법'),
          _buildListItem(context, Icons.help, '자주 묻는 질문', 'FAQ',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FAQScreen()),
              );
            }
          ),
          _buildListItem(context, Icons.info_outline, '앱 정보', '버전 및 개발자 정보',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AppInfoScreen()),
              );
            }
          ),
          
          SizedBox(height: 16),
          
          // 마이페이지 버튼
          Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: ListTile(
              leading: Icon(Icons.person, color: Color(0xFF00A896)),
              title: Text('마이페이지', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('개인정보 및 설정 관리'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyPageScreen()),
                );
              },
            ),
          ),
          
          // 설정 섹션
          _buildSectionTitle('설정'),
          _buildListItem(context, Icons.settings, '앱 설정', '알림, 언어, 로그아웃 등',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AppSettingsScreen()),
              );
            }
          ),
          _buildListItem(context, Icons.headset_mic, '고객센터', '문의하기 및 도움말',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CustomerSupportScreen()),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFF00A896)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap ?? () {
          // 기본 동작 - 아직 구현되지 않은 화면에 대한 처리
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('준비 중인 기능입니다')),
          );
        },
      ),
    );
  }
}