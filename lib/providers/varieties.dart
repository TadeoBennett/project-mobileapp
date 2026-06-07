import 'package:cpi_app/helpers/auth.dart';
import 'package:cpi_app/helpers/db.dart';
import 'package:cpi_app/helpers/utility_functions.dart';
import 'package:cpi_app/models/assignment.dart';
import 'package:cpi_app/models/globals.dart';
import 'package:cpi_app/models/http_exception.dart';
import 'package:cpi_app/models/substitute.dart';
import 'package:cpi_app/models/variety.dart';
import 'package:cpi_app/models/variety.dart';
import 'package:cpi_app/providers/assignments.dart';
import 'package:cpi_app/providers/substitutions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:collection/collection.dart';

final varietiesProvider = ChangeNotifierProvider<Varieties>((ref) {
  return Varieties(ref.read);
});

class Varieties with ChangeNotifier {
  Varieties(this.read);
  final Reader read;

  List<Variety> _varieties = [];

  //Downloads all the varieties from the server and replaces current data with the new data
  Future<void> hardDownload() async {
    try {
      final response = await Global.dio.get(
          '${Global.apiBaseUrl}/varieties/user-varieties/${UserAuth().user()?.id}',
          options: Options(headers: {
            'Authorization': 'Bearer ${UserAuth().user()?.token}'
          }));

      final List<Variety> extractedVarieties = [];

      //Clear the current variety from the database
      await DBHelper.clearTable(Global.varietyTable);

      for (final item in response.data) {
        print(item);

        Variety variety = Variety(
          varietyId: item['id'],
          name: item['name'],
          code: item['code'],
          isNew: 0,
        );

        extractedVarieties.add(variety);
      }

      print("STARTED------------------------------------");

      await DBHelper.bulkInsert(Global.varietyTable, extractedVarieties);

      print("FINISHED------------------------------------");

      _varieties = extractedVarieties;
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

//Downloads all the varieties from the server and replaces current data with the new data
  Future<void> downloadVarieties() async {
    print(UserAuth().user()?.token);

    try {
      final response = await Global.dio.get(
          '${Global.apiBaseUrl}/varieties/user-varieties/${UserAuth().user()?.id}',
          options: Options(headers: {
            'Authorization': 'Bearer ${UserAuth().user()?.token}'
          }));

      final List<Variety> extractedVarieties = [];

      //Clear the current variety from the database
      await DBHelper.clearTable(Global.varietyTable);

      for (final item in response.data) {
        Variety variety = Variety(
          varietyId: item['id'],
          name: item['name'],
          code: item['code'],
          isNew: 0,
        );

        extractedVarieties.add(variety);
      }

      print("STARTED------------------------------------");

      await DBHelper.bulkInsert(Global.varietyTable, extractedVarieties);

      print("FINISHED------------------------------------");

      _varieties = extractedVarieties;
      notifyListeners();
    } on DioError catch (error) {
      print(error);

      //used to handle Authenticated errors!
      if (error.response?.statusCode == 401) {
        throw HttpException('Not Authenticated!', 401);
      }

      //used to handle http errors
      if (error.response?.statusCode == 403) {
        throw HttpException('Not Authenticated!', 403);
      }

      //used to handle http errors
      throw HttpException('Server is down try again later!', 500);
    } catch (error) {
      print(error);
      //Used to handle any errors!
      throw HttpException('Something Went wrong Contact Admin!', 600);
    }
  }

  //Clears all Varieties
  Future<void> clearVarieties() async {
    try {
      //Clears the current data of Varieties Table
      await DBHelper.clearTable(Global.substitutionTable);

      //Sets the current substitution to memory
      _varieties = [];
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  //get the current varieties from the local database
  Future<void> initialize() async {
    //Get the current variety
    final dbVarieties = await DBHelper.getData(Global.varietyTable);

    //transforms the current variety
    final localVarieties = dbVarieties.map((variety) {
      Variety varietyObj = Variety(
        varietyId: variety["varietyId"],
        name: variety["name"],
        code: variety["code"],
        isNew: variety["isNew"],
      );

      varietyObj.brand = variety["brand"];
      varietyObj.quantity = variety["quantity"];
      varietyObj.unit = variety["unit"];
      varietyObj.countryOfOrigin = variety["countryOfOrigin"];
      varietyObj.additionalSpecs = variety["additionalSpecs"];

      return varietyObj;
    }).toList();

    //replaces the existing variety
    _varieties = localVarieties;
    notifyListeners();
  }

  //get the current varieties from memory
  List<Variety> get varieties {
    return [..._varieties];
  }

  //Used to get variety for substitution since variety can be one
  //that does not exist for other assignment within the same outlet
  List<Variety> getVarietiesWithSameCode(Assignment assignment) {
    // Get all the varieties with same code (SAME PRODUCT)
    List<Variety> sameCodeVarieties = _varieties.where((variety) {
      return UtilityFunctions.getParsedCode(variety.code) ==
              UtilityFunctions.getParsedCode(assignment.code) &&
          (variety.code != assignment.code);
    }).toList();

    //Get all assignments with same product (SAME PRODUCT)
    List<Assignment> assignments =
        read(assignmentsProvider).assignmentsWithCode(assignment.code);

    //used to store the options
    List<Variety> varietyOptions = [];

    for (final variety in sameCodeVarieties) {
      //check if the variety exist for an assignment within same outlet of the assignment being substituted
      Assignment? temp_assignment = assignments.firstWhereOrNull((element) =>
          element.varietyId == variety.varietyId &&
          element.outletId == assignment.outletId);

      // if assignment is not found for variety then the variety can be an option
      if (temp_assignment == null) {
        varietyOptions.add(variety);
      }
    }

    return varietyOptions;
  }

  //Function used to add a new variety to the database and memory
  Future<Variety> createVariety(
      varietyId,
      name,
      newVarietyBrand,
      newVarietyUnit,
      newVarietyMeasurement,
      newVarietyCountry,
      newVarietySpecification,
      code) async {
    //insert to database  to get variety id
    int newVarietyId = await DBHelper.insert(Global.varietyTable, {
      "varietyId": null,
      "name": name,
      "code": code,
      "brand": newVarietyBrand,
      "quantity": newVarietyMeasurement,
      "unit": newVarietyUnit,
      "countryOfOrigin": newVarietyCountry,
      "additionalSpecs": newVarietySpecification,
      "isNew": 1
    });

    //create new variety
    Variety newVariety = Variety(
      varietyId: newVarietyId,
      name: name,
      code: code,
      isNew: 1,
    );

    newVariety.brand = newVarietyBrand;
    newVariety.quantity = newVarietyMeasurement;
    newVariety.unit = newVarietyUnit;
    newVariety.countryOfOrigin = newVarietyCountry;
    newVariety.additionalSpecs = newVarietySpecification;

    //add to memory and state
    _varieties.add(newVariety);
    notifyListeners();
    return newVariety;
  }

  //Function used to update a variety in the database and memory
  Future<Variety> updateVariety(
    varietyId,
    name,
    newVarietyBrand,
    newVarietyUnit,
    newVarietyMeasurement,
    newVarietyCountry,
    newVarietySpecification,
  ) async {
    Variety variety = _varieties.firstWhere((variety) {
      return variety.varietyId == varietyId;
    });
    variety.name = name;
    variety.brand = newVarietyBrand;
    variety.unit = newVarietyUnit;
    variety.quantity = newVarietyMeasurement;
    variety.countryOfOrigin = newVarietyCountry;
    variety.additionalSpecs = newVarietySpecification;
    DBHelper.update(
        tableName: Global.varietyTable,
        row: variety.toMap(),
        where: 'varietyId = ?',
        whereArgs: [variety.varietyId]);
    notifyListeners();
    return variety;
  }

  Variety getVarietyById(int id) {
    // try{
    return _varieties.firstWhere((variety) => variety.varietyId == id);
    // } catch (e) {
    //   return null;
    // }
  }

  Future<void> uploadVarieties() async {
    try {
      //get the varieties that are new
      List<Substitute> substitutions =
          read(substitutionsProvider).getSubstitutionsForUpload();

      //get the varieties that are not new and are related to a substitution
      List<Variety> newVarieties = [];

      for (final substitution in substitutions) {
        Variety variety = getVarietyById(substitution.newVarietyId);
        //check if the variety is new
        if (variety.isNew == 1) {
          newVarieties.add(variety);
        }
      }

      //remove duplicates if any
      newVarieties = newVarieties.toSet().toList();

      //prevent unnecessary uploads
      if (newVarieties.isEmpty) {
        return;
      }

      //Map the varieties to a list of maps to be uploaded
      List<Map<String, dynamic>> varietyMaps = newVarieties.map((variety) {
        return variety.mapForApi();
      }).toList();

      //make a new request to the server
      final response = await Global.dio.post('/varieties',
          data: varietyMaps,
          options: Options(headers: {
            'Authorization': 'Bearer ${UserAuth().user()?.token}'
          }));

      //loop through the response and update the local database and memory list
      for (final item in response.data) {
        //get the old outlet id
        int oldVarietyId = item['mobile_id'];

        Variety variety = getVarietyById(oldVarietyId);
        variety.varietyId =
            item['id']; // set the new variety id returned by server
        variety.isNew = 0;

        await DBHelper.update(
            tableName: Global.varietyTable,
            row: variety.toMap(),
            where: 'varietyId = ?',
            whereArgs: [oldVarietyId]);

        //Update the Substitutions that point to the old outlet id if any
        read(substitutionsProvider)
            .updateNewVarietyId(oldVarietyId, variety.varietyId);
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
}
