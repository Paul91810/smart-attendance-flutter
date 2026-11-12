import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String databaseName = 'smart_attendance.db';
  static const int databaseVersion = 1;

  // Attendance table and columns
  static const String tableAttendance = 'attendance';
  static const String columnId = 'id';
  static const String columnEmployeeId = 'employeeId';
  static const String columnType = 'type';
  static const String columnTimestamp = 'timestamp';
  static const String columnLatitude = 'latitude';
  static const String columnLongitude = 'longitude';
  static const String columnSessionId = 'sessionId';
  static const String columnSynced = 'synced';

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, databaseName);

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableAttendance (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnEmployeeId TEXT NOT NULL,
        $columnType TEXT NOT NULL,
        $columnTimestamp TEXT NOT NULL,
        $columnLatitude REAL NOT NULL,
        $columnLongitude REAL NOT NULL,
        $columnSessionId TEXT NOT NULL,
        $columnSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
