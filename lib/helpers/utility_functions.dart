import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';

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

  Future<bool> locationEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static String getParsedCode(String code) {
    return code.substring(0, 23);
  }

  Future<Map<String, dynamic>> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
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
