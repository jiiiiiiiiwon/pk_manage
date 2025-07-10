import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:capstone_design/services/place_search_service.dart';

class PlaceSearchScreen extends StatefulWidget {
  final Function(LatLng location, String placeName)? onPlaceSelected;
  
  const PlaceSearchScreen({
    Key? key, 
    this.onPlaceSelected,
  }) : super(key: key);

  @override
  _PlaceSearchScreenState createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 위치 검색 수행
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await PlaceSearchService.searchPlaces(query);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
      
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 결과를 찾을 수 없습니다')),
        );
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '장소 검색',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchResults = [];
                          });
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        _searchPlaces(_searchController.text);
                      },
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (value) {
                _searchPlaces(value);
              },
            ),
          ),
          
          // 카테고리 필터 (선택적)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterChip('모든 장소'),
                SizedBox(width: 8),
                _buildFilterChip('주차장'),
                SizedBox(width: 8),
                _buildFilterChip('음식점'),
                SizedBox(width: 8),
                _buildFilterChip('카페'),
              ],
            ),
          ),
          
          // 검색 결과 로딩 인디케이터
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            
          // 검색 결과 목록
          Expanded(
            child: _searchResults.isEmpty && !_isSearching 
                ? _buildEmptySearchView()
                : ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) => _buildSearchResultItem(context, _searchResults[index]),
                  ),
          ),
        ],
      ),
    );
  }
  
  // 검색 결과가 없을 때 표시할 위젯
  Widget _buildEmptySearchView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            '장소를 검색해보세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            '장소명, 주소, 건물명 등으로 검색 가능합니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  // 검색 결과 아이템 위젯
  Widget _buildSearchResultItem(BuildContext context, Map<String, dynamic> place) {
    final locationName = place['name'] ?? '';
    final address = place['formatted_address'] ?? '';
    
    final location = place['geometry']?['location'];
    final double lat = location != null ? location['lat']?.toDouble() ?? 0.0 : 0.0;
    final double lng = location != null ? location['lng']?.toDouble() ?? 0.0 : 0.0;
    
    final bool isOpen = place['opening_hours']?['open_now'] ?? false;
    final rating = place['rating']?.toDouble() ?? 0.0;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Color(0xFFE0F7F4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.place, color: Color(0xFF00A896), size: 28),
      ),
      title: Text(
        locationName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Text(
            address, 
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              if (rating > 0) ...[
                Icon(Icons.star, size: 16, color: Colors.amber),
                Text(
                  ' ${rating.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                SizedBox(width: 8),
              ],
              if (place.containsKey('opening_hours'))
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isOpen ? '영업 중' : '영업 종료',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOpen ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      onTap: () {
        // 내비게이션 바를 통해 지도 페이지로 이동
        if (widget.onPlaceSelected != null) {
          widget.onPlaceSelected!(LatLng(lat, lng), locationName);
        }
      },
    );
  }
  
  // 필터 칩 위젯
  Widget _buildFilterChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFE0F7F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Color(0xFF00A896),
          fontSize: 13,
        ),
      ),
    );
  }
}