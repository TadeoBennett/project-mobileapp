import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:location/location.dart';

class UtilityFunctions {
  //used to write to local storage
  final localStorage = GetStorage();

  Future<bool> isInternetConnected() async {
    try {
      final response = await InternetAddress.lookup('www.google.com');
      return response.isNotEmpty;
    } on SocketException catch (e) {
      return false;
    }
  }

  //used to check if the location is enabled in the app
  Future<bool> locationEnabled() async {
    Location location = new Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return false;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  static String getParsedCode(String code) {
    return code.substring(0, 23);
  }

  //used to get the current Location
  Future<Map<String, dynamic>> getCurrentLocation() async {
    Location location = Location();
    final locationData = await location.getLocation();
    return {
      'latitude': locationData.latitude,
      'longitude': locationData.longitude,
    };
  }

  void logUserOut() {
    localStorage.remove('id');
    localStorage.remove('username');
    localStorage.remove('token');
    localStorage.remove('areaId');
    localStorage.remove('email');
  }
}
