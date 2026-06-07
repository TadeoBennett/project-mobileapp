class Substitute {
  int assignmentId;
  int outletSourceId;
  int newOutletId;
  int newVarietyId;
  double price;
  String comment;
  String collectedAt;
  int isUploaded;
  int failedAutoSync;
  double? lat;
  double? long;

  Substitute(
      {required this.assignmentId,
      required this.outletSourceId,
      required this.newOutletId,
      required this.newVarietyId,
      required this.price,
      required this.comment,
      required this.collectedAt,
      required this.isUploaded,
      required this.failedAutoSync,
      this.lat,
      this.long});

  Map<String, dynamic> toMap() => {
        "assignmentId": assignmentId,
        "outletSourceId": outletSourceId,
        "newOutletId": newOutletId,
        "newVarietyId": newVarietyId,
        "price": price,
        "comment": comment,
        "collectedAt": collectedAt,
        "isUploaded": isUploaded,
        "failedAutoSync": failedAutoSync,
        "lat": lat,
        "long": long
      };

  mapForApi() => {
        "assignment_id": assignmentId,
        "outlet_id": newOutletId,
        "variety_id": newVarietyId,
        "price": price,
        "comment": comment,
        "collected_at": collectedAt,
        "lat": lat,
        "long": long,
      };

  @override
  String toString() {
    return ' assignmentId $assignmentId'
        ' outletSourceId $outletSourceId'
        ' newOutletId $newOutletId'
        ' newVarietyId $newVarietyId'
        ' price $price'
        ' comment $comment'
        ' collectedAt $collectedAt'
        ' isUploaded $isUploaded'
        ' failedAutoSync $failedAutoSync'
        ' lat $lat'
        ' long $long';
  }
}
