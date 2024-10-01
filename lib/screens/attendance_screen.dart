import 'package:flutter/material.dart';
import 'package:geofence_2/services/location_service.dart';
import 'package:toastification/toastification.dart';
import '../services/geofence_service_handler.dart';
import '../utils/preferences.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final LocationService locationService = LocationService();
  final GeofenceServiceHandler geofenceServiceHandler =
      GeofenceServiceHandler();

  bool _isInsideGeofence = false;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    locationService
        .checkLocationPermission(); // Ask for locatin permission when the app initiated
    locationService
        .requestGeofencePermissions(); // Additional request for geofence service background location
    PreferencesUtil.getOnlineStatus(); // Load saved preference when app starts
    // Initialize Geofence with a callback for status changes
    geofenceServiceHandler.initialize(onGeofenceStatusChanged: (bool isInside) {
      if (mounted) {
        setState(() {
          _isInsideGeofence = isInside;
        });
        debugPrint('Geofence status changed: $_isInsideGeofence');
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      geofenceServiceHandler
          .setupGeofenceListeners(context); //add geofence event listeners
      geofenceServiceHandler
          .startGeofenceService(); //starting the geofencing service
    });
  }

  void _toggleOnline(bool value) async {
    PreferencesUtil.setOnlineStatus(value);
    setState(() {
      _isOnline = value;
      if (_isOnline) {
        if (mounted) {
          locationService.startLocationUpdates(context);
        }
      } else {
        locationService.stopLocationUpdates();
      }
    });
  }

  void _checkIn() {
    toastification.show(
      context: context,
      title: const Text('CHECKED IN'),
      autoCloseDuration: const Duration(seconds: 5),
    );
  }

  @override
  void dispose() {
    super.dispose();
    geofenceServiceHandler.disposing();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance App'),
        actions: [
          Row(
            children: [
              Text(
                _isOnline ? 'Online' : 'Offline',
              ),
              Switch(
                value: _isOnline,
                onChanged: _toggleOnline,
                activeColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent),
              onPressed: _isInsideGeofence && _isOnline ? _checkIn : null,
              child: const Text('Check In'),
            ),
          ],
        ),
      ),
    );
  }
}
