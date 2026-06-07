import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class Global {
  // static const apiBaseUrl = 'https://cpi.sib.org.bz/api';
  static const apiBaseUrl = 'http://10.10.1.232:8080/api';
  //Used to make the http request

  static Dio dio = Dio(BaseOptions(
    baseUrl: Global.apiBaseUrl,
    receiveTimeout: 45000, // 15 seconds
    connectTimeout: 10000,
    sendTimeout: 45000,
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
    return currentTimePeriod;
  }
}
