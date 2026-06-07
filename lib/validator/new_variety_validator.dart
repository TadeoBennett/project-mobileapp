class NewVarietyValidator {
  String? productValidator(value) {
    return value.length <= 2 ? 'Enter a valid product name' : null;
  }

  String? brandValidator(value) {
    return value.length <= 2 ? 'Enter a valid brand name' : null;
  }

  String? measurementValidator(value) {
    if (value == null || value == '') {
      return 'Enter a valid number';
    }
    value = double.parse(value);
    return value < 0.1 ? 'Enter a valid number' : null;
  }

  String? unitValidator(value) {
    return value.length < 2 ? 'Enter a valid unit of measurement' : null;
  }

  String? priceValidator(value) {
    if (value == null || value == '') {
      return 'Enter a valid number';
    }
    value = double.parse(value);
    return value < 0.1 ? "Enter a valid price" : null;
  }
}
