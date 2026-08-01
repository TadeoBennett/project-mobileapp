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
  String? openingTime;
  String? closingTime;
  String? photoLocalPath;
  String? photoUrl;
  String? photoUpdatedAt;
  int photoNeedsSync = 0;

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
    this.openingTime,
    this.closingTime,
    this.photoLocalPath,
    this.photoUrl,
    this.photoUpdatedAt,
    this.photoNeedsSync = 0,
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
      'email': email,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'photoLocalPath': photoLocalPath,
      'photoUrl': photoUrl,
      'photoUpdatedAt': photoUpdatedAt,
      'photoNeedsSync': photoNeedsSync,
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
        'email': email,
        'openingTime': openingTime,
        'closingTime': closingTime,
        'photoLocalPath': photoLocalPath,
        'photoUrl': photoUrl,
        'photoUpdatedAt': photoUpdatedAt,
        'photoNeedsSync': photoNeedsSync,
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
      'email': email,
      'opening_time': openingTime,
      'closing_time': closingTime,
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
        email: $email,
        openingTime: $openingTime,
        closingTime: $closingTime,
        photoNeedsSync: $photoNeedsSync
      }''';
}
