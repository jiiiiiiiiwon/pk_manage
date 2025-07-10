import 'package:flutter/material.dart';

class FAQScreen extends StatefulWidget {
  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<Map<String, String>> faqList = [
    {
      'question': '예약은 어떻게 하나요?',
      'answer': '지도 화면에서 원하는 주차장을 선택하고 예약 버튼을 눌러 진행하세요.'
    },
    {
      'question': '포인트는 어떻게 사용하나요?',
      'answer': '결제 시 보유 포인트를 차감하여 사용할 수 있습니다.'
    },
    {
      'question': '쿠폰 유효기간은 어디서 확인하나요?',
      'answer': '더보기 > 포인트 및 쿠폰 메뉴에서 확인 가능합니다.'
    },
  ];
  final List<bool> expanded = [false, false, false];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('자주 묻는 질문')),
      body: ListView.builder(
        itemCount: faqList.length,
        itemBuilder: (context, index) {
          return ExpansionPanelList(
            expansionCallback: (i, isOpen) {
              setState(() => expanded[index] = !isOpen);
            },
            animationDuration: Duration(milliseconds: 200),
            children: [
              ExpansionPanel(
                isExpanded: expanded[index],
                headerBuilder: (context, isOpen) => ListTile(
                  title: Text(faqList[index]['question']!, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                body: ListTile(
                  title: Text(faqList[index]['answer']!),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}