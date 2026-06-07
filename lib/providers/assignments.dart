import 'package:cpi_app/helpers/auth.dart';
import 'package:cpi_app/helpers/db.dart';
import 'package:cpi_app/helpers/utility_functions.dart';
import 'package:cpi_app/models/assignment.dart';
import 'package:cpi_app/models/globals.dart';
import 'package:cpi_app/models/http_exception.dart';
import 'package:cpi_app/models/substitute.dart';
import 'package:cpi_app/models/user.dart';
import 'package:cpi_app/models/variety.dart';
import 'package:cpi_app/providers/substitutions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

final assignmentsProvider = ChangeNotifierProvider<Assignments>((ref) {
  return Assignments(ref.read);
});

class Assignments with ChangeNotifier {
  Assignments(this.read);
  final Reader read;

  List<Assignment> _assignments = [];

  //Downloads all the assignments from the server and replaces current data with the new data
  Future<void> hardDownload() async {
    try {
      final response = await Global.dio.get(
          '${Global.apiBaseUrl}/assignments/user-assignments/${UserAuth().user()?.id}',
          options: Options(headers: {
            'Authorization': 'Bearer ${UserAuth().user()?.token}'
          }));

      final List<Assignment> extractedAssignments = [];

      //Clears the current data of assignments Table
      await DBHelper.clearTable(Global.assignmentTable);

      for (final item in response.data) {
        int isRejected = item['status'] == 'rejected' ? 1 : 0;

        //verify if the assignment has been requested for substitution
        // int isRequestedForSubstitution =
        //     item['requested_substitution'] == null ? 0 : 1;

        Assignment assignment = Assignment(
          id: item['id'],
          outletProductVarietyId: item['outlet_product_variety_id'],
          timePeriod: item['time_period'],
          varietyName: item['variety_name'],
          varietyId: item['variety_id'],
          lastCollected: item['last_collected'],
          previousPrice: double.tryParse(item['previous_price'].toString()),
          newPrice: null,
          collectedAt: null,
          comment: item['comment'],
          code: item['code'],
          outletName: item['outlet_name'],
          outletId: item['outlet_id'],
          canSubstitute: item['can_substitute'] ? 1 : 0,
          requestSubstitute: 0,
          isRequestUploaded: 0,
          isSubstituted: 0,
          isUploaded: 0,
          isRejected: isRejected,
          isApprovedByHQ: 0,
          failedAutoSync: 0,
        );

        extractedAssignments.add(assignment);
      }

      await DBHelper.bulkInsert(Global.assignmentTable, extractedAssignments);

      //Sets the current assignment to memory
      _assignments = extractedAssignments;
      notifyListeners();

      print("COMPLETED DOWNLOADING ASSIGNMENTS");
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

  Future<void> downloadAssignments() async {
    try {
      //Verify where to pull the assignments from
      String endpointUrl =
          '${Global.apiBaseUrl}/assignments/user-assignments/${UserAuth().user()?.id}';

      // verify the type of User that is Syncing

      User? currentUser = UserAuth().user();

      if (currentUser != null && currentUser.userType == 'HQ') {
        String currentTimePeriod =
            DateFormat('yyyy-MM-01').format(DateTime.now());
        endpointUrl =
            '${Global.apiBaseUrl}/quality-assurance-assignment?hq_id=${UserAuth().user()?.id}&time_period=$currentTimePeriod';
      }

      final response = await Global.dio.get(endpointUrl,
          options: Options(headers: {
            'Authorization': 'Bearer ${UserAuth().user()?.token}'
          }));

      final List<Assignment> extractedAssignments = [];
      final List<Substitute> extractedSubstitutions = [];

      //Clears the current data of assignments Table
      await DBHelper.clearTable(Global.assignmentTable);

      for (final item in response.data) {
        print(item);
        // verify if it is rejected
        int isRejected = item['status'] == 'rejected' ? 1 : 0;

        //verify if the assignment has been requested for substitution
        int hasBeenRequestedForSubstitution =
            item['request_substitution_status'] == null ? 0 : 1;

        int canSubstitute = item['can_substitute'] ? 1 : 0;

        //verifies if the request for permission has been approved
        if (hasBeenRequestedForSubstitution == 1) {
          if (item['request_substitution_status'] == 'approved') {
            canSubstitute = 1;
          }
        }

        //get the substitution if any
        Map<String, dynamic>? substitution = item['substitution'];

        Assignment assignment = Assignment(
          id: item['id'],
          outletProductVarietyId: 1,
          timePeriod: item['time_period'],
          varietyName: item['variety_name'],
          varietyId: item['variety_id'],
          lastCollected: item['last_collected'],
          previousPrice: double.tryParse(item['previous_price'].toString()),
          newPrice: double.tryParse(item['new_price'].toString()),
          collectedAt: item["collected_at"],
          comment: item['comment'],
          code: item['code'],
          outletName: item['outlet_name'],
          outletId: item['outlet_id'],
          canSubstitute: canSubstitute,
          requestSubstitute: hasBeenRequestedForSubstitution,
          isRequestUploaded: hasBeenRequestedForSubstitution,
          isSubstituted: substitution == null ? 0 : 1,
          isUploaded:
              item["new_price"] == null && item['substitution'] == null ? 0 : 1,
          isRejected: isRejected,
          isApprovedByHQ: item["status"] == 'approved' ? 1 : 0,
          failedAutoSync: 0,
          substitutionOutletName: item['substitution_outlet_name'],
          substitutionVarietyName: item['substitution_variety_name'],
          collectorComment: item['collector_comment'],
          collectorCollectedAt: item['collector_collected_at'],
          lat: double.tryParse(item['lat'].toString()),
          long: double.tryParse(item['long'].toString()),
        );

        //if there is a substitution we need to create or update the substitution
        if (substitution != null && assignment.isRejected == 0) {
          //create a substitution object and add to extracted substitution
          Substitute newSubstitute = Substitute(
              assignmentId: assignment.id,
              outletSourceId: assignment.outletId,
              newVarietyId: substitution['variety_id'],
              newOutletId: substitution['outlet_id'],
              price: double.parse(substitution["price"] ?? "0"),
              comment: substitution["comment"],
              collectedAt: assignment.collectedAt ?? '',
              isUploaded: 1,
              failedAutoSync: 0,
              lat: double.tryParse(item['lat'].toString()),
              long: double.tryParse(item['long'].toString()));
          extractedSubstitutions.add(newSubstitute);
        }

        //check if the assignment has been rejected
        if (assignment.isRejected == 1) {
          assignment.newPrice = null;
          assignment.isUploaded = 0;
          assignment.isSubstituted = 0;
          assignment.comment = null;
        }

        extractedAssignments.add(assignment);
      }

      await DBHelper.bulkInsert(Global.assignmentTable, extractedAssignments);

      //Sets the current assignment to memory
      _assignments = extractedAssignments;
      notifyListeners();

      //Used to update the substitutions in the db and memory
      await read(substitutionsProvider)
          .setSubstitutions(extractedSubstitutions);

      print("COMPLETED DOWNLOADING ASSIGNMENTS");
    } on DioError catch (error) {
      //used to handle Authenticated errors!
      if (error.response?.statusCode == 401) {
        throw HttpException('Not Authenticated!', 401);
      }

      print(error);

      //used to handle http errors
      throw HttpException('Server is down try again later!', 500);
    } catch (error) {
      print(error);
      //Used to handle any errors!
      throw HttpException('Something Went wrong Contact Admin!', 600);
    }
  }

  //Clears all Assignments from memory and database
  Future<void> clearAssignments() async {
    try {
      //Clears the current data of Assignments Table
      await DBHelper.clearTable(Global.assignmentTable);

      //Sets the current assignment to memory
      _assignments = [];
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  //gets a copy list of the current assignments
  List<Assignment> get assignments {
    return [..._assignments];
  }

  //get the current assignments from the local database
  Future<void> initialize() async {
    //Get the current assignments
    final dbAssignments = await DBHelper.getData(Global.assignmentTable);

    //transforms the current assignments
    final localAssignments = dbAssignments.map((assignment) {
      return Assignment(
          id: assignment['id'],
          outletProductVarietyId: assignment["outletProductVarietyId"],
          timePeriod: assignment["timePeriod"],
          varietyName: assignment["varietyName"],
          varietyId: assignment["varietyId"],
          lastCollected: assignment["lastCollected"],
          previousPrice: assignment["previousPrice"],
          newPrice: assignment["newPrice"],
          collectedAt: assignment["collectedAt"],
          comment: assignment["comment"],
          code: assignment["code"],
          outletName: assignment["outletName"],
          outletId: assignment["outletId"],
          canSubstitute: assignment["canSubstitute"],
          requestSubstitute: assignment["requestSubstitute"],
          isRequestUploaded: assignment["isRequestUploaded"],
          isSubstituted: assignment["isSubstituted"],
          isUploaded: assignment["isUploaded"],
          isRejected: assignment["isRejected"],
          isApprovedByHQ: assignment["isApprovedByHQ"],
          failedAutoSync: assignment["failedAutoSync"],
          substitutionOutletName: assignment['substitutionOutletName'],
          substitutionVarietyName: assignment['substitutionVarietyName'],
          collectorComment: assignment['collectorComment'],
          collectorCollectedAt: assignment['collectorCollectedAt'],
          lat: assignment['lat'],
          long: assignment['long']);
    }).toList();

    print(localAssignments);

    //replaces the existing assignments
    _assignments = localAssignments;
    notifyListeners();
  }

  //gets assignment by id
  Assignment getAssignmentById(int id) {
    return _assignments.firstWhere((assignment) => assignment.id == id);
  }

  //Updates an assignment on the local database
  Future<void> updateAssignmentPrice(int assignmentId, double newPrice,
      String comment, String collectedAt, double lat, double long) async {
    Assignment assignment = getAssignmentById(assignmentId);
    assignment.newPrice = newPrice;
    assignment.comment = comment;
    assignment.isUploaded = 0;
    assignment.isSubstituted = 0;
    assignment.collectedAt = collectedAt;
    assignment.lat = lat;
    assignment.long = long;

    await DBHelper.update(
        tableName: Global.assignmentTable,
        row: assignment.toMap(),
        where: "id = ?",
        whereArgs: [assignmentId]);

    notifyListeners();
  }

  //used to simply update assignment and set it to substituted
  Future<void> substitutedAssignment(
      int assignmentId, double newPrice, String collectedAt) async {
    Assignment assignment = getAssignmentById(assignmentId);
    assignment.isSubstituted = 1;
    assignment.isUploaded = 0;
    assignment.newPrice = newPrice;
    assignment.collectedAt = collectedAt;

    await DBHelper.update(
        tableName: Global.assignmentTable,
        row: assignment.toMap(),
        where: "id = ?",
        whereArgs: [assignmentId]);

    // final rows = await DBHelper.filterTable(
    //     tableName: Global.assignmentTable,
    //     where: "assignmentId: ?",
    //     whereArgs: [assignmentId]);

    // print(rows);

    notifyListeners();

    return;
  }

  //used to update an assignment price (Perfect Match)
  Future<void> updateAssignmentAndSubstitutePrice(Assignment currentAssignment,
      double newPrice, String comment, int isSubstituted) async {
    String collectedAt = DateFormat('yyyy-MM-dd H:mm:s').format(DateTime.now());
    Assignment newAssignment = Assignment(
        id: currentAssignment.id,
        outletProductVarietyId: currentAssignment.outletProductVarietyId,
        timePeriod: currentAssignment.timePeriod,
        varietyName: currentAssignment.varietyName,
        varietyId: currentAssignment.varietyId,
        lastCollected: currentAssignment.lastCollected,
        previousPrice: currentAssignment.previousPrice,
        newPrice: newPrice,
        collectedAt: collectedAt,
        comment: comment,
        code: currentAssignment.code,
        outletName: currentAssignment.outletName,
        outletId: currentAssignment.outletId,
        canSubstitute: currentAssignment.canSubstitute,
        requestSubstitute: currentAssignment.requestSubstitute,
        isRequestUploaded: currentAssignment.isRequestUploaded,
        isSubstituted: isSubstituted,
        isUploaded: 0,
        isRejected: currentAssignment.isRejected,
        isApprovedByHQ: currentAssignment.isApprovedByHQ,
        failedAutoSync: currentAssignment.failedAutoSync);

    //updates the local database
    await DBHelper.update(
        tableName: Global.assignmentTable,
        row: newAssignment.toMap(),
        where: 'id = ?',
        whereArgs: [newAssignment.id]);

    //updates the current assignment in memory
    _assignments.removeWhere((assignment) => assignment.id == newAssignment.id);
    _assignments.add(newAssignment);
    notifyListeners();
  }

  //used to request substitution for an assignment
  Future<void> requestSubstitution(int assignmentId, int status) async {
    //find the assignment in the current assignments
    Assignment assignment =
        _assignments.firstWhere((assignment) => assignment.id == assignmentId);
    assignment.requestSubstitute = status;

    //updates the local database
    await DBHelper.update(
        tableName: Global.assignmentTable,
        row: assignment.toMap(),
        where: 'id = ?',
        whereArgs: [assignment.id]);

    //updates the current assignment in memory
    notifyListeners();
  }

  //used to get the assignments that have been uploaded
  List<Assignment> uploadedAssignments() {
    return _assignments
        .where(
            (element) => element.isUploaded == 1 && element.isSubstituted == 0)
        .toList();
  }

  //used to get the assignments that have been collected
  List<Assignment> collectedAssignments() {
    return _assignments
        .where(
            (element) => element.newPrice != null && element.isSubstituted == 0)
        .toList();
  }

  //used to get the substitutes sync
  List<Assignment> assignmentsSubstituted() {
    return _assignments.where((element) => element.isSubstituted == 1).toList();
  }

  //used to get the substitutes assignments that have been uploaded
  List<Assignment> uploadedSubstitutes() {
    return _assignments
        .where(
            (element) => element.isUploaded == 1 && element.isSubstituted == 1)
        .toList();
  }

  //used to get the assignments that have been requested for substitutions
  List<Assignment> requestedSubstitutionAssignments() {
    return _assignments
        .where((element) =>
            element.requestSubstitute == 1 &&
            element.canSubstitute == 0 &&
            element.isRequestUploaded == 0)
        .toList();
  }

  List<Assignment> uploadedRequestedSubstitutionAssignments() {
    return _assignments
        .where((element) =>
            element.requestSubstitute == 1 &&
            element.isRequestUploaded == 1 &&
            element.canSubstitute == 0)
        .toList();
  }

  //used to get the assignments that have been allowed to be substitutions
  List<Assignment> grantedRequestedSubstitutions() {
    return _assignments
        .where((element) =>
            element.canSubstitute == 1 && element.requestSubstitute == 1)
        .toList();
  }

  //used t upload the assignments to the server
  Future<void> uploadAssignments() async {
    try {
      //get the assignments that have not been uploaded
      List<Assignment> assignments = collectedAssignments()
          .where((element) => element.isUploaded == 0)
          .toList();

      // Format the data for the server
      List<Map<String, dynamic>> assignmentMaps = [];
      for (Assignment assignment in assignments) {
        assignmentMaps.add(assignment.mapForApi());
      }

      // Verify the type of User
      String endpointUrl = '/assignments-upload';
      User? user = UserAuth().user();

      if (user != null && user.userType == 'HQ') {
        endpointUrl = '/quality-assurance-assignment';
      }

      //upload the assignments
      await Global.dio.put(endpointUrl,
          data: assignmentMaps,
          options: Options(headers: {
            'Authorization': 'Bearer ${UserAuth().user()?.token}'
          }));

      //update the assignments that have been uploaded
      for (final assignment in assignments) {
        assignment.isUploaded = 1;
        await DBHelper.update(
            tableName: Global.assignmentTable,
            row: assignment.toMap(),
            where: 'id = ?',
            whereArgs: [assignment.id]);
      }

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

  //used to upload request the substitutions for the assignments on the server
  Future<void> uploadRequestedSubstitutions() async {
    try {
      //get the assignments that have not been uploaded
      List<Assignment> assignments = requestedSubstitutionAssignments();

      // Format the data for the server
      List<Map<String, dynamic>> assignmentMaps = [];
      for (Assignment assignment in assignments) {
        assignmentMaps.add({"assignment_id": assignment.id});
      }

      //upload the assignments
      await Global.dio.post('/request-substitutions',
          data: assignmentMaps,
          options: Options(headers: {
            'Authorization': 'Bearer ${UserAuth().user()?.token}'
          }));

      //update the assignments that have been uploaded
      for (final assignment in assignments) {
        assignment.isRequestUploaded = 1;

        await DBHelper.update(
            tableName: Global.assignmentTable,
            row: assignment.toMap(),
            where: 'id = ?',
            whereArgs: [assignment.id]);
      }

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

  //used to set an assignment as uploaded when substituted
  Future<void> setAssignmentUploaded(int assignmentId) async {
    //find the assignment in the current assignments
    Assignment assignment =
        _assignments.firstWhere((assignment) => assignment.id == assignmentId);
    assignment.isUploaded = 1;
    await DBHelper.update(
        tableName: Global.assignmentTable,
        row: assignment.toMap(),
        where: 'id = ?',
        whereArgs: [assignment.id]);
    notifyListeners();
  }

  //gets the assignments by outlet_id
  List<Assignment> getByOutletId(int outlet_id) {
    return _assignments
        .where((assignment) => assignment.outletId == outlet_id)
        .toList();
  }

  //Gets all the assignments with the same code (Same product)
  List<Assignment> assignmentsWithCode(String code) {
    return _assignments
        .where((assignment) =>
            UtilityFunctions.getParsedCode(assignment.code) ==
            UtilityFunctions.getParsedCode(code))
        .toList();
  }

  //Gets all the assignments with the same code (Same product)
  Assignment? getAssignmentByOutletAndVarietyId(int outletId, int varietyId) {
    return _assignments.firstWhereOrNull((element) =>
        element.varietyId == varietyId && element.outletId == outletId);
  }

  Future<void> reportSyncToApi() async {
    try {
      //upload the assignments
      await Global.dio.get('/syncing',
          options: Options(headers: {
            'Authorization': 'Bearer ${UserAuth().user()?.token}'
          }));
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
}
