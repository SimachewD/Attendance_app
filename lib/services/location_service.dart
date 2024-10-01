import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toastification/toastification.dart';

class LocationService {

  Timer? _locationTimer;

  Future<void> requestGeofencePermissions() async {
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

  Future<void> checkLocationPermission() async {
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

  //update user's location when online
  void startLocationUpdates(BuildContext context) {
    _locationTimer?.cancel();
    _locationTimer =
        Timer.periodic(const Duration(seconds: 5), (Timer timer) async {
      Position position = await Geolocator.getCurrentPosition();
      toastification.show(
        context: context,
        title: Text(
            'Current Location: ${position.latitude}, ${position.longitude}'),
        autoCloseDuration: const Duration(seconds: 5),
      );
      // print('Current Location: ${position.latitude}, ${position.longitude}');
    });
  }

  void stopLocationUpdates() {
    _locationTimer?.cancel();
    debugPrint('Location tracking stoped');
  }
}
