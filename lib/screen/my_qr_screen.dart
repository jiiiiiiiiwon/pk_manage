import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class MyQRScreen extends StatefulWidget {
  @override
  _MyQRScreenState createState() => _MyQRScreenState();
}

class _MyQRScreenState extends State<MyQRScreen> {
  List<Map<String, dynamic>> _activeReservations = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedReservationIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchActiveReservations();
  }

  // 활성화된 예약 정보 가져오기
  Future<void> _fetchActiveReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://172.20.10.7:3000/api/reservations?includeAll=false'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reservations = List<Map<String, dynamic>>.from(data['reservations'] ?? []);
        
        // 활성화된 예약만 필터링 (status가 'active'인 것)
        final activeReservations = reservations.where((reservation) => 
          reservation['status'] == 'active'
        ).toList();

        setState(() {
          _activeReservations = activeReservations;
          _isLoading = false;
        });

        if (_activeReservations.isEmpty) {
          setState(() {
            _errorMessage = '활성화된 예약이 없습니다.';
          });
        }
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

  // QR 코드 데이터 생성
  String _generateQRData(Map<String, dynamic> reservation) {
    final qrData = {
      'reservationId': reservation['id'],
      'parkingId': reservation['parkingId'],
      'parkingName': reservation['parkingName'],
      'date': reservation['date'].toString().split('T')[0], // YYYY-MM-DD 형식
      'startTime': reservation['startTime'],
      'endTime': reservation['endTime'],
      'duration': reservation['duration'],
      'vehicleInfo': reservation['vehicleInfo'],
      'totalPrice': reservation['totalPrice'],
      'spaceLocation': reservation['spaceLocation'],
      'status': reservation['status'],
      'generatedAt': DateTime.now().toIso8601String(),
    };

    return jsonEncode(qrData);
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

  // 예약 선택 드롭다운
  Widget _buildReservationSelector() {
    if (_activeReservations.length <= 1) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedReservationIndex,
          isExpanded: true,
          hint: Text('예약을 선택하세요'),
          items: _activeReservations.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> reservation = entry.value;
            
            return DropdownMenuItem<int>(
              value: index,
              child: Text(
                '${reservation['parkingName']} - ${_formatDateTime(
                  reservation['date'].toString().split('T')[0], 
                  reservation['startTime']
                )}',
                style: TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (int? newIndex) {
            if (newIndex != null) {
              setState(() {
                _selectedReservationIndex = newIndex;
              });
            }
          },
        ),
      ),
    );
  }

  // 예약 정보 카드
  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    final dateStr = reservation['date']?.toString()?.split('T')[0] ?? '';
    final startTime = reservation['startTime'] ?? '';
    final endTime = reservation['endTime'] ?? '';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  '활성',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                _formatDateTime(dateStr, startTime),
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                ' ~ $endTime',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
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
              Text(
                '예약 ID: ${reservation['id']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내 QR 코드'),
        backgroundColor: Color(0xFF00A896),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchActiveReservations,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
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
                        onPressed: _fetchActiveReservations,
                        child: Text('다시 시도'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00A896),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // 예약 선택 드롭다운 (예약이 여러 개인 경우만)
                      _buildReservationSelector(),
                      
                      // 선택된 예약 정보
                      if (_activeReservations.isNotEmpty)
                        _buildReservationCard(_activeReservations[_selectedReservationIndex]),
                      
                      SizedBox(height: 2),
                      
                      // QR 코드 표시
                      if (_activeReservations.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(20),
                          margin: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '주차 예약 QR 코드',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00A896),
                                ),
                              ),
                              SizedBox(height: 16),
                              QrImageView(
                                data: _generateQRData(_activeReservations[_selectedReservationIndex]),
                                version: QrVersions.auto,
                                size: 250.0,
                                backgroundColor: Colors.white,
                                dataModuleStyle: QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                                eyeStyle: QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF00A896),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                '이 QR 코드를 주차장 입구에서 스캔해주세요',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '생성 시간: ${DateFormat('HH:mm').format(DateTime.now())}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // 하단 정보
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            SizedBox(height: 8),
                            Text(
                              '이 QR 코드는 예약 확인 및 주차장 출입에 사용됩니다.\n타인과 공유하지 마세요.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      // 추가 여백 (하단 네비게이션 바와의 간격)
                      SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}