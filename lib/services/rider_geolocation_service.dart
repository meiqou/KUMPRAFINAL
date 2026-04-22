import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class RiderGeolocationService {
  static Timer? _timer;
  static int _activeBatchId = 0;
  static final StreamController<Position> _positionController = StreamController<Position>.broadcast();

  static Stream<Position> get positionStream => _positionController.stream;

  static Future<bool> checkPermissions() async {
    return await Geolocator.isLocationServiceEnabled() &&
        await Geolocator.checkPermission() == LocationPermission.always;
  }

  static Future<void> startTracking(int batchId) async {
    if (_activeBatchId != 0) stopTracking();
    
    _activeBatchId = batchId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tracking_batch_id', batchId);

    // Check/request permissions
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return;

    // Get initial position
    Position position = await Geolocator.getCurrentPosition();
    _positionController.add(position);
    await _updateLocation(batchId, position.latitude, position.longitude);

    // Poll every 10s
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        // ignore: deprecated_member_use
        Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _positionController.add(pos);
        await _updateLocation(batchId, pos.latitude, pos.longitude);
      } catch (e) {
        print('GPS error: $e');
      }
    });
  }

  static Future<void> _updateLocation(int batchId, double lat, double lng) async {
    await ApiService.post('config/update.php', {
      'batch_id': batchId,
      'latitude': lat,
      'longitude': lng,
    }, auth: true);
  }

  static void stopTracking() {
    _timer?.cancel();
    _timer = null;
    _activeBatchId = 0;
    _positionController.addError('Tracking stopped');
  }

  static int get activeBatchId => _activeBatchId;
}

