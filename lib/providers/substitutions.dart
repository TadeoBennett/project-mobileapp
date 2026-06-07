import 'package:cpi_app/helpers/auth.dart';
import 'package:cpi_app/helpers/db.dart';
import 'package:cpi_app/models/assignment.dart';
import 'package:cpi_app/models/globals.dart';
import 'package:cpi_app/models/http_exception.dart';
import 'package:cpi_app/models/outlet.dart';
import 'package:cpi_app/models/substitute.dart';
import 'package:cpi_app/models/variety.dart';
import 'package:cpi_app/providers/assignments.dart';
import 'package:cpi_app/providers/outlets.dart';
import 'package:cpi_app/providers/varieties.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final substitutionsProvider = ChangeNotifierProvider<Substitutions>((ref) {
  return Substitutions(ref.read);
});

class Substitutions with ChangeNotifier {
  Substitutions(this.read);
  final Reader read;

  List<Substitute> _substitutions = [];

  //returns a copy of the current substitutions
  List<Substitute> get substitutions {
    return [..._substitutions];
  }

  //Used to set the substitutions that come from the server on db and memory.
  Future<void> setSubstitutions(List<Substitute> substitutes) async {
    print("HERE");
    print(substitutes);

    //first thing we need to do is clear the substitutions that currently exist
    await DBHelper.clearTable(Global.substitutionTable);

    //Reinsert the substitution onto the table
    await DBHelper.bulkInsert(Global.substitutionTable, substitutes);

    _substitutions = substitutes;
    notifyListeners();
  }

  //Clears all substitutions
  Future<void> clearSubstitutions() async {
    try {
      //Clears the current data of substitutions Table
      await DBHelper.clearTable(Global.substitutionTable);

      //Sets the current substitution to memory
      _substitutions = [];
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  //get the current substitutions from the local database
  Future<void> initialize() async {
    //Get the current substitutes
    final dbSubstitutes = await DBHelper.getData(Global.substitutionTable);

    //transforms the current substitutes
    final localSubstitutes = dbSubstitutes.map((substitute) {
      return Substitute(
        assignmentId: substitute['assignmentId'],
        outletSourceId: substitute['outletSourceId'],
        newOutletId: substitute['newOutletId'],
        newVarietyId: substitute['newVarietyId'],
        price: substitute['price'],
        comment: substitute['comment'],
        collectedAt: substitute['collectedAt'],
        isUploaded: substitute['isUploaded'],
        failedAutoSync: substitute['failedAutoSync'],
        lat: substitute['lat'],
        long: substitute['long'],
      );
    }).toList();

    //replaces the existing substitutes
    _substitutions = localSubstitutes;
    notifyListeners();
  }

  //inserts a new substitute to the database
  Future<Substitute> insert(
      int assignmentId,
      int outletSourceId,
      int newOutletId,
      int newVarietyId,
      double price,
      String comment,
      double lat,
      double long) async {
    Substitute substitute = Substitute(
        assignmentId: assignmentId,
        outletSourceId: outletSourceId,
        newOutletId: newOutletId,
        newVarietyId: newVarietyId,
        isUploaded: 0,
        price: price,
        comment: comment,
        collectedAt: DateFormat('yyyy-MM-dd H:mm:s').format(DateTime.now()),
        failedAutoSync: 0,
        lat: lat,
        long: long);

    //insert the substitute to the database
    await DBHelper.insert(Global.substitutionTable, substitute.toMap());

    //add the substitute to the local list otherwise it replace the existing substitute
    if (getSubstitution(assignmentId) == null) {
      _substitutions.add(substitute);
    } else {
      _substitutions
          .removeWhere((substitute) => substitute.assignmentId == assignmentId);
      _substitutions.add(substitute);
    }
    notifyListeners();

    return substitute;
  }

  //clears a substitution from the database and memory
  Future<void> clearSubstitution(int assignmentId) async {
    try {
      //Clears the current data of substitution Table
      await DBHelper.delete(Global.substitutionTable,
          where: 'assignmentId = ?', whereArgs: [assignmentId]);

      //clear the substitute from the memory
      _substitutions
          .removeWhere((substitute) => substitute.assignmentId == assignmentId);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  //Gets the Substitute details of the given assignmentId otherwise null
  Substitute? getSubstitution(int assignmentId) {
    try {
      Substitute? substitute = _substitutions
          .firstWhere((substitute) => substitute.assignmentId == assignmentId);
      return substitute;
    } catch (e) {
      return null;
    }
  }

  //Used to remove a substitutions
  Future<void> removeSubstitute(int assignmentId) async {
    await DBHelper.delete(Global.substitutionTable,
        where: 'assignmentId = ?', whereArgs: [assignmentId]);
    _substitutions
        .removeWhere((substitute) => substitute.assignmentId == assignmentId);
    notifyListeners();
  }

  //updates the newOutletId of the substitute to what the server return when creating the outlet
  Future<void> updateNewOutletId(int oldOutletId, int newOutletId) async {
    //get all the substitutes that have the newOutletId as the oldOutletId
    List<Substitute> substitutes = _substitutions
        .where((substitute) => substitute.newOutletId == oldOutletId)
        .toList();

    //update the newOutletId of the substitutes
    for (Substitute substitute in substitutes) {
      substitute.newOutletId = newOutletId;
      await DBHelper.update(
          tableName: Global.substitutionTable,
          row: substitute.toMap(),
          where: 'assignmentId = ?',
          whereArgs: [substitute.assignmentId]);
    }

    notifyListeners();
  }

  Future<void> updateNewVarietyId(int oldVarietyId, int newVarietyId) async {
    //get all the substitutes that have the newVarietyId as the oldVarietyId
    List<Substitute> substitutes = _substitutions
        .where((substitute) => substitute.newVarietyId == oldVarietyId)
        .toList();

    //update the newVarietyId of the substitutes
    for (Substitute substitute in substitutes) {
      substitute.newVarietyId = newVarietyId;
      await DBHelper.update(
          tableName: Global.substitutionTable,
          row: substitute.toMap(),
          where: 'assignmentId = ?',
          whereArgs: [substitute.assignmentId]);
    }

    notifyListeners();
  }

  //Used to get the substitutions that require upload
  List<Substitute> getSubstitutionsForUpload() {
    return _substitutions
        .where((substitute) => substitute.isUploaded == 0)
        .toList();
  }

  //upload substitution helper (Does the actual uploading)
  Future<void> uploadSubstitutions() async {
    try {
      //get all the substitutes that have not been uploaded
      List<Substitute> substitutes = getSubstitutionsForUpload();

      //Maps of the substitutions
      List<Map<String, dynamic>> substitutionMap = [];

      //upload all the substitutes
      for (Substitute substitute in substitutes) {
        substitutionMap.add(substitute.mapForApi());
      }

      //upload the substitutes to the server
      await Global.dio.post('/substitutions',
          data: substitutionMap,
          options: Options(headers: {
            'Authorization': 'Bearer ${UserAuth().user()?.token}'
          }));

      //update the isUploaded field of the substitutes to 1
      for (Substitute substitute in substitutes) {
        substitute.isUploaded = 1;
        await read(assignmentsProvider)
            .setAssignmentUploaded(substitute.assignmentId);
        await DBHelper.update(
            tableName: Global.substitutionTable,
            row: substitute.toMap(),
            where: 'assignmentId = ?',
            whereArgs: [substitute.assignmentId]);
      }

      notifyListeners();
    } on DioError catch (error) {
      print(error);
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
}
