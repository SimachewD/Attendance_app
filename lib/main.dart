import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geofence_service/geofence_service.dart' as geofenceservice;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:toastification/toastification.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AttendanceScreen(),
    );
  }
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final geofenceservice.GeofenceService _geofenceService =
      geofenceservice.GeofenceService.instance.setup(
        interval: 2000,
        accuracy: 20,
        loiteringDelayMs: 15000,
        statusChangeDelayMs: 5000,
        useActivityRecognition: false,
        allowMockLocations: false,
        printDevLog: false,
        geofenceRadiusSortType: geofenceservice.GeofenceRadiusSortType.DESC,
      );

  final List<geofenceservice.Geofence> _geofenceList = [
    // geofenceservice.Geofence(
    //   id: 'place_1',
    //   latitude: 9.0019327,
    //   longitude: 38.8429305,
    //   radius: [
    //     geofenceservice.GeofenceRadius(id: 'radius_100m', length: 100),
    //     geofenceservice.GeofenceRadius(id: 'radius_25m', length: 25),
    //     geofenceservice.GeofenceRadius(id: 'radius_250m', length: 250),
    //     geofenceservice.GeofenceRadius(id: 'radius_200m', length: 50000),
    //   ],
    // ),
    geofenceservice.Geofence(
      id: 'place_2',
      latitude: 8.9924164,
      longitude: 38.7922022,
      radius: [
        // geofenceservice.GeofenceRadius(id: 'radius_3m', length: 3),
        // geofenceservice.GeofenceRadius(id: 'radius_10m', length: 10),
        geofenceservice.GeofenceRadius(id: 'radius_100m', length: 100),
      ],
    ),
  ];

  bool _isInsideGeofence = false;
  bool _isOnline = false;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _loadOnlineStatus();  // Load saved preference when app starts
    _checkLocationPermission(); // Ask for locatin permission when the app initiated
    _requestGeofencePermissions(); // Additional request for geofence service background location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupGeofenceListeners(); //add geofence event listeners
      _startGeofenceService(); //starting the geofencing service
    });
  }

  Future<void> _requestGeofencePermissions() async {
    await Permission.locationWhenInUse
        .request(); // Request foreground location permission
    // Request background location permission if the geofence runs in the background
    if (await Permission.locationAlways.isDenied) {
      PermissionStatus backgroundPermission =
          await Permission.locationAlways.request();
      if (!backgroundPermission.isGranted) {
        debugPrint('Background location permission denied');
      } else {
        debugPrint('Background location permission granted');
      }
    }
  }

  Future<void> _checkLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    // Check and request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission is permanently denied');
      openAppSettings();
      return;
    }

    // If permissions are granted, you can now use geolocator
    Position position = await Geolocator.getCurrentPosition();
    debugPrint('Current position: ${position.latitude}, ${position.longitude}');
  }

  // Load the online status from shared preferences
  void _loadOnlineStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isOnline = prefs.getBool('isOnline') ?? false;  // Default to false
    });
  }

  void _setupGeofenceListeners() {
    _geofenceService.addGeofenceStatusChangeListener(
        _onGeofenceStatusChanged); // add a function to listen geofence status event (ENTER, EXIT)
    _geofenceService.addLocationChangeListener(_onLocationChanged); // listen to location change
    _geofenceService.addLocationServicesStatusChangeListener(
        _onLocationServicesStatusChanged); //listen for location service changes
    // _geofenceService.addActivityChangeListener(_onActivityChanged);
    _geofenceService.addStreamErrorListener(_onError); // listener for errors
  }

  void _startGeofenceService() {
    _geofenceService
        .start(_geofenceList)
        .catchError(_onError); //starts geofence service for list of geofences
  }

// geofence status change handler
  Future<void> _onGeofenceStatusChanged(
    geofenceservice.Geofence geofence,
    geofenceservice.GeofenceRadius geofenceRadius,
    geofenceservice.GeofenceStatus geofenceStatus,
    geofenceservice.Location location) async {
    final bool isInside = (geofenceStatus == geofenceservice.GeofenceStatus.ENTER);

    setState(() {
      _isInsideGeofence = isInside;
    });

    toastification.show(
      context: context,
      title: Text(isInside ? 'You are in' : 'You left'),
      autoCloseDuration: const Duration(seconds: 5),
    );
  }


  // void _onActivityChanged(geofenceservice.Activity prevActivity,
  //     geofenceservice.Activity currActivity) {
  //   print('Previous Activity: ${prevActivity.toJson()}');
  //   print('Current Activity: ${currActivity.toJson()}');
  // }

  void _onLocationChanged(geofenceservice.Location location) {
    // toastification.show(
    //   context: context, // optional if you use ToastificationWrapper
    //   title: Text('Location: ${location.toJson()}'),
    //   autoCloseDuration: const Duration(seconds: 5),
    // );
    // print('Location: ${location.toJson()}');
  }

  void _onLocationServicesStatusChanged(bool status) {
    debugPrint('Is Location Services Enabled: $status');
  }

  void _onError(error) {
    final errorCode = geofenceservice.getErrorCodesFromError(error);
    if (errorCode == null) {
      debugPrint('Undefined error: $error');
      return;
    }
    debugPrint('Error Code: $errorCode');
  }

  void _toggleOnline(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('isOnline', value);
    setState(() {
      _isOnline = value;
      if (_isOnline) {
        _startLocationUpdates();
      } else {
        _stopLocationUpdates();
      }
    });
  }

//update user's location when online
  void _startLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer =
        Timer.periodic(const Duration(minutes: 1), (Timer timer) async {
      Position position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      toastification.show(
        context: context,
        title: Text(
            'Current Location: ${position.latitude}, ${position.longitude}'),
        autoCloseDuration: const Duration(seconds: 5),
      );
      // print('Current Location: ${position.latitude}, ${position.longitude}');
    });
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    debugPrint('Location tracking stoped');
  }

  void _checkIn() {
    if (_isInsideGeofence) {
      // Handle check-in logic here
      // print('Checked in!');
      toastification.show(
        context: context, // optional if you use ToastificationWrapper
        title: const Text('CHECKED IN'),
        autoCloseDuration: const Duration(seconds: 5),
      );
    } else {
      debugPrint('You are outside the geofence!');
    }
  }

  @override
void dispose() {
  _locationTimer?.cancel();
  _geofenceService.removeGeofenceStatusChangeListener(_onGeofenceStatusChanged);
  _geofenceService.removeLocationChangeListener(_onLocationChanged);
  _geofenceService.removeLocationServicesStatusChangeListener(_onLocationServicesStatusChanged);
  _geofenceService.removeStreamErrorListener(_onError);
  _geofenceService.stop(); // Ensures the service is stopped
  super.dispose();
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
