import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:capstone_design/screen/map_screen.dart';

class ParkingReservationScreen extends StatefulWidget {
  final ParkingLotInfo parkingInfo;
  final LatLng location;
  final Function(ParkingLotInfo)? onParkingInfoUpdate;

  const ParkingReservationScreen({
    Key? key,
    required this.parkingInfo,
    required this.location,
    this.onParkingInfoUpdate,
  }) : super(key: key);

  @override
  State<ParkingReservationScreen> createState() => _ParkingReservationScreenState();
}

class ParkingSpace {
  final String id;
  final int row;
  final int col;
  final String floor;
  final bool isAvailable;
  final String? type; // 'regular', 'disabled', 'electric' 등
  final String? dataSource; // 'camera', 'sensor' 등

  ParkingSpace({
    required this.id,
    required this.row,
    required this.col,
    required this.floor,
    required this.isAvailable,
    this.type = 'regular',
    this.dataSource,
  });
}

class _ParkingReservationScreenState extends State<ParkingReservationScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(
    hour: TimeOfDay.now().hour + 2,
    minute: TimeOfDay.now().minute,
  );
  int _duration = 2; // 시간 단위
  String? _selectedVehicle;
  final List<String> _vehicles = ['자동차 1 (12가 3456)', '자동차 2 (78다 9012)'];
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // 동적 주차장 레이아웃 저장소
  Map<String, List<ParkingSpace>> floorLayouts = {}; // 층별 주차 공간 저장
  List<String> availableFloors = []; // 사용 가능한 층 목록
  
  ParkingSpace? selectedSpace;
  String _selectedFloor = ''; // 동적으로 설정
  bool _isLoading = false;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // 한국어 로케일 초기화
    initializeDateFormatting('ko_KR', null);
    _selectedVehicle = _vehicles.isNotEmpty ? _vehicles.first : null;
    
    // 주차장 레이아웃 초기화 (빈 상태로 시작)
    initializeEmptyLayouts();

    // 초기 주차 정보 업데이트
    _updateParkingInfoInMap();

    // 서버에서 주차장 상태 가져오기
    _fetchParkingStatus();

    // 타이머 초기화 - 30초마다 주차장 자동 업데이트
    _refreshTimer = Timer.periodic(Duration(seconds: 180), (timer) {
      if (mounted) {
        _fetchParkingStatus();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // 총 금액 계산
  int _calculateTotalPrice() {
    return widget.parkingInfo.pricePerHour * _duration;
  }

  // 주차 시간 계산
  void _updateDuration() {
    final int startMinutes = _startTime.hour * 60 + _startTime.minute;
    final int endMinutes = _endTime.hour * 60 + _endTime.minute;
    
    int durationMinutes = endMinutes - startMinutes;
    if (durationMinutes < 0) {
      durationMinutes += 24 * 60; // 다음 날로 넘어가는 경우
    }
    
    setState(() {
      _duration = (durationMinutes / 60).ceil(); // 시간 단위로 올림
    });
  }

  // 날짜 선택 다이얼로그
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // 시작 시간 선택 다이얼로그
  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    
    if (pickedTime != null && pickedTime != _startTime) {
      setState(() {
        _startTime = pickedTime;
        // 종료 시간도 자동으로 조정
        _endTime = TimeOfDay(
          hour: (_startTime.hour + _duration) % 24,
          minute: _startTime.minute,
        );
      });
    }
  }

  // 종료 시간 선택 다이얼로그
  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    
    if (pickedTime != null && pickedTime != _endTime) {
      setState(() {
        _endTime = pickedTime;
        // 주차 시간 업데이트
        _updateDuration();
      });
    }
  }

  // 전체 주차 공간 및 사용 가능한 공간 계산
  Map<String, int> _calculateParkingSpaces() {
    int totalSpaces = 0;
    int availableSpaces = 0;
    
    // 모든 층의 주차 공간 계산
    for (var floorSpaces in floorLayouts.values) {
      for (var space in floorSpaces) {
        totalSpaces++;
        if (space.isAvailable) {
          availableSpaces++;
        }
      }
    }
    
    return {
      'total': totalSpaces,
      'available': availableSpaces,
    };
  }

  // 빈 레이아웃으로 초기화
  void initializeEmptyLayouts() {
    floorLayouts = {};
    availableFloors = [];
    _selectedFloor = '';
  }

  // 서버에서 주차장 상태 가져오기
  Future<void> _fetchParkingStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await http.get(
        Uri.parse('http://172.20.10.7:3000/api/parking/status'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parkingZones = data['parkingZones'];
        
        // 주차장 데이터 업데이트
        _updateAllParkingLayoutsFromServer(parkingZones);
        
        // 주차 정보 업데이트
        _updateParkingInfoInMap();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주차장 정보가 업데이트되었습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주차장 정보를 가져오는데 실패했습니다: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주차장 정보를 가져오는 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 서버 데이터로부터 모든 주차장 레이아웃 업데이트
  void _updateAllParkingLayoutsFromServer(List<dynamic> parkingZones) {
    Map<String, List<ParkingSpace>> newLayouts = {};
    Set<String> floors = {};
    
    print('=== 서버 데이터 분석 시작 ===');
    print('서버에서 받은 주차 구역 수: ${parkingZones.length}');
    
    // 먼저 모든 데이터 확인
    for (int i = 0; i < parkingZones.length; i++) {
      var zone = parkingZones[i];
      String zoneId = zone['id'] ?? '';
      print('[$i] ID: $zoneId, status: ${zone['status']}, floor: ${zone['floor']}, dataSource: ${zone['data_source']}');
    }
    
    // Map을 사용하여 완전한 중복 제거 + 층별로 분리해서 처리
    Map<String, Map<String, dynamic>> floorData = {};
    
    for (var zone in parkingZones) {
      String zoneId = zone['id'] ?? '';
      if (zoneId.isEmpty) continue;
      
      // 층 정보 추출
      String floorKey = '';
      if (zoneId.startsWith('school_')) {
        floorKey = 'school';
      } else if (zoneId.startsWith('module_')) {
        var parts = zoneId.split('_');
        if (parts.length >= 2) {
          floorKey = parts[1]; // 1F, 2F 등
        }
      }
      
      if (floorKey.isEmpty || floorKey == 'unknown') continue;
      
      // 층별 키 생성: "2F_module_2F_1" 형태
      String floorSpecificKey = '${floorKey}_${zoneId}';
      floorData[floorSpecificKey] = zone;
    }
    
    print('=== 중복 제거 후 고유 데이터 ===');
    print('고유 주차 구역 수: ${floorData.length}');
    floorData.forEach((key, zone) {
      print('Key: $key, ID: ${zone['id']}, Status: ${zone['status']}');
    });
    
    // 고유한 데이터만 처리
    for (var entry in floorData.entries) {
      var zone = entry.value;
      String zoneId = zone['id'] ?? '';
      
      try {
        String status = zone['status'] ?? 'unknown';
        String dataSource = zone['data_source'] ?? 'unknown';
        String? floor = zone['floor'];
        
        // 주차 구역의 층 정보 결정
        String floorKey;
        if (zoneId.startsWith('school_')) {
          floorKey = 'school';
        } else if (floor != null && floor.isNotEmpty) {
          floorKey = floor;
        } else if (zoneId.startsWith('module_')) {
          var parts = zoneId.split('_');
          if (parts.length >= 2) {
            floorKey = parts[1];
          } else {
            continue;
          }
        } else {
          continue;
        }
        
        if (floorKey == 'unknown') continue;
        
        floors.add(floorKey);
        
        // 층별 레이아웃 초기화
        if (!newLayouts.containsKey(floorKey)) {
          newLayouts[floorKey] = [];
        }
        
        // 행, 열 정보 설정
        int row = 0;
        int col = 0;
        
        if (zoneId.startsWith('school_')) {
          int schoolNum = int.tryParse(zoneId.split('_').last) ?? 1;
          if (schoolNum <= 3) {
            row = 0;
            col = schoolNum - 1;
          } else {
            row = 1;
            col = schoolNum - 4;
          }
        } else if (zoneId.startsWith('module_')) {
          var parts = zoneId.split('_');
          if (parts.length >= 3) {
            int moduleNum = int.tryParse(parts[2]) ?? 1;
            row = 0;
            col = moduleNum - 1;
            print('✅ 모듈 배치: $zoneId -> moduleNum: $moduleNum, col: $col');
          }
        } else {
          col = 0;
          row = 0;
        }
        
        // 주차 공간 유형 결정
        String spaceType = 'regular';
        if (zoneId.contains('disabled') || dataSource == 'disabled') {
          spaceType = 'disabled';
        } else if (zoneId.contains('electric') || dataSource == 'electric') {
          spaceType = 'electric';
        }
        
        // 주차 공간 생성
        ParkingSpace space = ParkingSpace(
          id: zoneId,
          row: row,
          col: col,
          floor: floorKey,
          isAvailable: status == 'empty',
          type: spaceType,
          dataSource: dataSource,
        );
        
        // 층별 레이아웃에 추가
        newLayouts[floorKey]!.add(space);
        print('✅ 최종 생성: ${space.id} -> ${space.floor} (col: ${space.col}) (${space.isAvailable ? "가능" : "불가"})');
        
      } catch (e) {
        print('❌ 주차 구역 ${zoneId} 처리 중 오류: $e');
      }
    }
    
    // 각 층의 주차 공간을 행/열 순서로 정렬
    for (var floorKey in newLayouts.keys) {
      newLayouts[floorKey]!.sort((a, b) {
        if (a.row != b.row) return a.row.compareTo(b.row);
        return a.col.compareTo(b.col);
      });
    }
    
    setState(() {
      floorLayouts = newLayouts;
      // unknown 층을 제외하고 정렬
      availableFloors = floors.where((floor) => floor != 'unknown').toList()..sort();
      
      // 선택된 층이 없거나 더 이상 유효하지 않으면 첫 번째 층 선택
      if (_selectedFloor.isEmpty || !availableFloors.contains(_selectedFloor) || _selectedFloor == 'unknown') {
        _selectedFloor = availableFloors.isNotEmpty ? availableFloors.first : '';
      }
      
      // 선택된 공간이 더 이상 유효하지 않으면 초기화
      if (selectedSpace != null) {
        bool spaceStillExists = false;
        for (var spaces in floorLayouts.values) {
          if (spaces.any((space) => space.id == selectedSpace!.id)) {
            spaceStillExists = true;
            break;
          }
        }
        if (!spaceStillExists) {
          selectedSpace = null;
        }
      }
    });
    
    print('=== 최종 결과 ===');
    print('사용 가능한 층: ${availableFloors.join(", ")}');
    for (var floorKey in newLayouts.keys) {
      var spaces = newLayouts[floorKey]!;
      print('🏢 ${floorKey}: ${spaces.length}개');
      for (var space in spaces) {
        print('   📍 ${space.id} -> col: ${space.col} (${_getSpaceDisplayText(space)})');
      }
    }
  }

  // 층 전환 메서드
  void switchFloor(String floor) {
    setState(() {
      _selectedFloor = floor;
      selectedSpace = null;
    });
  }

  // 주차 공간 선택 메서드
  void selectParkingSpace(ParkingSpace space) {
    if (!space.isAvailable) return;
    
    setState(() {
      selectedSpace = space;
    });

    _updateParkingInfoInMap();
  }

  // 범례 아이템을 생성하는 헬퍼 메서드
  Widget buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // 주차장 레이아웃 빌드
  Widget buildParkingLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목과 새로고침 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '주차 자리 선택',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _fetchParkingStatus,
              tooltip: '주차장 정보 새로고침',
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // 층 전환 버튼 (동적 생성)
        if (availableFloors.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableFloors.map((floor) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton(
                    onPressed: () => switchFloor(floor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedFloor == floor ? Colors.blue : Colors.grey.shade300,
                      foregroundColor: _selectedFloor == floor ? Colors.white : Colors.black,
                    ),
                    child: Text(_getFloorDisplayName(floor)),
                  ),
                );
              }).toList(),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // 선택된 층에 따라 다른 레이아웃 표시
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade100,
          ),
          child: Column(
            children: [
              // 현재 선택된 층 표시
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _getFloorColor(_selectedFloor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${_getFloorDisplayName(_selectedFloor)} 주차구역',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 로딩 중이면 로딩 표시
              if (_isLoading)
                CircularProgressIndicator()
              // 선택된 층의 레이아웃 표시
              else if (_selectedFloor.isNotEmpty && floorLayouts.containsKey(_selectedFloor))
                _buildDynamicFloorLayout(_selectedFloor)
              else
                Center(
                  child: Text(
                    '주차장 정보가 없습니다.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              
              const SizedBox(height: 16),
            
              // 범례
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildLegendItem(Colors.white, '이용 가능'),
                  const SizedBox(width: 16),
                  buildLegendItem(Colors.grey.shade400, '이용 불가'),
                  const SizedBox(width: 16),
                  buildLegendItem(Colors.orange, '선택됨'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.accessible, size: 16),
                  const SizedBox(width: 4),
                  const Text('장애인 주차구역', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 16),
                  Icon(Icons.electric_car, size: 16),
                  const SizedBox(width: 4),
                  const Text('전기차 충전구역', style: TextStyle(fontSize: 12)),
                ],
              ),
              
              // 선택된 공간 정보
              if (selectedSpace != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '선택된 주차 공간: ${_getSpaceLocationString(selectedSpace!)}' +
                          (selectedSpace!.type == 'disabled' ? ' (장애인 주차구역)' : 
                          selectedSpace!.type == 'electric' ? ' (전기차 충전구역)' : ''),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // 층 표시 이름 가져오기
  String _getFloorDisplayName(String floor) {
    switch (floor) {
      case 'school':
        return '학교';
      case '1F':
        return '1층';
      case '2F':
        return '2층';
      case '3F':
        return '3층';
      default:
        return floor.isNotEmpty ? floor : '미확인';
    }
  }

  // 층별 색상 가져오기
  Color _getFloorColor(String floor) {
    switch (floor) {
      case 'school':
        return Colors.purple.shade300;
      case '1F':
        return Colors.blue.shade300;
      case '2F':
        return Colors.green.shade300;
      case '3F':
        return Colors.teal.shade300;
      default:
        return Colors.grey.shade400;
    }
  }

  // 동적 층 레이아웃 빌드
  Widget _buildDynamicFloorLayout(String floor) {
    if (!floorLayouts.containsKey(floor) || floorLayouts[floor]!.isEmpty) {
      return Center(child: Text('${_getFloorDisplayName(floor)}에 주차 공간이 없습니다.'));
    }
    
    List<ParkingSpace> spaces = floorLayouts[floor]!;
    
    // 학교 주차장의 경우 특별한 배치 사용
    if (floor == 'school') {
      return _buildSchoolSpecialLayout(spaces);
    }
    
    // 일반 주차장의 경우 그리드 배치
    return _buildGridLayout(spaces);
  }

  // 학교 주차장 특별 배치
  Widget _buildSchoolSpecialLayout(List<ParkingSpace> spaces) {
    // school_1, school_2, school_3 (윗줄)
    List<ParkingSpace> topRow = spaces.where((s) => ['school_1', 'school_2', 'school_3'].contains(s.id)).toList();
    // school_4, school_5, school_6, school_7 (아래줄)
    List<ParkingSpace> bottomRow = spaces.where((s) => ['school_4', 'school_5', 'school_6', 'school_7'].contains(s.id)).toList();
    
    return Column(
      children: [
        // 윗줄 (3칸)
        if (topRow.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: topRow.map((space) => _buildParkingSpaceWidget(space)).toList(),
          ),
        SizedBox(height: 15),
        // 아래줄 (4칸) - 왼쪽에 공백 추가
        if (bottomRow.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 공백
              SizedBox(width: 59),
              // 아래줄 4개 주차 공간
              ...bottomRow.map((space) => _buildParkingSpaceWidget(space)).toList(),
            ],
          ),
      ],
    );
  }

  // 그리드 배치 (일반 주차장용) - 한 줄로 배치
  Widget _buildGridLayout(List<ParkingSpace> spaces) {
    // 열 번호 순서로 정렬
    spaces.sort((a, b) => a.col.compareTo(b.col));
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: spaces.map((space) => _buildParkingSpaceWidget(space)).toList(),
      ),
    );
  }

  // 주차 공간 위젯 빌드
  Widget _buildParkingSpaceWidget(ParkingSpace space) {
    // 공간 상태에 따른 색상 결정
    Color spaceColor;
    IconData? icon;
    
    if (space.type == 'disabled') {
      icon = Icons.accessible;
      spaceColor = space.isAvailable ? Colors.blue.shade100 : Colors.grey.shade400;
    } else if (space.type == 'electric') {
      icon = Icons.electric_car;
      spaceColor = space.isAvailable ? Colors.green.shade100 : Colors.grey.shade400;
    } else {
      icon = null;
      spaceColor = space.isAvailable ? Colors.white : Colors.grey.shade400;
    }
    
    // 선택된 공간인 경우 색상 변경
    if (selectedSpace?.id == space.id) {
      spaceColor = Colors.orange;
    }
    
    return GestureDetector(
      onTap: space.isAvailable ? () => selectParkingSpace(space) : null,
      child: Container(
        width: 55, // 원래 비율로 복원
        height: 90, // 원래 비율로 복원
        margin: const EdgeInsets.all(2), // 원래 마진으로 복원
        decoration: BoxDecoration(
          color: spaceColor,
          border: Border.all(
            color: Colors.black,
            width: selectedSpace?.id == space.id ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 22), // 원래 크기로 복원
            const SizedBox(height: 6), // 원래 간격으로 복원
            Text(
              _getSpaceDisplayText(space),
              style: TextStyle(
                fontSize: 13, // 원래 크기로 복원
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3), // 원래 간격으로 복원
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // 원래 패딩으로 복원
              decoration: BoxDecoration(
                color: space.isAvailable 
                  ? Colors.green.shade100  
                  : Colors.red.shade100,   
                borderRadius: BorderRadius.circular(8), // 원래 크기로 복원
                border: Border.all(
                  color: space.isAvailable 
                    ? Colors.green.shade700 
                    : Colors.red.shade700,
                  width: 1,
                ),
              ),
              child: Text(
                space.isAvailable ? '가능' : '불가',
                style: TextStyle(
                  fontSize: 11, // 원래 크기로 복원
                  fontWeight: FontWeight.bold,
                  color: space.isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 주차 공간 표시 텍스트 가져오기
  String _getSpaceDisplayText(ParkingSpace space) {
    if (space.id.startsWith('school_')) {
      return '${space.id.split('_').last}번';
    } else if (space.id.startsWith('module_')) {
      var parts = space.id.split('_');
      if (parts.length >= 3) {
        // module_2F_1 -> "1번", module_2F_2 -> "2번" 등 (간단하게 표시)
        return '${parts[2]}번';
      }
    }
    
    // 기본 표시
    return '${space.col + 1}번';
  }

  // 공간 위치 문자열 가져오기
  String _getSpaceLocationString(ParkingSpace space) {
    if (space.id.startsWith('school_')) {
      final schoolNumber = space.id.split('_').last;
      return '학교 ${schoolNumber}번';
    } else if (space.id.startsWith('module_')) {
      var parts = space.id.split('_');
      if (parts.length >= 3) {
        // module_2F_1 -> "2층 1번", module_2F_2 -> "2층 2번" 등
        String floorName = _getFloorDisplayName(parts[1]);
        return '${floorName} ${parts[2]}번';
      }
    }
    
    return '${_getFloorDisplayName(space.floor)} ${space.col + 1}번';
  }

  void _updateParkingInfoInMap() {
    // 현재 사용 가능한 주차 공간 계산
    final parkingSpaces = _calculateParkingSpaces();
    
    // 상위 위젯에서 받은 주차장 정보 업데이트
    if (mounted && widget.parkingInfo != null) {
      final updatedInfo = ParkingLotInfo(
        id: widget.parkingInfo.id,
        name: widget.parkingInfo.name,
        address: widget.parkingInfo.address,
        totalSpaces: parkingSpaces['total']!,
        availableSpaces: parkingSpaces['available']!,
        pricePerHour: widget.parkingInfo.pricePerHour,
        openingHours: widget.parkingInfo.openingHours,
        features: widget.parkingInfo.features,
      );
      
      if (widget.onParkingInfoUpdate != null) {
        widget.onParkingInfoUpdate!(updatedInfo);
      }
    }
  }

  Future<void> _submitReservation() async {
    if (_formKey.currentState!.validate()) {
      // 주차 공간 선택 확인
      if (selectedSpace == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주차 공간을 선택해주세요')),
        );
        return;
      }
      
      try {
        // 로딩 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );
        
        // 선택한 공간의 현재 상태 다시 확인 (이중 체크)
        final checkResponse = await http.get(
          Uri.parse('http://172.20.10.7:3000/api/parking/check/${selectedSpace!.id}'),
        );
        
        if (checkResponse.statusCode == 200) {
          final checkData = jsonDecode(checkResponse.body);
          if (!checkData['isAvailable']) {
            // 로딩 닫기
            Navigator.pop(context);
            
            // 이미 예약된 공간
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('선택한 공간이 방금 예약되었습니다. 다른 공간을 선택해주세요.')),
            );
            
            // 주차장 정보 새로고침
            _fetchParkingStatus();
            return;
          }
        }
        
        // 예약 데이터 준비
        final Map<String, dynamic> reservationData = {
          'parkingId': selectedSpace!.id,
          'parkingName': widget.parkingInfo.name,
          'date': _selectedDate.toString(),
          'startTime': '${_startTime.hour}:${_startTime.minute}',
          'endTime': '${_endTime.hour}:${_endTime.minute}',
          'duration': _duration,
          'vehicleInfo': _selectedVehicle,
          'totalPrice': _calculateTotalPrice(),
          'spaceLocation': _getSpaceLocationString(selectedSpace!),
        };

        // 서버로 POST 요청 보내기
        final response = await http.post(
          Uri.parse('http://172.20.10.7:3000/api/reservations'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(reservationData),
        );

        // 로딩 닫기
        Navigator.pop(context);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          
          if (responseData != null && responseData['success'] == true) {
            // 성공적으로 예약됨
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('예약이 완료되었습니다!')),
            );
            
            // 예약된 공간 상태 업데이트
            if (selectedSpace != null) {
              setState(() {
                // 해당 층의 해당 공간을 찾아서 상태 업데이트
                if (floorLayouts.containsKey(selectedSpace!.floor)) {
                  for (int i = 0; i < floorLayouts[selectedSpace!.floor]!.length; i++) {
                    if (floorLayouts[selectedSpace!.floor]![i].id == selectedSpace!.id) {
                      floorLayouts[selectedSpace!.floor]![i] = ParkingSpace(
                        id: selectedSpace!.id,
                        row: selectedSpace!.row,
                        col: selectedSpace!.col,
                        floor: selectedSpace!.floor,
                        isAvailable: false,
                        type: selectedSpace!.type,
                        dataSource: selectedSpace!.dataSource,
                      );
                      break;
                    }
                  }
                }
              });
            }
            
            // 예약 확인 페이지로 이동하거나 이전 화면으로 돌아가기
            Navigator.pop(context);
          } else {
            // 서버에서 success: false 반환
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('예약 중 오류가 발생했습니다: ${responseData['message'] ?? '알 수 없는 오류'}')),
            );
          }
        } else {
          // 서버 오류 처리
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('예약 중 오류가 발생했습니다: ${response.body}')),
          );
        }
      } catch (e) {
        // 예외 처리
        // 로딩 닫기 (예외 발생 시도 닫히도록)
        Navigator.of(context, rootNavigator: true).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('예약 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('주차 예약하기'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 주차장 정보
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.parkingInfo.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.parkingInfo.address),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.local_parking, color: Colors.blue, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '주차 가능: ${widget.parkingInfo.availableSpaces}/${widget.parkingInfo.totalSpaces}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.attach_money, color: Colors.green, size: 20),
                        const SizedBox(width: 4),
                        Text('시간당 ${widget.parkingInfo.pricePerHour}원'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 날짜 선택
            ListTile(
              title: const Text('예약 날짜'),
              subtitle: Text(dateFormat.format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            
            const Divider(),
            
            // 시간 선택
            ListTile(
              title: const Text('시작 시간'),
              subtitle: Text('${_startTime.hour}시 ${_startTime.minute}분'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectStartTime(context),
            ),
            
            ListTile(
              title: const Text('종료 시간'),
              subtitle: Text('${_endTime.hour}시 ${_endTime.minute}분'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectEndTime(context),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('주차 시간:'),
                  Text(
                    '$_duration시간',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // 차량 선택
            if (_vehicles.isNotEmpty) ...[
              ListTile(
                title: const Text('차량 선택'),
                subtitle: DropdownButtonFormField<String>(
                  value: _selectedVehicle,
                  items: _vehicles.map((vehicle) {
                    return DropdownMenuItem<String>(
                      value: vehicle,
                      child: Text(vehicle),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicle = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '차량을 선택해주세요';
                    }
                    return null;
                  },
                ),
              ),
            ] else ...[
              ListTile(
                title: const Text('차량 정보'),
                subtitle: TextFormField(
                  decoration: const InputDecoration(
                    hintText: '차량 번호를 입력하세요',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '차량 번호를 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            buildParkingLayout(),
            const SizedBox(height: 24),
            
            // 결제 정보
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('시간당 요금:'),
                        Text('${widget.parkingInfo.pricePerHour}원'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('주차 시간:'),
                        Text('$_duration시간'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '총 결제 금액:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_calculateTotalPrice()}원',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 예약 버튼
            ElevatedButton(
              onPressed: _submitReservation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '예약하기',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}