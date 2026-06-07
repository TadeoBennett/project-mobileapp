import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static const _dbName = 'cpi_app.db';
  static const _dbVersion = 1;

  //Gets the database connection or creates a new database connection
  static Future<Database> database() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, _dbName);

    return await openDatabase(path,
        onCreate: DBHelper.createDatabase, version: _dbVersion);
  }

  //Deletes a record from a table in a database connection
  static Future<int> delete(String tableName,
      {required String where, required List<dynamic> whereArgs}) async {
    Database db = await DBHelper.database();
    return await db.delete(tableName, where: where, whereArgs: whereArgs);
  }

  //inserts data to a specific table
  static Future<int> insert(String tableName, Map<String, dynamic> data) async {
    Database db = await DBHelper.database();
    return await db.insert(tableName, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int?> findLastInsertId(String tableName) async {
    Database db = await DBHelper.database();
    List<Map<String, dynamic>> rows =
        await db.rawQuery('SELECT MAX(outletId) as lastRowId FROM $tableName');
    return rows.first['lastRowId'];
  }

  static Future<List<Map<String, dynamic>>> filterTable(
      {tableName, where, whereArgs}) async {
    Database db = await DBHelper.database();
    List<Map<String, dynamic>> rows =
        await db.query(tableName, where: where, whereArgs: whereArgs);
    return rows;
  }

  //inserts Multiple Rows to a specific table Faster than insert
  static Future<void> bulkInsert(String tableName, List<dynamic> rows) async {
    Database db = await DBHelper.database();
    Batch batch = db.batch();
    for (final row in rows) {
      batch.insert(tableName, row.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  //Gets all the data from a specific table
  static Future<List<Map<String, dynamic>>> getData(String tableName) async {
    Database db = await DBHelper.database();
    return await db.query(tableName);
  }

  //Clears data of a specific table
  static Future<void> clearTable(String tableName) async {
    Database db = await DBHelper.database();
    await db.delete(tableName);
  }

  static Future<void> update({tableName, row, where, whereArgs}) async {
    try {
      Database db = await DBHelper.database();
      await db.update(tableName, row, where: where, whereArgs: whereArgs);
    } catch (e) {
      print(e);
    }
  }

  //Creates the database tables
  static Future<void> createDatabase(Database db, int version) async {
    //Create Outlets table to store downloaded outlets
    db.execute('''
            CREATE TABLE outlet(
              outletId INTEGER PRIMARY KEY NOT NULL, 
              address TEXT, 
              estName TEXT,
              note TEXT,
              areaId INTEGER, 
              phone TEXT,
              lat REAL,
              long REAL,
              isUploaded INTEGER,
              isCompleted INTEGER,
              isEdited INTEGER,
              isNew INTEGER,
              failedAutoSync INTEGER,
              email TEXT NULL
            )
          ''');

    //Create Products table to store downloaded products
    db.execute('''
            CREATE TABLE assignment(
              id INTEGER PRIMARY KEY,
              outletProductVarietyId INTEGER,
              timePeriod TEXT,
              varietyName TEXT,
              varietyId INTEGER,
              lastCollected TEXT,
              previousPrice REAL,
              newPrice REAL,
              collectedAt TEXT,
              comment TEXT,
              code TEXT,
              outletName TEXT,
              outletId INTEGER,
              canSubstitute INTEGER,
              requestSubstitute INTEGER,
              isRequestUploaded INTEGER,
              isSubstituted INTEGER,
              isUploaded INTEGER,
              isRejected INTEGER,
              isApprovedByHQ INTEGER,
              failedAutoSync INTEGER,
              substitutionOutletName TEXT,
              substitutionVarietyName TEXT,
              collectorComment TEXT,
              collectorCollectedAt TEXT,
              lat REAL NULL,
              long REAL NULL
            )
          ''');

    //Create Varieties table to store downloaded products
    db.execute('''
            CREATE TABLE variety(
              varietyId INTEGER PRIMARY KEY,
              name TEXT,
              code TEXT,
              brand TEXT NULL,
              quantity REAL NULL,
              unit TEXT NULL,
              countryOfOrigin TEXT NULL,
              additionalSpecs TEXT NULL,
              isNew INTEGER
            )
          ''');

    //Create Substitutes table to store Assignments Substituted
    db.execute('''
            CREATE TABLE substitute(
              assignmentId INTEGER PRIMARY KEY,
              outletSourceId INTEGER,
              newOutletId INTEGER,
              newVarietyId INTEGER,
              price REAL,
              comment TEXT,
              collectedAt TEXT,
              isUploaded INTEGER,
              failedAutoSync INTEGER,
              lat REAL NULL,
              long REAL NULL
            )
          ''');

    //Create Syncs Table to store Sync History
    db.execute('''
              CREATE TABLE syncs(
                id INTEGER PRIMARY KEY,
                last_outlets_updated TEXT,
                last_products_updated TEXT,
                last_subs_updated TEXT,
                outlets_count INTEGER,
                products_count INTEGER,
                subs_count INTEGER
              )
          ''');
  }
}
