class User {
  final int id;
  final int areaId;
  final String username;
  final String? password;
  final String email;
  final String? token;
  final String? userType;

  User(
      {required this.id,
      required this.areaId,
      required this.username,
      this.password,
      required this.email,
      this.token,
      this.userType});

  @override
  String toString() {
    return '$email $token $username $areaId $userType';
  }
}
