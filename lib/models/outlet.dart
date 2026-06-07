import '../helpers/auth.dart';

class Outlet {
  int outletId;
  String? address;
  int areaId = UserAuth().user()!.areaId;
  String phone;
  String estName;
  String? note;
  double? lat;
  double? long;
  int isCompleted = 0;
  int isUploaded = 0;
  int isEdited = 0;
  int isNew = 0;
  int failedAutoSync = 0;
  String? email;

  set setComplete(bool complete) {
    isCompleted = complete ? 1 : 0;
  }

  set setOutletId(int id) {
    outletId = id;
  }

  Outlet({
    required this.outletId,
    required this.areaId,
    required this.estName,
    this.note,
    this.lat,
    this.long,
    required this.address,
    required this.phone,
    required this.isCompleted,
    required this.isUploaded,
    required this.isEdited,
    required this.isNew,
    required this.failedAutoSync,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'outletId': outletId,
      'estName': estName,
      'note': note,
      'lat': lat,
      'long': long,
      'address': address,
      'phone': phone,
      'isEdited': isEdited,
      'isUploaded': isUploaded,
      'isCompleted': isCompleted,
      'isNew': isNew,
      'failedAutoSync': failedAutoSync,
      'areaId': areaId,
      'email': email
    };
  }

  Map toJson() => {
        'outletId': outletId,
        'estName': estName,
        'note': note,
        'lat': lat,
        'long': long,
        'address': address,
        'phone': phone,
        'areaId': UserAuth().user()?.areaId,
        'isNew': isNew,
        'isEdited': isEdited,
        'isUploaded': isUploaded,
        'isCompleted': isCompleted,
        'failedAutoSync': failedAutoSync,
        'email': email
      };

  Map<String, dynamic> mapForApi() {
    return {
      'mobile_id': outletId,
      'est_name': estName,
      'note': note,
      'lat': lat,
      'long': long,
      'address': address,
      'phone': phone,
      'area_id': areaId,
      'email': email
    };
  }

  @override
  String toString() => '''
      Outlet { 
        outletId: $outletId, 
        estName: $estName, 
        note: $note, 
        lat: $lat, 
        long: $long, 
        address: $address, 
        phone: $phone, 
        areaId: $areaId, 
        isNew: $isNew, 
        isEdited: $isEdited, 
        isUploaded: $isUploaded, 
        isCompleted: $isCompleted,
        failedAutoSync: $failedAutoSync ,
        email: $email
      }''';
}
