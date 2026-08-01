import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class Global {
  // static const apiBaseUrl = '';
  // static const apiBaseUrl = 'http://127.0.0.1:8080';
  static const apiBaseUrl = 'https://goldsmith-elsewhere-coveted.ngrok-free.dev/api';
  //Used to make the http request

  static Dio dio = Dio(BaseOptions(
    baseUrl: Global.apiBaseUrl,
    receiveTimeout: 180000, // 3min
    connectTimeout: 60000,
    sendTimeout: 90000, // 1.5min
  ));

  //Globals for the database transactions
  static const outletTable = 'outlet';
  static const varietyTable = 'variety';
  static const assignmentTable = 'assignment';
  static const substitutionTable = 'substitute';

  //Globals for variety management
  static const newVarietyCode = 'NEW';

  //Global Current time Period
  static getCurrentTimePeriod() {
    final DateFormat dateFormatter = DateFormat('yyyy-MM-01');
    String currentTimePeriod = dateFormatter.format(DateTime.now());
    currentTimePeriod = '2024-07-01';
    return currentTimePeriod;
  }
}
