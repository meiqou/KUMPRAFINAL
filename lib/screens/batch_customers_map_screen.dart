import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../utils/constants.dart';
import '../../services/rider_geolocation_service.dart';
import '../../services/api_service.dart'; // Assuming ApiService is available

class BatchCustomersMapScreen extends StatefulWidget {
  final int batchId;
  final double clusterLat;
  final double clusterLng;

  const BatchCustomersMapScreen({
    super.key,
    required this.batchId,
    required this.clusterLat,
    required this.clusterLng,
  });

  @override
  State<BatchCustomersMapScreen> createState() => _BatchCustomersMapScreenState();
}

class _BatchCustomersMapScreenState extends State<BatchCustomersMapScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  LatLng? _riderPos;
  LatLng _clusterPos = const LatLng(0, 0);
  bool _loading = true;
  String _distance = '';
  String _duration = '';
  StreamSubscription<Position>? _positionSub;
  List<Map<String, dynamic>> _customers = [];
  Timer? _customerPollTimer;

  @override
  void initState() {
    super.initState();
    _clusterPos = LatLng(widget.clusterLat, widget.clusterLng);
    _loadMapData();
    _listenToGPS();
    _startCustomerPolling();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _customerPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _listenToGPS() async {
    _positionSub = RiderGeolocationService.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _riderPos = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_riderPos!, math.max(_mapController.camera.zoom, 15.0));
        _loadRoute(); // Refresh route with new rider pos
      }
    });
  }

  Future<void> _loadMapData() async {
    await _loadRoute();
    await _fetchCustomers();
    setState(() => _loading = false);
  }

  Future<void> _loadRoute() async {
    if (_riderPos == null) {
      final pos = RiderGeolocationService.lastKnownPosition ?? await RiderGeolocationService.getCurrentPosition();
      _riderPos = LatLng(pos.latitude, pos.longitude);
    }

    if (_riderPos == null) return; // Should not happen if getCurrentPosition works

    final url = Uri.parse('https://api.geoapify.com/v1/routing?waypoints=${_riderPos!.longitude},${_riderPos!.latitude}|${widget.clusterLng},${widget.clusterLat}&mode=drive&details=instruction&apiKey=${AppConstants.geoapifyApiKey}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final geometry = feature['geometry'];
          final summary = feature['properties']['summary'];

          setState(() {
            _distance = '${(summary['distance'] / 1000).toStringAsFixed(1)} km';
            _duration = '${(summary['duration'] / 60).round()} min';
            _routePoints = _decodePolyline(geometry['coordinates']);
          });
          _fitBounds();
        }
      }
    } catch (e) {
      print('Route load error: $e');
    }
  }

  Future<void> _fetchCustomers() async {
    // This assumes a new API endpoint 'batches/customers.php' exists
    // that returns a list of customers with their locations for a given batch.
    final res = await ApiService.get(
      'batches/customers.php',
      auth: true,
      params: {'batch_id': widget.batchId.toString()},
    );

    if (mounted && res['success'] == true && res['customers'] != null) {
      setState(() {
        _customers = List<Map<String, dynamic>>.from(res['customers']);
      });
    } else {
      print('Failed to fetch customers: ${res['message']}');
    }
  }

  void _startCustomerPolling() {
    _customerPollTimer?.cancel();
    _customerPollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchCustomers();
    });
  }

  List<LatLng> _decodePolyline(List coordinates) {
    return coordinates.map<LatLng>((coord) => LatLng(coord[1] as double, coord[0] as double)).toList();
  }

  void _fitBounds() {
    if (_routePoints.isEmpty && _customers.isEmpty && _riderPos == null) return;

    List<LatLng> pointsToFit = [];
    if (_riderPos != null) pointsToFit.add(_riderPos!);
    pointsToFit.addAll(_routePoints);
    for (var customer in _customers) {
      final lat = customer['latitude'] as double?;
      final lng = customer['longitude'] as double?;
      if (lat != null && lng != null) {
        pointsToFit.add(LatLng(lat, lng));
      }
    }
    pointsToFit.add(_clusterPos); // Ensure cluster is always included

    if (pointsToFit.isEmpty) return;

    double minLat = pointsToFit[0].latitude, maxLat = pointsToFit[0].latitude;
    double minLng = pointsToFit[0].longitude, maxLng = pointsToFit[0].longitude;

    for (final point in pointsToFit) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Customers Map', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primaryDark,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _clusterPos,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey={apiKey}',
                additionalOptions: const {'apiKey': AppConstants.geoapifyApiKey},
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: AppColors.primary,
                    strokeWidth: 5.0,
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_riderPos != null)
                    Marker(
                      point: _riderPos!,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                    ),
                  Marker(
                    point: _clusterPos,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_pin, color: Colors.white, size: 32),
                    ),
                  ),
                  // Customer Markers
                  ..._customers.map((customer) {
                    final lat = customer['latitude'] as double?;
                    final lng = customer['longitude'] as double?;
                    if (lat == null || lng == null) return Marker(point: LatLng(0,0), child: Container()); // Placeholder
                    return Marker(
                      point: LatLng(lat, lng),
                      child: Tooltip(
                        message: customer['name'] ?? 'Customer',
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 20),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_distance.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Text('Distance to Cluster: $_distance', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    Text('Duration to Cluster: $_duration', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadMapData, // Refresh all data
        child: const Icon(Icons.refresh),
      ),
    );
  }
}