import 'package:cpi_app/models/globals.dart';
import 'package:cpi_app/models/http_exception.dart';
import 'package:cpi_app/models/user.dart';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';

class UserAuth {
  //used to write to local storage
  final localStorage = GetStorage();

  //Used to authenticate the user
  Future<Map<String, dynamic>> authenticateUser(
      String username, String password) async {
    try {
      print('${Global.apiBaseUrl}/login');

      //make http request to login and verify if the user was logged in properly
      Response response = await Global.dio.post('${Global.apiBaseUrl}/login',
          data: {
            'username': username,
            'password': password,
            'type': "collector"
          });

      print(response.data);

      User loggedUser = User(
        id: response.data['user']['id'],
        username: response.data['user']['username'],
        email: response.data['user']['email'],
        areaId: response.data['user']['area_id'],
        token: response.data['token'],
        userType: response.data['user']['type'],
      );

      int? lastLoginUserId = getCurrentUserId();
      saveCurrentUserId(response.data['user']['id']);
      saveUserOnLocalStorage(loggedUser);

      return {
        "lastLoginUserId": lastLoginUserId,
        "currentUserId": response.data['user']['id'],
        "currentUserType": response.data['user']['type'],
      };
    } on DioError catch (error) {
      //used to handle http errors!
      if (error.response?.statusCode == 400) {
        throw HttpException('Invalid Credentials!', 400);
      }

      //used to handle http errors!
      if (error.response?.statusCode == 401) {
        throw HttpException('Not Authenticated!', 401);
      }

      print(error);

      throw HttpException('Server is down try again later!', 500);
    } catch (error) {
      print(error);
      //Used to handle any errors!
      throw HttpException('Something Went wrong Contact Admin!', 600);
    }
  }

  //used to store the user on local Storage
  void saveUserOnLocalStorage(User user) {
    print("SAVING LOCAL STORAGE ");
    print(user);

    //save the user to the local storage
    localStorage.write('id', user.id);
    localStorage.write('username', user.username);
    localStorage.write('email', user.email);
    localStorage.write('areaId', user.areaId);
    localStorage.write('token', user.token);
    localStorage.write('userType', user.userType);
  }

  User? user() {
    try {
      //get user from local storage and return details
      final user = User(
          id: localStorage.read('id'),
          username: localStorage.read('username'),
          token: localStorage.read('token'),
          areaId: localStorage.read('areaId'),
          email: localStorage.read('email'),
          userType: localStorage.read('userType'));

      return user;
    } catch (error) {
      return null;
    }
  }

  int? getCurrentUserId() {
    return localStorage.read('currentUserId');
  }

  void saveCurrentUserId(int userId) {
    localStorage.write('currentUserId', userId);
  }

  void clearUserInformation() {
    localStorage.remove('id');
    localStorage.remove('username');
    localStorage.remove('token');
    localStorage.remove('areaId');
    localStorage.remove('email');
    localStorage.remove('userType');
  }

  //used to send  a FCM token to the server to keep track of the user device
  Future<void> sendFCMTokenToServer(String token) async {
    try {
      //make http request to submit the user FCM token
      Response response = await Global.dio.post('${Global.apiBaseUrl}/user-fcm',
          data: {'token': token, 'application': 'collector-app'},
          options: Options(headers: {
            'Authorization': 'Bearer ${UserAuth().user()?.token}'
          }));

      print(response.data);
    } catch (error) {
      print(error);
      //Used to handle any errors!
      throw HttpException('Something Went wrong Contact Admin!', 500);
    }
  }
}
