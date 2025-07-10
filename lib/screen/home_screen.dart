import 'package:flutter/material.dart';
import 'dart:io';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:capstone_design/screen/my_page_screen.dart';
import 'package:capstone_design/screen/more_screen.dart';
import 'package:capstone_design/screen/map_screen.dart';
import 'package:capstone_design/screen/place_search_screen.dart';
import 'package:capstone_design/screen/home_screen/reservation_history_screen.dart';
import 'package:capstone_design/screen/login_screen.dart'; // 로그인 화면 import 추가
import 'package:capstone_design/screen/my_qr_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? _lastScannedCode;
  
  // 검색 위치 저장을 위한 변수 추가
  LatLng? _selectedLocation;
  String? _selectedPlaceName;

  @override
  Widget build(BuildContext context) {
    print("MainScreen의 build 메서드 호출됨");
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR인식'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: '더보기'),
        ],
      ),
    );
  }

  // _MainScreenState 클래스 내부에서 _buildBody 메서드 수정
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _homePage();
      case 1:
        // 검색 화면
        return PlaceSearchScreen(
          onPlaceSelected: (location, placeName) {
            print("장소 선택됨: $location, $placeName");
            if (location != null && placeName != null) {
              // 선택된 위치 정보 업데이트
              setState(() {
                // 깊은 복사를 통해 새 객체 생성
                _selectedLocation = LatLng(location.latitude, location.longitude);
                _selectedPlaceName = placeName;
              });
              
              // 약간의 지연 후 지도 화면으로 전환 (컴포넌트 렌더링 시간 확보)
              Future.delayed(Duration(milliseconds: 100), () {
                if (mounted) {
                  setState(() {
                    _currentIndex = 2; // 지도 탭으로 전환
                  });
                }
              });
            }
          },
        );
      case 2:
        // 지도 화면 - 아주 중요: 위치가 변경될 때마다 새 키로 화면 강제 재생성
        return MapScreen(
          key: UniqueKey(), // 매번 새로운 키 생성하여 위젯 강제 재생성
          initialLocation: _selectedLocation,
          placeName: _selectedPlaceName,
          clearSelection: () {
            print("위치 선택 정보 초기화");
            setState(() {
              _selectedLocation = null;
              _selectedPlaceName = null;
            });
          },
        );
      case 3:
        return _qrPage();
      case 4:
        return MoreScreen();
      default:
        return _homePage();
    }
  }

  Widget _homePage() {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 헤더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/img/splash_logo.png',
                            width: 40,
                          ),
                          SizedBox(width: 6),
                          Text('어디대',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800]
                            ),
                          ),
                        ],
                      ),
                      // 프로필 아이콘 클릭시 마이페이지로 이동
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyPageScreen()),
                          );
                        },
                        child: Icon(Icons.person_outline, color: Colors.grey[600], size: 26),
                      )
                    ],
                  ),
                  SizedBox(height: 10),

                  // 카드 그리드
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildCard(
                          '어디대는지 알려줄게', 
                          '누르면 지도에서 이동', 
                          Colors.teal[300]!, 
                          Icons.directions_car,
                          onTap: () {
                            // 네비게이션 바를 통해 지도 페이지로 이동
                            setState(() {
                              _currentIndex = 2; // 지도 탭의 인덱스(0부터 시작)
                            });
                          }
                        ),
                        _buildCard(
                          '어디 뒀는지 알려줄게', 
                          '최근 주차 위치 보기', 
                          Colors.blue[900]!, 
                          LucideIcons.key,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ParkingLocationPage()),
                            );
                          }
                        ),
                        _buildCard(
                          '자주 가는 곳이야?', 
                          '즐겨찾기한 주차장', 
                          const Color.fromARGB(255, 212, 144, 42)!, 
                          Icons.push_pin,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FavoritesPage()),
                            );
                          }
                        ),
                        _buildCard(
                          '언제, 얼마였는지 궁금해?', 
                          '예약 내역 / 예약 취소', 
                          const Color.fromARGB(255, 132, 129, 160)!, 
                          LucideIcons.receipt,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ReservationHistoryScreen()),
                            );
                          }
                        ),
                        _buildCard(
                          '남는 공간 있어?', 
                          '내 주차 공간 공유 등록', 
                          const Color.fromARGB(255, 120, 112, 112)!, 
                          Icons.local_parking,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ShareParkingPage()),
                            );
                          }
                        ),
                        _buildCard(
                          '미리 예약해둘까?', 
                          '정기권 구매 / 사전 예약', 
                          Colors.teal[200]!, 
                          Icons.calendar_today,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ReservationPage()),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 사용 설명 버튼
            Positioned(
              left: 16,
              bottom: 80,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.help_outline, size: 18, color: Colors.grey[800]),
                label: Text('사용 설명', style: TextStyle(color: Colors.grey[800])),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 1,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: StadiumBorder(),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),

            // 개발용 로그인 버튼 추가
            Positioned(
              right: 16,
              bottom: 80,
              child: ElevatedButton.icon(
                onPressed: () {
                  // 로그인 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                icon: Icon(Icons.login, size: 18, color: Colors.white),
                label: Text('로그인', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  elevation: 2,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      )
    );
  }

  Widget _buildCard(String title, String subtitle, Color color, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.white),
            SizedBox(height: 12),
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
          ],
        ),
      ),
    );
  }

  Widget _qrPage() {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
              width: 200,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyQRScreen()),
                  );
                },
                icon: Icon(Icons.qr_code, size: 24),
                label: Text('내 QR코드'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00A896),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // QR 코드 스캔 버튼 (기존)
            Container(
              width: 200,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _showQRBottomSheet,
                icon: Icon(Icons.qr_code_scanner, size: 24),
                label: Text('QR 코드 스캔'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
            
            if (_lastScannedCode != null) ...[
              SizedBox(height: 30),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '최근 스캔 결과',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        _lastScannedCode!,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 30),
            
            // 설명 텍스트
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(16),
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
                    '• 내 QR코드: 예약한 주차장 정보를 QR코드로 확인\n• QR 코드 스캔: 다른 QR코드를 스캔하여 정보 확인',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // 바텀시트 내에서 QR 스캐너가 적절히 표시되도록 수정
  void _showQRBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        // 기기별 화면 크기 차이 고려
        final double screenHeight = MediaQuery.of(context).size.height;
        final double screenWidth = MediaQuery.of(context).size.width;
        bool isSmallScreen = screenWidth < 380; // iPhone SE와 같은 작은 화면 감지
        
        return Container(
          height: screenHeight * (isSmallScreen ? 0.85 : 0.9), // 작은 화면에서는 조금 더 작게
          child: Stack(
            children: [
              // 반투명 배경
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
              // 모달 시트
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: screenHeight * (isSmallScreen ? 0.8 : 0.85),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 상단 바
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              'QR 코드 스캔',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 20 : 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // QR 스캐너 영역 - 작은 화면에서도 적절한 비율 유지
                      Expanded(
                        flex: 10, // 더 많은 공간 할당
                        child: Container(
                          // 약간의 패딩 추가
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8.0 : 12.0,
                            vertical: isSmallScreen ? 4.0 : 8.0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: QRScannerView(
                              onScanSuccess: (String scannedCode) {
                                Navigator.pop(context);
                                setState(() {
                                  _lastScannedCode = scannedCode;
                                });
                                _processScannedCode(scannedCode);
                              },
                            ),
                          ),
                        ),
                      ),
                      // 하단 컨트롤 - 작은 화면에서는 더 작게
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 8.0 : 12.0,
                          horizontal: 16.0,
                        ),
                        child: Column(
                          children: [
                            Text(
                              'QR 코드를 화면에 맞춰주세요',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _pickQRFromGallery();
                                  },
                                  icon: Icon(Icons.photo_library, size: isSmallScreen ? 18 : 22),
                                  label: Text('갤러리'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[100],
                                    foregroundColor: Colors.green,
                                    padding: isSmallScreen
                                        ? EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                                        : EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _toggleFlash();
                                  },
                                  icon: Icon(Icons.flashlight_on, size: isSmallScreen ? 18 : 22),
                                  label: Text('라이트'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[100],
                                    foregroundColor: Colors.green,
                                    padding: isSmallScreen
                                        ? EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                                        : EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _processScannedCode(String code) {
    // TODO: 스캔된 QR 코드를 처리하는 로직 추가
    print('QR 코드 스캔 결과: $code');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('QR 코드 스캔 완료: $code'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _pickQRFromGallery() async {
    // 갤러리에서 QR 코드 선택하는 로직 (추후 구현)
    print('갤러리에서 QR 코드 선택');
  }

  void _toggleFlash() {
    // 플래시 토글 기능 (추후 구현)
    print('플래시 토글');
  }
}

// QR 스캐너 위젯
class QRScannerView extends StatefulWidget {
  final Function(String) onScanSuccess;

  const QRScannerView({Key? key, required this.onScanSuccess}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool _isFlashOn = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return _buildQrView(context);
  }

  Widget _buildQrView(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scanArea = screenWidth * 0.8;
    
    if (screenWidth < 380) {
      scanArea = screenWidth * 0.7;
    }
    
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.green,
        borderRadius: 15,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
        cutOutBottomOffset: 0,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    int counter = 0;
    controller.scannedDataStream.listen((scanData) async {
      counter++;
      await controller.pauseCamera();

      if (counter == 1 && scanData.code != null) {
        widget.onScanSuccess(scanData.code!);
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라 권한이 필요합니다')),
      );
    }
  }

  Future<void> toggleFlash() async {
    if (controller != null) {
      await controller!.toggleFlash();
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class MapDirectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('지도에서 이동'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 100, color: Colors.teal),
            SizedBox(height: 20),
            Text('지도 기능이 여기에 구현될 예정입니다.', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class ParkingLocationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('최근 주차 위치'),
        backgroundColor: Colors.blue[900],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.key, size: 100, color: Colors.blue[900]),
            SizedBox(height: 20),
            Text('최근에 주차한 위치를 보여줍니다.', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('즐겨찾기한 주차장'),
        backgroundColor: Colors.yellow[700],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.push_pin, size: 100, color: Colors.yellow[700]),
            SizedBox(height: 20),
            Text('즐겨찾기한 주차장 목록을 보여줍니다.', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class PaymentHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('결제 내역 / 예약 확인'),
        backgroundColor: Colors.grey[600],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.receipt, size: 100, color: Colors.grey[600]),
            SizedBox(height: 20),
            Text('결제 내역과 예약 정보를 보여줍니다.', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class ShareParkingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('주차 공간 공유 등록'),
        backgroundColor: Colors.grey[700],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_parking, size: 100, color: Colors.grey[700]),
            SizedBox(height: 20),
            Text('내 주차 공간을 다른 사람과 공유하기 위한 등록 페이지입니다.', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class ReservationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('정기권 구매 / 사전 예약'),
        backgroundColor: Colors.teal[300],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 100, color: Colors.teal[300]),
            SizedBox(height: 20),
            Text('정기권 구매나 주차 공간 사전 예약 기능을 제공합니다.', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}