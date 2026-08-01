import 'package:cpi_app/helpers/auth.dart';
import 'package:cpi_app/helpers/db.dart';
import 'package:cpi_app/helpers/utility_functions.dart';
import 'package:cpi_app/models/assignment.dart';
import 'package:cpi_app/models/globals.dart';
import 'package:cpi_app/models/http_exception.dart';
import 'package:cpi_app/models/outlet.dart';
import 'package:cpi_app/providers/assignments.dart';
import 'package:cpi_app/providers/substitutions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:collection/collection.dart';

final outletsProvider = ChangeNotifierProvider<Outlets>((ref) {
  return Outlets(ref.read);
});

class Outlets with ChangeNotifier {
  Outlets(this.read);

  final Reader read;

  List<Outlet> _outlets = [];

  //Downloads all the outlets from the server and replaces current data with the new data
  Future<void> hardDownload() async {
    try {
      final response = await Global.dio.get(
          '${Global.apiBaseUrl}/outlets/user-outlets/${UserAuth().user()?.id}',
          options: Options(headers: {
            'Authorization': 'Bearer ${UserAuth().user()?.token}'
          }));

      final List<Outlet> extractedOutlets = [];

      //Clear the current outlets from the database
      await DBHelper.clearTable(Global.outletTable);

      for (final item in response.data) {
        Outlet outlet = Outlet(
          outletId: item['id'],
          estName: item['est_name'],
          note: item['note'],
          lat: double.tryParse((item['lat']).toString()),
          long: double.tryParse((item['long']).toString()),
          address: item['address'],
          phone: (item['phone']).toString(),
          areaId: item['area_id'],
          isEdited: 0,
          isCompleted: 0,
          isUploaded: 0,
          isNew: 0,
          failedAutoSync: 0,
        );

        extractedOutlets.add(outlet);
        await DBHelper.insert(Global.outletTable, outlet.toMap());
      }

      await DBHelper.bulkInsert(Global.outletTable, extractedOutlets);

      _outlets = extractedOutlets;
      notifyListeners();
    } on DioError catch (error) {
      //used to handle Authenticated errors!
      if (error.response?.statusCode == 401) {
        throw HttpException('Not Authenticated!', 401);
      }

      //used to handle http errors
      throw HttpException('Server is down try again later!', 500);
    } catch (error) {
      print(error);
      //Used to handle any errors!
      throw HttpException('Something Went wrong Contact Admin!', 600);
    }
  }

  //Used to download outlets from the server
  Future<void> downloadOutlets() async {
    try {
      final response = await Global.dio.get(
          '${Global.apiBaseUrl}/outlets/user-outlets/${UserAuth().user()?.id}',
          options: Options(headers: {
            'Authorization': 'Bearer ${UserAuth().user()?.token}'
          }));

      final List<Outlet> extractedOutlets = [];

      //Clear the current outlets from the database
      await DBHelper.clearTable(Global.outletTable);

      for (final item in response.data) {
        Outlet outlet = Outlet(
          outletId: item['id'],
          estName: item['est_name'],
          note: item['note'],
          lat: double.tryParse((item['lat']).toString()),
          long: double.tryParse((item['long']).toString()),
          address: item['address'],
          phone: (item['phone']).toString(),
          areaId: item['area_id'],
          isEdited: 0,
          isCompleted: 0,
          isUploaded: 0,
          isNew: 0,
          failedAutoSync: 0,
          email: item['email'],
          openingTime: item['opening_time'],
          closingTime: item['closing_time'],
          photoUrl: item['photo_url'],
          photoUpdatedAt: item['photo_updated_at'],
        );

        extractedOutlets.add(outlet);
        await DBHelper.insert(Global.outletTable, outlet.toMap());
      }

      await DBHelper.bulkInsert(Global.outletTable, extractedOutlets);
      _outlets = extractedOutlets;

      notifyListeners();
    } on DioError catch (error) {
      //used to handle Authenticated errors!
      if (error.response?.statusCode == 401) {
        throw HttpException('Not Authenticated!', 401);
      }
      //used to handle http errors
      throw HttpException('Server is down try again later!', 500);
    } catch (error) {
      print(error);
      //Used to handle any errors!
      throw HttpException('Something Went wrong Contact Admin!', 600);
    }
  }

  //Clears all Outlets
  Future<void> clearOutlets() async {
    try {
      //Clears the current data of Outlets Table
      await DBHelper.clearTable(Global.outletTable);

      //Sets the current substitution to memory
      _outlets = [];
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  //returns a copy of the current outlets
  List<Outlet> get outlets {
    return [..._outlets];
  }

  //get the current outlets from the local database
  Future<void> initialize() async {
    //Get the current assignments
    final dbOutlets = await DBHelper.getData(Global.outletTable);

    //transforms the current assignments
    final localOutlets = dbOutlets.map((outlet) {
      print(outlet);

      return Outlet(
          outletId: outlet["outletId"],
          estName: outlet["estName"],
          note: outlet["note"],
          lat: outlet["lat"],
          long: outlet["long"],
          address: outlet["address"],
          phone: outlet["phone"],
          areaId: outlet["areaId"],
          isEdited: outlet["isEdited"],
          isCompleted: outlet["isCompleted"],
          isUploaded: outlet["isUploaded"],
          isNew: outlet["isNew"],
          failedAutoSync: outlet["failedAutoSync"],
          email: outlet["email"],
          openingTime: outlet["openingTime"],
          closingTime: outlet["closingTime"],
          photoLocalPath: outlet["photoLocalPath"],
          photoUrl: outlet["photoUrl"],
          photoUpdatedAt: outlet["photoUpdatedAt"],
          photoNeedsSync: outlet["photoNeedsSync"] ?? 0);
    }).toList();

    //replaces the existing assignments
    _outlets = localOutlets;
    notifyListeners();
  }

  //get the outlet by id from the local outlets
  Outlet getOutletById(int outletId) {
    return _outlets.firstWhere((outlet) => outlet.outletId == outletId);
  }

  //get the outlet options for substitution
  List<Outlet> getOutletOptionsForSubstitution(int outletId) {
    return _outlets.where((outlet) => outlet.outletId != outletId).toList();
  }

  //inserts/Updates a new outlet to the database
  Future<void> insertOrUpdate(Outlet outlet) async {
    //verify if the outlet is new or not
    if (outlet.outletId == 0) {
      //if new then the outletId needs to be changed from 0 to most available
      int? lastInsertId = await DBHelper.findLastInsertId(Global.outletTable);
      if (lastInsertId != null) {
        outlet.outletId = lastInsertId + 1;
      } else {
        outlet.outletId = 1;
      }
    }

    int outletId = await DBHelper.insert(Global.outletTable, outlet.toMap());

    _outlets.removeWhere(((element) => element.outletId == outletId));
    _outlets.add(outlet);
    notifyListeners();
  }

  //Updates an outlet on the local database
  Future<void> updateLocation(int outletId) async {
    //get the location from the device location services
    final position = await determinePosition();

    //get the long and lat from the position
    double lat = position.latitude;
    double long = position.longitude;

    Outlet oldOutlet =
        _outlets.firstWhere((element) => element.outletId == outletId);
    oldOutlet.lat = lat;
    oldOutlet.long = long;
    oldOutlet.isEdited = 1;
    oldOutlet.isUploaded = 0;

    //update the outlet in the database and memory
    await DBHelper.update(
        tableName: Global.outletTable,
        row: oldOutlet.toMap(),
        where: 'outletId = ?',
        whereArgs: [outletId]);

    notifyListeners();
  }

  /// are denied the `Future` will return an error.
  Future<Position> determinePosition() async {
    //get the current location permission status
    bool hasPermission = await UtilityFunctions().locationEnabled();

    if (!hasPermission) {
      return Future.error(
          'Location Was not changed! Please allow the device to access the device location to update!');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.

    final position = await Geolocator.getCurrentPosition();

    return position;
  }

  //Gets outlets that have been modified
  List<Outlet> editedOutletsForSync() {
    return _outlets
        .where((element) => element.isEdited == 1 && element.isNew == 0)
        .toList();
  }

  //Gets outlets that have been added
  List<Outlet> addedOutletsForSync() {
    return _outlets.where((element) => element.isNew == 1).toList();
  }

  //Used to upload the outlets to the server
  Future<void> uploadOutlets() async {
    //get the outlets that have been edited
    List<Outlet> editedOutlets = editedOutletsForSync();

    //get the outlets that have been added
    List<Outlet> addedOutlets = addedOutletsForSync();

    //upload the new outlet to the server
    await uploadNewOutlet(addedOutlets);
    await uploadEditOutlet(editedOutlets);
  }

  //used to upload all new outlet to the server
  Future<void> uploadNewOutlet(List<Outlet> addedOutlets) async {
    try {
      //prevent unnecessary uploads
      if (addedOutlets.isEmpty) {
        return;
      }

      //Map the outlets to a list of maps to be uploaded
      List<Map<String, dynamic>> outletMaps = addedOutlets.map((outlet) {
        return outlet.mapForApi();
      }).toList();

      //make a new request to the server
      final response = await Global.dio.post('/outlets',
          data: outletMaps,
          options: Options(headers: {
            'Authorization': 'Bearer ${UserAuth().user()?.token}'
          }));

      //loop through the response and update the local database and memory list
      for (final item in response.data) {
        //get the old outlet id
        int oldOutletId = item['mobile_id'];

        Outlet outlet = getOutletById(oldOutletId);
        outlet.outletId =
            item['id']; // set the new outlet id returned by server
        outlet.isNew = 0;
        outlet.isUploaded = 1;
        outlet.isEdited = 0;

        await DBHelper.update(
            tableName: Global.outletTable,
            row: outlet.toMap(),
            where: 'outletId = ?',
            whereArgs: [oldOutletId]);

        //Update the Substitutions that point to the old outlet id if any
        read(substitutionsProvider)
            .updateNewOutletId(oldOutletId, outlet.outletId);
      }

      notifyListeners();
    } on DioError catch (error) {
      //used to handle Authenticated errors!
      if (error.response?.statusCode == 401) {
        throw HttpException('Not Authenticated!', 401);
      }

      //used to handle http errors
      print(error);
      throw HttpException('Server is down try again later! Could not upload new outlet.', 500);
    } catch (error) {
      print(error);
      //Used to handle any errors!
      throw HttpException('Something Went wrong Contact Admin!', 600);
    }
  }

  //used to upload a single edited outlet to the server
  Future<void> uploadEditOutlet(List<Outlet> editedOutlets) async {
    try {
      //prevent unnecessary uploads
      if (editedOutlets.isEmpty) {
        return;
      }

      //Map the outlets to a list of maps to be uploaded
      List<Map<String, dynamic>> outletMaps = editedOutlets.map((outlet) {
        return outlet.mapForApi();
      }).toList();

      //make a new request to the server
      await Global.dio.put('/outlets',
          data: outletMaps,
          options: Options(headers: {
            'Authorization': 'Bearer ${UserAuth().user()?.token}'
          }));

      //loop through the response and update the local database and memory list
      for (final outlet in editedOutlets) {
        outlet.isNew = 0;
        outlet.isUploaded = 1;
        outlet.isEdited = 0;

        await DBHelper.update(
            tableName: Global.outletTable,
            row: outlet.toMap(),
            where: 'outletId = ?',
            whereArgs: [outlet.outletId]);
      }

      notifyListeners();
    } on DioError catch (error) {
      //used to handle Authenticated errors!
      if (error.response?.statusCode == 401) {
        throw HttpException('Not Authenticated!', 401);
      }

      //used to handle http errors
      print(error);
      throw HttpException('Server is down try again later! Could not upload edited outlet.', 500);
    } catch (error) {
      print(error);
      //Used to handle any errors!
      throw HttpException('Something Went wrong Contact Admin!', 600);
    }
  }

  //Called when a collector snaps a new outlet photo. Saves the local path and
  //marks it pending immediately (so the pending state survives even if the
  //upload below fails or the app is killed), then tries to upload right away.
  //Any failure here (offline or otherwise) is swallowed silently - the photo
  //stays queued and will be retried by syncPendingPhotos() on the next manual sync.
  Future<void> capturePhoto(int outletId, String localFilePath) async {
    Outlet outlet = getOutletById(outletId);
    outlet.photoLocalPath = localFilePath;
    outlet.photoNeedsSync = 1;

    await DBHelper.update(
        tableName: Global.outletTable,
        row: outlet.toMap(),
        where: 'outletId = ?',
        whereArgs: [outletId]);

    notifyListeners();

    try {
      await uploadOutletPhoto(outletId, localFilePath);
      outlet.photoNeedsSync = 0;

      await DBHelper.update(
          tableName: Global.outletTable,
          row: outlet.toMap(),
          where: 'outletId = ?',
          whereArgs: [outletId]);

      notifyListeners();
    } catch (error) {
      //silently queue for the next manual sync
    }
  }

  //Uploads a single outlet photo to the server and updates the outlet's photoUrl/photoUpdatedAt
  Future<void> uploadOutletPhoto(int outletId, String filePath) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath,
          filename: filePath.split('/').last),
    });

    final response = await Global.dio.post('/outlets/$outletId/photo',
        data: formData,
        options: Options(
            headers: {'Authorization': 'Bearer ${UserAuth().user()?.token}'}));

    Outlet outlet = getOutletById(outletId);
    outlet.photoUrl = response.data['photo_url'];
    outlet.photoUpdatedAt = response.data['photo_updated_at'];
  }

  //Gets outlets with a photo captured locally that hasn't been uploaded yet
  List<Outlet> outletsWithPendingPhotoForSync() {
    return _outlets.where((element) => element.photoNeedsSync == 1).toList();
  }

  //Used during manual sync to upload any photos that failed to upload immediately
  Future<void> syncPendingPhotos() async {
    List<Outlet> pendingOutlets = outletsWithPendingPhotoForSync();

    if (pendingOutlets.isEmpty) {
      return;
    }

    try {
      for (final outlet in pendingOutlets) {
        await uploadOutletPhoto(outlet.outletId, outlet.photoLocalPath!);
        outlet.photoNeedsSync = 0;

        await DBHelper.update(
            tableName: Global.outletTable,
            row: outlet.toMap(),
            where: 'outletId = ?',
            whereArgs: [outlet.outletId]);
      }

      notifyListeners();
    } on DioError catch (error) {
      if (error.response?.statusCode == 401) {
        throw HttpException('Not Authenticated!', 401);
      }
      throw HttpException('Server is down try again later! Could not sync pending photos.', 500);
    } catch (error) {
      print(error);
      throw HttpException('Something Went wrong Contact Admin!', 600);
    }
  }

  //Used to get the outlets that have a location
  List<Outlet> getOutletsWithLocation() {
    final emptyLocations = [null, 0, 0.0];

    return _outlets.where((element) {
      return emptyLocations.contains(element.long) != true &&
          emptyLocations.contains(element.lat) != true;
    }).toList();
  }

  //used to get the outlets for the outlet screen
  List<Outlet> getOutletsWithAssignmentsOrNew() {
    List<Outlet> outlets = [];
    for (Outlet outlet in _outlets) {
      // if outlet is new the show it in screen
      if (outlet.isNew == 1) {
        outlets.add(outlet);
      } else {
        // checks if the outlet has assignments
        List<Assignment> assignments =
            read(assignmentsProvider).getByOutletId(outlet.outletId);
        if (assignments.isNotEmpty) {
          outlets.add(outlet);
        }
      }
    }
    return outlets;
  }
}
