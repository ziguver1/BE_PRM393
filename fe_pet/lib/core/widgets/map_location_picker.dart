import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;

  const MapLocationPicker({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  final double _initialZoom = 13.0;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // TP.HCM coordinates
  static const LatLng _hcmCenter = LatLng(10.8231, 106.6297);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation ?? _hcmCenter;
    // Notify parent about the selected location after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLocationSelected(_selectedLocation!);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    widget.onLocationSelected(point);
  }

  void _onLongPress(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    widget.onLocationSelected(point);
    
    // Move map to selected location
    _mapController.move(point, _mapController.camera.zoom);
  }

  void _centerOnSelectedLocation() {
    if (_selectedLocation != null) {
      _mapController.move(_selectedLocation!, _mapController.camera.zoom);
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 1,
        },
      );

      if (response.data != null && (response.data as List).isNotEmpty) {
        final result = response.data[0];
        final lat = double.parse(result['lat'].toString());
        final lon = double.parse(result['lon'].toString());
        final point = LatLng(lat, lon);

        setState(() {
          _selectedLocation = point;
        });
        widget.onLocationSelected(point);
        _mapController.move(point, 16.0);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy địa chỉ. Vui lòng thử lại.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi tìm kiếm địa chỉ.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Address Bar
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Nhập địa chỉ cần tìm...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: _searchAddress,
                ),
              ),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.grey),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _searchAddress(_searchController.text);
                  },
                ),
            ],
          ),
        ),

        // Map container
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation ?? _hcmCenter,
              initialZoom: _initialZoom,
              onTap: _onMapTap,
              onLongPress: _onLongPress,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              // OpenStreetMap TileLayer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fe_pet',
              ),
              // Selected location marker
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Selected coordinates display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedLocation != null
                      ? 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}'
                      : 'Chưa chọn vị trí',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
              if (_selectedLocation != null)
                IconButton(
                  icon: const Icon(Icons.my_location, size: 20),
                  onPressed: _centerOnSelectedLocation,
                  tooltip: 'Canh giữa vị trí đã chọn',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        
        // Instructions
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Nhấn hoặc nhấn giữ trên bản đồ để chọn vị trí giao hàng',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
