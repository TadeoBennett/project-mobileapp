class LoginValidator {
  String? userValidator(value) {
    return value.length <= 2 ? 'Enter a valid username' : null;
  }

  String? pwdValidator(value) {
    return value.length < 4 ? "Password too short" : null;
  }
}
