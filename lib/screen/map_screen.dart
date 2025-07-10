import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async'; // StreamSubscription을 위해 추가
import 'parking_reservation_screen.dart';
import 'package:flutter/scheduler.dart';

class MapScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? placeName;
  final Function? clearSelection;

  const MapScreen({
    Key? key, 
    this.initialLocation,
    this.placeName,
    this.clearSelection,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  GoogleMapController? _controller;
  final Map<MarkerId, Marker> _markers = {};
  final Location _location = Location();
  bool _isLoading = true;
  LatLng? _currentLocation;
  MarkerId? _selectedMarkerId;
  StreamSubscription<LocationData>? _locationSubscription;
  bool _isMapControllerReady = false;
  bool _hasMovedToSearchLocation = false;
  bool _isLocationPermissionGranted = false;
  
  // 주차장 정보 (실제로는 데이터베이스나 API에서 가져올 수 있음)
  final Map<String, ParkingLotInfo> _parkingLots = {
    'marker_연구실': ParkingLotInfo(
      id: 'parking_lab_001',  // 고유 ID 부여
      name: '연구실 주차장',
      address: '부산광역시 영도구 태종로 727, 공대1관 370호',
      totalSpaces: 30,
      availableSpaces: 12,
      pricePerHour: 2000,
      openingHours: '24시간',
      features: ['지붕 있음', '전기차 충전', '장애인 주차구역'],
    ),
    'marker_하리': ParkingLotInfo(
      id: 'parking_hari_001',  // 고유 ID 부여
      name: '동삼하리항 공영주차장',
      address: '부산광역시 영도구 동삼동 1174-4',
      totalSpaces: 50,
      availableSpaces: 38,
      pricePerHour: 2000,
      openingHours: '24시간',
      features: ['야외 주차장', '장애인 주차구역'],
    ),
  };
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 위젯 수명주기 관찰자 추가
    print("MapScreen initState 호출: ${widget.initialLocation}, ${widget.placeName}");
    _addPredefinedMarkers();
    _initLocation();
    
    // 초기화가 끝난 후 지연시간을 두고 검색 위치로 이동 재시도
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted && widget.initialLocation != null) {
        _processSearchLocation();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 상태 변경시에도 검색 위치 확인
    if (widget.initialLocation != null && !_hasMovedToSearchLocation) {
      _processSearchLocation();
    }
  }
  
  // 새로운 메서드: 검색 위치 처리
  void _processSearchLocation() {
    if (widget.initialLocation == null || widget.placeName == null) return;
    
    print("검색 위치 처리 시도: ${widget.initialLocation}, ${widget.placeName}");
    
    // 검색 마커 추가
    _addSearchResultMarker();
    
    // 컨트롤러가 준비되지 않은 경우 준비될 때까지 반복 시도
    if (_controller == null) {
      print("컨트롤러가 아직 준비되지 않음, 0.5초 후 재시도");
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted && !_hasMovedToSearchLocation) {
          _processSearchLocation();
        }
      });
      return;
    }
    
    // 컨트롤러가 준비되었으면 카메라 이동
    try {
      print("카메라를 검색 위치로 이동 시도");
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(widget.initialLocation!, 16.0)
      ).then((_) {
        setState(() {
          _hasMovedToSearchLocation = true;
        });
        print("카메라 이동 성공");
      }).catchError((error) {
        print("카메라 이동 오류: $error");
      });
    } catch (e) {
      print("검색 위치 처리 중 오류: $e");
    }
  }
  
  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    print("MapScreen didUpdateWidget 호출: ${widget.initialLocation}, ${widget.placeName}");
    
    // 위젯이 업데이트되고 새로운 검색 위치가 있으면 처리
    if (widget.initialLocation != null && 
        (oldWidget.initialLocation != widget.initialLocation || 
         oldWidget.placeName != widget.placeName)) {
      
      // 새로운 검색 위치로 업데이트 시 플래그 초기화
      setState(() {
        _hasMovedToSearchLocation = false;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _processSearchLocation();
        }
      });
    }
  }
  
  void _addSearchResultMarker() {
    if (widget.initialLocation == null || widget.placeName == null) {
      print("위치 정보 누락: ${widget.initialLocation}, ${widget.placeName}");
      return;
    }
    
    print("검색 마커 추가 시도: ${widget.initialLocation}, ${widget.placeName}");
    
    try {
      // 기존 검색 결과 마커 삭제
      final searchMarkerIds = _markers.keys
          .where((id) => id.value.startsWith('search_'))
          .toList();
      
      for (var id in searchMarkerIds) {
        _markers.remove(id);
      }
      
      // 새 마커 추가
      final String markerId = 'search_${DateTime.now().millisecondsSinceEpoch}';
      final MarkerId id = MarkerId(markerId);
      
      final Marker marker = Marker(
        markerId: id,
        position: widget.initialLocation!,
        infoWindow: InfoWindow(
          title: widget.placeName,
          snippet: '검색 결과',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () {
          _onMarkerTap(id);
        },
      );
      
      setState(() {
        _markers[id] = marker;
      });
      
      print("검색 마커 추가 완료");
    } catch (e) {
      print("마커 추가 중 오류: $e");
    }
  }
  
  void _moveToLocation(LatLng location, {double zoom = 15.0}) {
    print("카메라 이동 요청: $location, 줌: $zoom");
    if (_controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(location, zoom),
      ).then((_) {
        print("카메라 이동 완료: $location");
      }).catchError((error) {
        print("카메라 이동 오류: $error");
      });
    } else {
      print("컨트롤러가 null입니다. 카메라 이동 불가");
      // 컨트롤러가 준비되지 않았으면 지연 후 다시 시도
      Future.delayed(Duration(milliseconds: 500), () {
        if (_controller != null && mounted) {
          _controller!.animateCamera(
            CameraUpdate.newLatLngZoom(location, zoom),
          ).then((_) {
            print("지연 후 카메라 이동 완료: $location");
          }).catchError((error) {
            print("지연 후 카메라 이동 오류: $error");
          });
        }
      });
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // 미리 정의된 마커들을 추가
  void _addPredefinedMarkers() {
    // 여기에 미리 정의된 위치들에 마커를 추가
    _addMarker(
      const LatLng(35.07497, 129.08600), // 연구실
      '연구실',
      '부산광역시 영도구 태종로 727, 공대1관 370호',
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
    );
    _addMarker(
      const LatLng(35.0692584, 129.0817477), // 동삼하리항 공영주차장
      '동삼하리항 공영주차장',
      '부산광역시 영도구 동삼동 1174-4',
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
    );
  }

  Future<void> _initLocation() async {
    print("위치 초기화 시작");
    
    // 플랫폼 별 권한 처리
    bool permissionGranted = false;
    if (Platform.isAndroid) {
      permissionGranted = await _requestAndroidPermissions();
    } else {
      permissionGranted = await _requestIOSPermissions();
    }

    if (!permissionGranted) {
      print("위치 권한이 거부됨");
      setState(() {
        _isLocationPermissionGranted = false;
        _isLoading = false;
        // 권한이 없을 경우 기본 위치 사용 (한국해양대학교)
        _currentLocation = const LatLng(35.075269, 129.088703);
      });
      return;
    }

    setState(() {
      _isLocationPermissionGranted = true;
    });

    // 현재 위치 가져오기
    try {
      print("현재 위치 요청 중...");
      LocationData locationData = await _location.getLocation();
      
      if (locationData.latitude != null && locationData.longitude != null) {
        final newLocation = LatLng(locationData.latitude!, locationData.longitude!);
        print("현재 위치 획득 성공: $newLocation");
        
        if (mounted) {
          setState(() {
            _currentLocation = newLocation;
            _isLoading = false;
          });
          
          // Google Maps 기본 현재 위치 표시 사용 (마커 제거)
        }
      } else {
        throw Exception("위치 데이터가 null입니다");
      }
    } catch (e) {
      print('현재 위치를 가져오는 중 오류 발생: $e');
      // 위치를 가져오지 못할 경우 기본 위치 사용 (한국해양대학교)
      if (mounted) {
        setState(() {
          _currentLocation = const LatLng(35.075269, 129.088703);
          _isLoading = false;
        });
        print("기본 위치로 설정: ${_currentLocation}");
      }
    }

    // 위치 변경 이벤트 리스닝 (권한이 있을 경우에만)
    if (permissionGranted) {
      _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
        if (currentLocation.latitude != null && currentLocation.longitude != null && mounted) {
          final newLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          print("위치 업데이트: $newLocation");
          
          setState(() {
            _currentLocation = newLocation;
          });
          
          // Google Maps 기본 현재 위치 표시 사용 (마커 제거)
        }
      });
    }
  }

  // 안드로이드용 권한 요청
  Future<bool> _requestAndroidPermissions() async {
    print("안드로이드 위치 권한 요청");
    
    // Permission Handler 패키지 사용
    final status = await ph.Permission.location.request();
    print('위치 권한 상태: $status');
    
    if (status != ph.PermissionStatus.granted) {
      print("위치 권한이 거부됨");
      return false;
    }
    
    // 추가로 위치 서비스가 활성화되어 있는지 확인
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      print("위치 서비스가 비활성화됨, 활성화 요청");
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        print("위치 서비스 활성화 거부됨");
        return false;
      }
    }
    
    return true;
  }

  // iOS용 권한 요청
  Future<bool> _requestIOSPermissions() async {
    print("iOS 위치 권한 요청");
    
    // 위치 서비스가 활성화되어 있는지 확인
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        print("위치 서비스가 비활성화됨");
        return false;
      }
    }

    // 위치 권한 확인
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        print("위치 권한이 거부됨");
        return false;
      }
    }
    
    return true;
  }

  void _onMapCreated(GoogleMapController controller) {
    print("지도 컨트롤러 생성됨");
    
    if (mounted) {
      setState(() {
        _controller = controller;
        _isMapControllerReady = true;
      });
      
      // 컨트롤러가 생성된 직후 검색 위치가 있으면 처리
      if (widget.initialLocation != null && !_hasMovedToSearchLocation) {
        print("컨트롤러 생성 직후 검색 위치 처리");
        _processSearchLocation();
      }
      else if (_currentLocation != null) {
        // 검색 위치가 없으면 현재 위치로 이동
        print("현재 위치로 지도 이동: $_currentLocation");
        _moveToLocation(_currentLocation!);
      }
    }
  }

  // 특정 위치에 마커 추가
  void _addMarker(
    LatLng position, 
    String title, 
    String snippet, 
    BitmapDescriptor icon, {
    bool isCurrentLocation = false,
    String? markerIdPrefix
  }) {
    final String markerId = markerIdPrefix != null 
        ? '${markerIdPrefix}${DateTime.now().millisecondsSinceEpoch}'
        : isCurrentLocation 
            ? 'current_location' 
            : 'marker_${title.replaceAll(' ', '_').toLowerCase()}';
    
    final MarkerId id = MarkerId(markerId);
    
    final Marker marker = Marker(
      markerId: id,
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
        onTap: () {
          _onMarkerInfoWindowTap(id);
        },
      ),
      icon: icon,
      onTap: () {
        _onMarkerTap(id);
      },
    );
    
    if (mounted) { // mounted 체크 추가
      setState(() {
        _markers[id] = marker;
      });
    }
  }

  // 마커를 탭했을 때 호출
  void _onMarkerTap(MarkerId markerId) {
    if (mounted) { // mounted 체크 추가
      setState(() {
        _selectedMarkerId = markerId;
      });
      
      // 선택된 마커로 카메라 이동
      if (_markers.containsKey(markerId)) {
        _moveToLocation(_markers[markerId]!.position);
      }
      
      // 마커 탭 이벤트 - 하단에 정보 표시
      _showMarkerInfo(markerId);
    }
  }
  
  // 마커 정보창을 탭했을 때 호출
  void _onMarkerInfoWindowTap(MarkerId markerId) {
    // 마커 정보창 탭 이벤트 - 상세 정보 페이지로 이동 등
    _showMarkerDetailScreen(markerId);
  }
  
  // 하단에 마커 정보 표시
  void _showMarkerInfo(MarkerId markerId) {
    if (!_markers.containsKey(markerId)) return;
    
    final marker = _markers[markerId]!;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('선택: ${marker.infoWindow.title}'),
        action: SnackBarAction(
          label: '더보기',
          onPressed: () {
            _showMarkerDetailScreen(markerId);
          },
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  // 마커 상세 정보 화면 표시
  void _showMarkerDetailScreen(MarkerId markerId) {
    if (!_markers.containsKey(markerId)) return;
    
    final marker = _markers[markerId]!;
    final String markerIdString = markerId.value;
    final ParkingLotInfo? parkingInfo = _parkingLots[markerIdString];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              marker.infoWindow.title ?? '제목 없음',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(marker.infoWindow.snippet ?? '설명 없음'),
            const SizedBox(height: 16),
            
            // 주차장 정보가 있으면 표시
            if (parkingInfo != null) ...[
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.local_parking, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '주차 가능: ${parkingInfo.availableSpaces}/${parkingInfo.totalSpaces}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('시간당 ${parkingInfo.pricePerHour}원'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('운영 시간: ${parkingInfo.openingHours}'),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: parkingInfo.features.map((feature) => Chip(
                  label: Text(feature, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.grey[200],
                )).toList(),
              ),
              const Divider(),
            ],
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openMapWithDirections(marker.position, marker.infoWindow.title ?? '목적지');
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('길찾기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      final currentParkingInfo = parkingInfo ?? 
                        ParkingLotInfo(
                          id: 'unknown_${DateTime.now().millisecondsSinceEpoch}',
                          name: marker.infoWindow.title ?? '주차장',
                          address: marker.infoWindow.snippet ?? '',
                          totalSpaces: 0,
                          availableSpaces: 0,
                          pricePerHour: 0,
                          openingHours: '정보 없음',
                          features: [],
                        );
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ParkingReservationScreen(
                            parkingInfo: currentParkingInfo,
                            location: marker.position,
                            onParkingInfoUpdate: (updatedInfo) {
                              // 주차장 정보가 업데이트되면 마커와 데이터 갱신
                              // 빌드 과정 이후 실행되도록 스케줄링
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    if (markerIdString.startsWith('marker_')) {
                                      _parkingLots[markerIdString] = updatedInfo;
                                    }
                                  });
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('예약하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 길찾기 기능 구현 (외부 지도 앱 실행)
  Future<void> _openMapWithDirections(LatLng destination, String destinationName) async {
    // 현재 위치가 null이면 기본 위치 사용
    if (_currentLocation == null) {
      _showErrorSnackBar('현재 위치를 확인할 수 없습니다.');
      return;
    }

    final LatLng origin = _currentLocation!;
    
    // URL 생성
    String url;
    
    if (Platform.isAndroid) {
      // 구글 지도 URL (안드로이드)
      url = 'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving&dir_action=navigate';
    } else if (Platform.isIOS) {
      // 애플 지도 URL (iOS)
      url = 'https://maps.apple.com/?saddr=${origin.latitude},${origin.longitude}&daddr=${destination.latitude},${destination.longitude}&dirflg=d';
    } else {
      // 웹 브라우저용 URL
      url = 'https://www.google.com/maps/dir/${origin.latitude},${origin.longitude}/${destination.latitude},${destination.longitude}';
    }
    
    // URL 열기
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // URL을 열 수 없는 경우
        _showErrorSnackBar('길찾기를 시작할 수 없습니다. 지도 앱이 설치되어 있는지 확인하세요.');
      }
    } catch (e) {
      _showErrorSnackBar('오류가 발생했습니다: $e');
    }
  }
  
  // 오류 메시지 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 현재 위치로 이동하는 개선된 메서드
  void _moveToCurrentLocation() {
    print("현재 위치로 이동 요청");
    
    if (_currentLocation != null) {
      print("현재 위치 사용: $_currentLocation");
      _moveToLocation(_currentLocation!, zoom: 16.0);
    } else {
      print("현재 위치가 null임, 위치 다시 요청");
      // 현재 위치가 없으면 다시 가져오기 시도
      _getCurrentLocationAndMove();
    }
  }

  // 현재 위치를 다시 가져와서 이동
  Future<void> _getCurrentLocationAndMove() async {
    try {
      if (!_isLocationPermissionGranted) {
        _showErrorSnackBar('위치 권한이 필요합니다.');
        return;
      }

      // 로딩 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('현재 위치를 가져오는 중...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      LocationData locationData = await _location.getLocation();
      
      if (locationData.latitude != null && locationData.longitude != null) {
        final newLocation = LatLng(locationData.latitude!, locationData.longitude!);
        print("새로운 현재 위치 획득: $newLocation");
        
        setState(() {
          _currentLocation = newLocation;
        });
        
        // Google Maps 기본 현재 위치 표시 사용 (마커 제거)
        
        // 지도 이동
        _moveToLocation(newLocation, zoom: 16.0);
        
        // 성공 메시지
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('현재 위치로 이동했습니다.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception("위치 데이터를 가져올 수 없습니다");
      }
    } catch (e) {
      print('현재 위치 가져오기 오류: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar('현재 위치를 가져올 수 없습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 지도 중심 위치 결정 로직 개선
    LatLng mapCenter;
    double initialZoom = 15.0;
    
    if (widget.initialLocation != null) {
      // 검색 위치가 있으면 우선 사용
      mapCenter = widget.initialLocation!;
      initialZoom = 16.0;
      print("지도 초기 중심 위치: 검색 위치 사용 - $mapCenter");
    } else if (_currentLocation != null) {
      // 현재 위치가 있으면 사용
      mapCenter = _currentLocation!;
      initialZoom = 15.0;
      print("지도 초기 중심 위치: 현재 위치 사용 - $mapCenter");
    } else {
      // 둘 다 없으면 기본 위치 (한국해양대학교)
      mapCenter = const LatLng(35.075269, 129.088703);
      initialZoom = 15.0;
      print("지도 초기 중심 위치: 기본 위치 사용 - $mapCenter");
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('주차장 찾기')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: mapCenter,
              zoom: initialZoom,
            ),
            onMapCreated: _onMapCreated,
            markers: Set<Marker>.of(_markers.values),
            myLocationEnabled: _isLocationPermissionGranted,
            myLocationButtonEnabled: false, // 커스텀 버튼 사용
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            compassEnabled: true,
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          // 위치 권한 경고 메시지 (필요시)
          if (!_isLocationPermissionGranted && !_isLoading)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: _buildPermissionWarning(),
            ),
          // 현재 위치 버튼 (개선됨)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: "locationBtn",
              mini: true,
              onPressed: _moveToCurrentLocation,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.my_location, 
                size: 20,
                color: _currentLocation != null ? Colors.blue : Colors.grey,
              ),
              tooltip: '현재 위치로 이동',
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "mainBtn",
        onPressed: () {
          // 모든 마커가 보이도록 카메라 위치 조정
          _fitAllMarkers();
        },
        child: const Icon(Icons.map),
        tooltip: '모든 마커 보기',
      ),
    );
  }
  
  // 권한 경고 메시지 위젯
  Widget _buildPermissionWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off, color: Colors.orange[800]),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '위치 권한이 필요합니다',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                Text(
                  '현재 위치 및 길찾기 기능을 사용하려면 위치 권한을 허용해주세요.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // 권한 재요청
              _initLocation();
            },
            child: Text(
              '재시도',
              style: TextStyle(color: Colors.orange[800]),
            ),
          ),
        ],
      ),
    );
  }
  
  // 모든 마커가 지도에 표시되도록 카메라 위치 조정
  void _fitAllMarkers() {
    if (_markers.isEmpty || _controller == null) {
      print("마커가 없거나 컨트롤러가 준비되지 않음");
      return;
    }
    
    // 모든 마커의 위치를 가져옴
    final List<LatLng> markerPositions = _markers.values
        .map((marker) => marker.position)
        .toList();
        
    // 모든 위치를 포함하는 경계 계산
    double minLat = markerPositions.first.latitude;
    double maxLat = markerPositions.first.latitude;
    double minLng = markerPositions.first.longitude;
    double maxLng = markerPositions.first.longitude;
    
    for (final position in markerPositions) {
      if (position.latitude < minLat) minLat = position.latitude;
      if (position.latitude > maxLat) maxLat = position.latitude;
      if (position.longitude < minLng) minLng = position.longitude;
      if (position.longitude > maxLng) maxLng = position.longitude;
    }
    
    // 경계에 패딩 추가
    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );
    
    // 카메라 위치 조정
    _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    ).then((_) {
      print("모든 마커를 포함하도록 카메라 조정 완료");
    }).catchError((error) {
      print("카메라 조정 오류: $error");
    });
  }
}

// 주차장 정보를 담는 클래스
class ParkingLotInfo {
  final String id;  // ID 필드 추가
  final String name;
  final String address;
  final int totalSpaces;
  final int availableSpaces;
  final int pricePerHour;
  final String openingHours;
  final List<String> features;

  ParkingLotInfo({
    required this.id,  // 생성자에 추가
    required this.name,
    required this.address,
    required this.totalSpaces,
    required this.availableSpaces,
    required this.pricePerHour,
    required this.openingHours,
    required this.features,
  });
}