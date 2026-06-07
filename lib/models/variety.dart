class Variety {
  int varietyId;
  String name;
  String code;
  String? brand;
  double? quantity;
  String? unit;
  String? countryOfOrigin;
  String? additionalSpecs;
  int isNew;

  Variety({
    required this.varietyId,
    required this.name,
    required this.code,
    required this.isNew,
  });

  @override
  String toString() {
    return """
      {code: $code,
       name: $name,
       varietyId: $varietyId,
       countryOfOrigin: $countryOfOrigin,
       quantity: $quantity,
       unit: $unit,
       countryOfOrigin: $countryOfOrigin,
       additionalSpecs: $additionalSpecs,
       isNew: $isNew,}
    """;
  }

  Map<String, dynamic> toMap() => {
        "varietyId": varietyId,
        "name": name,
        "code": code,
        "brand": brand,
        "quantity": quantity,
        "unit": unit,
        "countryOfOrigin": countryOfOrigin,
        "additionalSpecs": additionalSpecs,
        "isNew": isNew,
      };

  Map<String, dynamic> mapForApi() => {
        "mobile_id": varietyId,
        "name": name,
        "code": code,
      };
}
