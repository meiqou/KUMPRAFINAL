import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../utils/constants.dart';

class LiveMapScreen extends StatefulWidget {
  final int? orderId;
  final double latitude;
  final double longitude;
  final bool isLiveLocation;

  const LiveMapScreen({
    super.key,
    this.orderId,
    required this.latitude,
    required this.longitude,
    required this.isLiveLocation,
  });

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();
  Timer? _pollTimer;
  bool _isRefreshing = false;

  late double _currentLat;
  late double _currentLng;
  late bool _hasLiveLocation;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.latitude;
    _currentLng = widget.longitude;
    _hasLiveLocation = widget.isLiveLocation;
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    if (widget.orderId == null) return;
    _refreshLiveLocation();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshLiveLocation(),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Future<void> _refreshLiveLocation() async {
    if (_isRefreshing || widget.orderId == null) return;
    _isRefreshing = true;

    try {
      final res = await ApiService.get(
        'orders/status.php',
        auth: true,
        params: {'order_id': widget.orderId.toString()},
      );

      final order = res['order'];
      if (res['success'] == true && order is Map<String, dynamic>) {
        final riderLat = _toDouble(order['rider_latitude']);
        final riderLng = _toDouble(order['rider_longitude']);
        final clusterLat = _toDouble(order['latitude']);
        final clusterLng = _toDouble(order['longitude']);

        final nextLat = riderLat ?? clusterLat;
        final nextLng = riderLng ?? clusterLng;

        if (nextLat != null && nextLng != null && mounted) {
          final hasLive = riderLat != null && riderLng != null;
          setState(() {
            _currentLat = nextLat;
            _currentLng = nextLng;
            _hasLiveLocation = hasLive;
          });
          _mapController.move(
            LatLng(nextLat, nextLng),
            hasLive ? 15 : 13,
          );
        }
      }
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(_currentLat, _currentLng);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Text(
          _hasLiveLocation ? 'LIVE RIDER MAP' : 'MAP PREVIEW',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: _hasLiveLocation ? 15 : 13,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey={apiKey}',
                additionalOptions: const {
                  'apiKey': AppConstants.geoapifyApiKey,
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_pin,
                      size: 42,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _hasLiveLocation
                    ? 'Showing current rider location.'
                    : 'Rider location unavailable. Showing market center.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
