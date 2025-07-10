import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MyPageScreen extends StatelessWidget {
  final bool hasCarImage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('마이페이지', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Container(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('12가 3456', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('2024년 1월부터 함께하고 있어요', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          _buildListItem(context, Icons.edit, '차량 정보 수정', '차량 번호, 차종 변경', EditCarInfoScreen()),
          _buildListItem(context, Icons.person, '내 정보 수정', '이름, 연락처 등 개인정보 변경', EditUserInfoScreen()),
          _buildListItem(context, Icons.bar_chart, '이용 내역 보기', '이달의 사용량과 요금 그래프', UsageStatsScreen()),
          _buildListItem(context, Icons.map, '차량 이동 히스토리', '최근 주차 장소 타임라인 보기', CarHistoryScreen()),
          _buildListItem(context, Icons.headset_mic, '고객센터 문의하기', '새로운 문의 등록하기', CustomerSupportScreen()),
          _buildListItem(context, Icons.question_answer, '내가 고객센터에 문의했던 내용', '내 문의 내역 확인', CustomerInquiryScreen()),
          _buildListItem(context, Icons.settings, '앱 설정', '알림 설정, 로그아웃 등', AppSettingsScreen()),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, IconData icon, String title, String subtitle, Widget screen) {
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
      ),
    );
  }
}

// 1. 차량 정보 수정
class EditCarInfoScreen extends StatelessWidget {
  final TextEditingController numberController = TextEditingController();
  final TextEditingController typeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('차량 정보 수정')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.add_a_photo, size: 30, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text('차량 사진 추가', style: TextStyle(color: Colors.grey[700]))
                ],
              ),
            ),
            SizedBox(height: 24),
            Text('차량 번호', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: numberController,
              decoration: InputDecoration(hintText: '예: 12가 3456'),
            ),
            SizedBox(height: 20),
            Text('차종', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: typeController,
              decoration: InputDecoration(hintText: '예: SUV, 소형차 등'),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00A896)),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('저장'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// 2. 내 정보 수정
class EditUserInfoScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController paymentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('내 정보 수정')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person_add_alt_1, size: 30, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text('프로필 사진 추가', style: TextStyle(color: Colors.grey[700]))
                ],
              ),
            ),
            SizedBox(height: 24),
            Text('이름', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: '홍길동'),
            ),
            SizedBox(height: 20),
            Text('연락처', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(hintText: '010-0000-0000'),
            ),
            SizedBox(height: 20),
            Text('이메일', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(hintText: 'example@email.com'),
            ),
            SizedBox(height: 20),
            Text('결제수단 등록', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: paymentController,
              decoration: InputDecoration(hintText: '예: 현대카드 1234'),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00A896)),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('저장'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// 3. 이용 내역
class UsageStatsScreen extends StatelessWidget {
  final List<BarChartGroupData> data = [
    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 3, color: Color(0xFF00A896))]),
    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 5, color: Color(0xFF00A896))]),
    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 2, color: Color(0xFF00A896))]),
    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 6, color: Color(0xFF00A896))]),
    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 4, color: Color(0xFF00A896))]),
  ];

  final List<String> labels = ['월', '화', '수', '목', '금'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('이용 내역 보기')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이번 주 주차 내역', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          return Text(index >= 0 && index < labels.length ? labels[index] : '', style: TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: data,
                ),
              ),
            ),
            SizedBox(height: 32),
            Text('총 주차 횟수: 20회', style: TextStyle(fontSize: 16)),
            Text('총 이용 요금: ₩24,000', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// 4. 차량 이동 히스토리
class CarHistoryScreen extends StatelessWidget {
  final List<Map<String, String>> history = [
    {'location': '강남역 공영주차장', 'datetime': '2025.04.01 08:30', 'tag': '출근'},
    {'location': '롯데마트 잠실점', 'datetime': '2025.04.03 18:45', 'tag': '장보기'},
    {'location': '한강공원 주차장', 'datetime': '2025.04.05 14:20', 'tag': '산책'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('차량 이동 히스토리')),
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: history.length,
        separatorBuilder: (context, index) => Divider(color: Colors.black12),
        itemBuilder: (context, index) {
          final item = history[index];
          return ListTile(
            leading: Icon(Icons.place, color: Color(0xFF00A896)),
            title: Text(item['location']!),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['datetime']!, style: TextStyle(fontSize: 12)),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFE0F7F4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item['tag']!, style: TextStyle(fontSize: 12, color: Color(0xFF007A6D))),
                )
              ],
            ),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          );
        },
      ),
    );
  }
}

// 5. 고객센터 문의
class CustomerSupportScreen extends StatefulWidget {
  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('고객센터 문의하기')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('문의 제목', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: titleController,
              decoration: InputDecoration(hintText: '예: 예약 취소하고 싶어요'),
            ),
            SizedBox(height: 20),
            Text('문의 내용', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: contentController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: '문의하고 싶은 내용을 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00A896)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('문의가 등록되었습니다')),
                  );
                  Navigator.pop(context);
                },
                child: Text('문의하기'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// 6. 고객센터 문의 내용
class CustomerInquiryScreen extends StatelessWidget {
  final List<Map<String, String>> inquiries = [
    {
      'title': '예약 취소는 어떻게 하나요?',
      'date': '2025.04.01',
      'answer': '앱 내 마이페이지 > 이용 내역에서 예약 취소가 가능합니다.'
    },
    {
      'title': '포인트 유효기간이 궁금해요',
      'date': '2025.04.03',
      'answer': ''
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('내 문의 내역')),
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: inquiries.length,
        separatorBuilder: (context, index) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = inquiries[index];
          final hasAnswer = item['answer'] != null && item['answer']!.isNotEmpty;

          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                Text(item['date']!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                SizedBox(height: 12),
                Text('답변', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  hasAnswer ? item['answer']! : '답변 대기 중입니다.',
                  style: TextStyle(color: hasAnswer ? Colors.black87 : Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 7. 앱 설정
class AppSettingsScreen extends StatefulWidget {
  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool notificationsEnabled = true;
  bool autoLogin = false;
  String selectedLanguage = '한국어';
  final List<String> languages = ['한국어', 'English'];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('앱 설정')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('알림 받기'),
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() => notificationsEnabled = value);
            },
          ),
          SwitchListTile(
            title: Text('자동 로그인'),
            value: autoLogin,
            onChanged: (value) {
              setState(() => autoLogin = value);
            },
          ),
          ListTile(
            title: Text('언어 설정'),
            subtitle: Text(selectedLanguage),
            onTap: () async {
              final lang = await showDialog<String>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: Text('언어 선택'),
                  children: languages.map((lang) => SimpleDialogOption(
                    child: Text(lang),
                    onPressed: () => Navigator.pop(context, lang),
                  )).toList(),
                ),
              );
              if (lang != null) setState(() => selectedLanguage = lang);
            },
          ),
          SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: Size(double.infinity, 48),
              ),
              onPressed: () {
                // 로그아웃 기능 처리 예정
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 10),
                  Text('로그아웃'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}