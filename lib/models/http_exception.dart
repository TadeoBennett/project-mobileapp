import 'package:flutter_riverpod/flutter_riverpod.dart';

class HttpException implements Exception {
  String message;
  int status;

  HttpException(this.message, this.status);

  @override
  String toString() {
    return message;
  }
}
