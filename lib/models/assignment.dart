class Assignment {
  int id;
  int outletProductVarietyId;
  String timePeriod;
  int varietyId;
  String varietyName;
  String? lastCollected;
  double? previousPrice;
  double? newPrice;
  String? collectedAt;
  String? comment;
  String code;
  String? outletName;
  int outletId;
  int canSubstitute;
  int requestSubstitute;
  int isRequestUploaded;
  int isSubstituted;
  int isUploaded;
  int isRejected;
  int isApprovedByHQ;
  int failedAutoSync;
  String? substitutionOutletName;
  String? substitutionVarietyName;
  String? collectorComment;
  String? collectorCollectedAt;
  double? lat;
  double? long;

  Assignment(
      {required this.id,
      required this.outletProductVarietyId,
      required this.timePeriod,
      required this.varietyName,
      required this.varietyId,
      this.lastCollected,
      this.previousPrice,
      this.newPrice,
      required this.collectedAt,
      this.comment,
      required this.code,
      required this.outletName,
      required this.outletId,
      required this.canSubstitute,
      required this.requestSubstitute,
      required this.isRequestUploaded,
      required this.isSubstituted,
      required this.isUploaded,
      required this.isRejected,
      required this.isApprovedByHQ,
      required this.failedAutoSync,
      this.substitutionOutletName,
      this.substitutionVarietyName,
      this.collectorComment,
      this.collectorCollectedAt,
      this.lat,
      this.long});

  @override
  String toString() {
    return "{ id: $id, "
        "outletProductVarietyId : $outletProductVarietyId, "
        "timePeriod : $timePeriod, "
        "varietyName: $varietyName,"
        "varietyId: $varietyId,"
        "lastCollected: $lastCollected,"
        "previousPrice : $previousPrice, "
        "newPrice : $newPrice, "
        "collectedAt : $collectedAt, "
        "comment : $comment, "
        "code : $code, "
        "outletName : $outletName, "
        "outletId : $outletId, "
        "canSubstitute : $canSubstitute, "
        "requestSubstitute : $requestSubstitute, "
        "isRequestUploaded : $isRequestUploaded,"
        "isSubstituted : $isSubstituted, "
        "isUploaded : $isUploaded, "
        "isRejected : $isRejected, "
        "isApprovedByHQ : $isApprovedByHQ, "
        "failedAutoSync : $failedAutoSync "
        "substitutionOutletName : $substitutionOutletName "
        "substitutionVarietyName : $substitutionVarietyName "
        "collectorComment: $collectorComment"
        "collectorCollectedAt: $collectorCollectedAt"
        "lat: $lat"
        "long: $long"
        "}";
  }

  Map<String, dynamic> toMap() => {
        "id": id,
        "outletProductVarietyId": outletProductVarietyId,
        "timePeriod": timePeriod,
        "varietyName": varietyName,
        "varietyId": varietyId,
        "lastCollected": lastCollected,
        "previousPrice": previousPrice,
        "newPrice": newPrice,
        "collectedAt": collectedAt,
        "comment": comment,
        "code": code,
        "outletName": outletName,
        "outletId": outletId,
        "canSubstitute": canSubstitute,
        "requestSubstitute": requestSubstitute,
        "isRequestUploaded": isRequestUploaded,
        "isSubstituted": isSubstituted,
        "isUploaded": isUploaded,
        "isRejected": isRejected,
        "isApprovedByHQ": isApprovedByHQ,
        "failedAutoSync": failedAutoSync,
        "substitutionOutletName": substitutionOutletName,
        "substitutionVarietyName": substitutionVarietyName,
        "collectorComment": collectorComment,
        "collectorCollectedAt": collectorCollectedAt,
        "lat": lat,
        "long": long
      };

  Map<String, dynamic> mapForApi() => {
        "id": id,
        "new_price": newPrice,
        "collected_at": collectedAt,
        "comment": comment,
        "lat": lat,
        "long": long,
      };
}
