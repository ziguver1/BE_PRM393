import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/network/api_client.dart';

class OrderTrackingScreen extends StatefulWidget {
  final List<LatLng> routePoints;
  final int orderId;

  const OrderTrackingScreen({
    super.key,
    required this.routePoints,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late MapController _mapController;
  int _currentRouteIndex = 0;
  double _progress = 0.0;
  String? _driverName;
  String? _driverPhone;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Auto-fit map to route bounds after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
    
    // Fetch initial state and start polling
    _fetchTracking();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchTracking();
    });
  }

  Future<void> _fetchTracking() async {
    try {
      final response = await ApiClient().dio.get('/orders/${widget.orderId}/tracking');
      if (response.statusCode == 200) {
        final data = response.data;
        final status = data['status'] as String? ?? 'SHIPPING';
        final progress = (data['progress'] as num? ?? 0.0).toDouble();
        final currentIndex = data['currentIndex'] as int? ?? 0;
        final driver = data['driver'];

        if (!mounted) return;

        setState(() {
          _progress = progress;
          if (widget.routePoints.isNotEmpty) {
            _currentRouteIndex = currentIndex.clamp(0, widget.routePoints.length - 1);
          }
          if (driver != null) {
            _driverName = driver['name'] as String?;
            _driverPhone = driver['phone'] as String?;
          }
        });

        if (status == 'DELIVERED' || status == 'RECEIVED') {
          _pollTimer?.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đơn hàng đã được giao.'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải thông tin tracking: $e');
    }
  }

  void _fitBounds() {
    if (widget.routePoints.isEmpty) return;

    // Calculate bounds from route points
    final bounds = LatLngBounds.fromPoints(widget.routePoints);

    // Fit map to bounds with padding
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.routePoints.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Theo dõi đơn hàng'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Chưa có lộ trình giao hàng',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Clamp current route index safely for marker rendering
    final markerPositionIndex = _currentRouteIndex.clamp(0, widget.routePoints.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Theo dõi đơn hàng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _fitBounds,
            tooltip: 'Canh giữa lộ trình',
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: widget.routePoints.first,
          initialZoom: 13,
          minZoom: 10,
          maxZoom: 18,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          // OpenStreetMap TileLayer
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.fe_pet',
          ),
          
          // PolylineLayer for route
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.routePoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
          
          // MarkerLayer with store, driver, and home markers
          MarkerLayer(
            markers: [
              // Store marker (first point) - Red
              Marker(
                point: widget.routePoints.first,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
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
                    Icons.store,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              
              // Delivery person motorcycle marker - Orange
              Marker(
                point: widget.routePoints[markerPositionIndex],
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
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
                    Icons.motorcycle,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              
              // Home marker (last point) - Green
              Marker(
                point: widget.routePoints.last,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
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
                    Icons.home,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      
      // Info panel at bottom
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (_driverName != null) ...[
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _driverName!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'SĐT: ${_driverPhone ?? "0909000000"} - Xe: PetShop Delivery',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_progress.toInt()}%',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(
                  icon: Icons.store,
                  color: Colors.red,
                  label: 'Cửa hàng',
                ),
                _buildLegendItem(
                  icon: Icons.route,
                  color: Colors.blue,
                  label: 'Lộ trình',
                ),
                _buildLegendItem(
                  icon: Icons.home,
                  color: Colors.green,
                  label: 'Khách hàng',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
