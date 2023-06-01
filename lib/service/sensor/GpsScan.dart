//더미코드
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  double? mLatitude;
  double? mLongitude;
  double? mAltitude;
  double? mAccuracy;

  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  late Position position;


  Future<bool> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location Enabled!');

      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      debugPrint('Location Permission Dinied!');

      return false;
    }

    position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    mLatitude = position.latitude;
    mLongitude = position.longitude;
    mAltitude = position.altitude;
    mAccuracy = position.accuracy;

    return true;
  }

}