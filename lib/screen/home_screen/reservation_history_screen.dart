import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ReservationHistoryScreen extends StatefulWidget {
  @override
  _ReservationHistoryScreenState createState() => _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState extends State<ReservationHistoryScreen> {
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  // 서버에서 예약 목록 가져오기 (모든 상태 포함)
  Future<void> _fetchReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://172.20.10.7:3000/api/reservations?includeAll=true'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _reservations = List<Map<String, dynamic>>.from(data['reservations'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '예약 내역을 불러오는데 실패했습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '네트워크 오류가 발생했습니다.';
        _isLoading = false;
      });
    }
  }

  // 예약 취소
  Future<void> _cancelReservation(int reservationId, String parkingName) async {
    // 확인 다이얼로그 표시
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('예약 취소'),
        content: Text('$parkingName 예약을 취소하시겠습니까?\n취소된 예약은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('아니요'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('취소하기'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await http.put(
        Uri.parse('http://172.20.10.7:3000/api/reservations/$reservationId/cancel'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      // 로딩 다이얼로그 닫기
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('예약이 취소되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          // 예약 목록 새로고침
          _fetchReservations();
        } else {
          _showErrorMessage(responseData['message'] ?? '예약 취소에 실패했습니다.');
        }
      } else {
        _showErrorMessage('서버 오류가 발생했습니다.');
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      Navigator.pop(context);
      _showErrorMessage('네트워크 오류가 발생했습니다.');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 주차 위치 표시 형식 수정 (학교 주차장 처리)
  String _formatSpaceLocation(String spaceLocation, String parkingId) {
    // 학교 주차장인 경우 parkingId에서 번호 추출
    if (parkingId.startsWith('school_')) {
      final schoolNumber = parkingId.split('_').last;
      return '학교 ${schoolNumber}번';
    }
    
    // 일반 주차장은 기존 spaceLocation 그대로 사용
    return spaceLocation;
  }

  // 예약 상태에 따른 색상 반환
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  // 예약 상태에 따른 텍스트 반환
  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return '활성';
      case 'completed':
        return '완료';
      case 'canceled':
        return '취소됨';
      default:
        return '알 수 없음';
    }
  }

  // 날짜 및 시간 포맷팅
  String _formatDateTime(String date, String time) {
    try {
      final dateTime = DateTime.parse('$date $time:00');
      return DateFormat('M월 d일 (E) HH:mm', 'ko_KR').format(dateTime);
    } catch (e) {
      return '$date $time';
    }
  }

  // 예약 카드 위젯
  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    final status = reservation['status'] ?? 'unknown';
    final canCancel = status == 'active';
    final dateStr = reservation['date']?.toString()?.split('T')[0] ?? '';
    final startTime = reservation['startTime'] ?? '';
    final endTime = reservation['endTime'] ?? '';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canCancel
            ? () => _cancelReservation(
                  reservation['id'],
                  reservation['parkingName'] ?? '주차장',
                )
            : null,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 주차장 이름과 상태
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      reservation['parkingName'] ?? '주차장',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // 예약 정보
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    _formatDateTime(dateStr, startTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    ' ~ ${endTime}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.local_parking, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    reservation['spaceLocation'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    reservation['vehicleInfo'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // 하단: 가격과 액션
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${reservation['totalPrice'] ?? 0}원',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A896),
                    ),
                  ),
                  if (canCancel)
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 16,
                          color: Colors.red,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '탭하여 취소',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('예약 내역'),
        backgroundColor: Color(0xFF00A896),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchReservations,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          // 안내 메시지
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Text(
              '💡 완료된 예약은 회색으로 표시되며 취소할 수 없습니다',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // 메인 콘텐츠
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchReservations,
                              child: Text('다시 시도'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF00A896),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _reservations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '예약 내역이 없습니다',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '지도에서 주차장을 선택하여\n첫 예약을 진행해보세요',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchReservations,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              itemCount: _reservations.length,
                              itemBuilder: (context, index) {
                                return _buildReservationCard(_reservations[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}