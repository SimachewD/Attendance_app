import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geofence_service/geofence_service.dart' as geofenceservice;
import 'package:toastification/toastification.dart';

class GeofenceServiceHandler {
  Function(bool)? onGeofenceStatusChanged;
  GeofenceServiceHandler({this.onGeofenceStatusChanged});

  BuildContext? _context;
  Timer? _locationTimer;

  void initialize({required Function(bool) onGeofenceStatusChanged}) {
    this.onGeofenceStatusChanged = onGeofenceStatusChanged;
  }

  final geofenceservice.GeofenceService _geofenceService =
      geofenceservice.GeofenceService.instance.setup(
    interval: 5000,
    accuracy: 100,
    loiteringDelayMs: 30000,
    statusChangeDelayMs: 10000,
    useActivityRecognition: false,
    allowMockLocations: false,
    printDevLog: false,
    geofenceRadiusSortType: geofenceservice.GeofenceRadiusSortType.DESC,
  );

  final List<geofenceservice.Geofence> _geofenceList = [
    geofenceservice.Geofence(
      id: 'place_2',
      latitude: 8.9924164,
      longitude: 38.7922022,
      radius: [
        geofenceservice.GeofenceRadius(id: 'radius_500m', length: 500),
      ],
    ),
  ];

  void setupGeofenceListeners(BuildContext context) {
    _context = context; // Assign context here
    _geofenceService.addGeofenceStatusChangeListener(
        _onGeofenceStatusChanged); // add a function to listen geofence status event (ENTER, EXIT)
    _geofenceService.addLocationChangeListener(
        _onLocationChanged); // listen to location change
    _geofenceService.addLocationServicesStatusChangeListener(
        _onLocationServicesStatusChanged); //listen for location service changes
    _geofenceService.addStreamErrorListener(_onError); // listener for errors
    // _geofenceService.addActivityChangeListener(_onActivityChanged);
  }

  void startGeofenceService() {
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
    final bool isInside;
    if (geofenceStatus == geofenceservice.GeofenceStatus.ENTER || 
    geofenceStatus == geofenceservice.GeofenceStatus.DWELL) {
      isInside = true; //when a user gets inside the geofence or stays out there, set isInside True
    } else if (geofenceStatus == geofenceservice.GeofenceStatus.EXIT) {
      isInside = false; ////when a user leaves the geofence, set isInside False
    } else {
        return; // Early exit for other statuses
    }

    // Trigger the callback if it's set
    if (onGeofenceStatusChanged != null) {
      onGeofenceStatusChanged!(isInside);
    }

    toastification.show(
      context: _context,
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

  void disposing() {
    _locationTimer?.cancel();
    _geofenceService
        .removeGeofenceStatusChangeListener(_onGeofenceStatusChanged);
    _geofenceService.removeLocationChangeListener(_onLocationChanged);
    _geofenceService.removeLocationServicesStatusChangeListener(
        _onLocationServicesStatusChanged);
    _geofenceService.removeStreamErrorListener(_onError);
    _geofenceService.stop();
  }
}
