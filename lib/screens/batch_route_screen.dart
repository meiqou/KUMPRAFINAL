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

class BatchRouteScreen extends StatefulWidget {
  final int batchId;
  final double clusterLat;
  final double clusterLng;

  const BatchRouteScreen({
    super.key,
    required this.batchId,
    required this.clusterLat,
    required this.clusterLng,
  });

  @override
  State<BatchRouteScreen> createState() => _BatchRouteScreenState();
}

class _BatchRouteScreenState extends State<BatchRouteScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  LatLng? _riderPos;
  LatLng _clusterPos = const LatLng(0, 0);
  bool _loading = true;
  String _distance = '';
  String _duration = '';
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _clusterPos = LatLng(widget.clusterLat, widget.clusterLng);
    _loadRoute();
    _listenToGPS();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
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

  Future<void> _loadRoute() async {
    if (_riderPos == null) {
      final pos = RiderGeolocationService.lastKnownPosition ?? await RiderGeolocationService.getCurrentPosition();
      _riderPos = LatLng(pos.latitude, pos.longitude);
    }

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
      _distance = '${(summary['distance'] / 1000).toStringAsFixed(1) ?? '0.0'} km';
      _duration = '${(summary['duration'] / 60).round() ?? 0} min';
      _routePoints = _decodePolyline(geometry['coordinates']);
      _loading = false;
    });

          _fitBounds();
        }
      }
    } catch (e) {
      print('Route load error: $e');
      setState(() => _loading = false);
    }
  }

  List<LatLng> _decodePolyline(List coordinates) {
    return coordinates.map<LatLng>((coord) => LatLng(coord[1] as double, coord[0] as double)).toList();
  }

  void _fitBounds() {
    if (_routePoints.isEmpty) return;
    double minLat = math.pi, maxLat = -math.pi, minLng = math.pi, maxLng = -math.pi;
    for (final point in _routePoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
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
        title: const Text('Batch Route', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    Text('Distance: $_distance', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    Text('Duration: $_duration', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadRoute,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

