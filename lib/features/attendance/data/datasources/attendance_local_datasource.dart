import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../models/attendance_record_model.dart';

abstract class AttendanceLocalDataSource {
  Future<int> insertRecord(AttendanceRecordModel record);
  Future<List<AttendanceRecordModel>> getAttendanceHistory(String employeeId);
  Future<List<AttendanceRecordModel>> getUnsyncedRecords();
  Future<void> markAsSynced(int id);
}

class AttendanceLocalDataSourceImpl implements AttendanceLocalDataSource {
  final DatabaseHelper databaseHelper;

  AttendanceLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<int> insertRecord(AttendanceRecordModel record) async {
    try {
      final db = await databaseHelper.database;
      final id = await db.insert(
        DatabaseHelper.tableAttendance,
        record.toMap(),
      );
      return id;
    } catch (e) {
      throw CacheException('Failed to insert attendance record into SQLite: $e');
    }
  }

  @override
  Future<List<AttendanceRecordModel>> getAttendanceHistory(String employeeId) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        DatabaseHelper.tableAttendance,
        where: '${DatabaseHelper.columnEmployeeId} = ?',
        whereArgs: [employeeId],
        orderBy: '${DatabaseHelper.columnTimestamp} DESC',
      );
      return results.map((map) => AttendanceRecordModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheException('Failed to query attendance history from SQLite: $e');
    }
  }

  @override
  Future<List<AttendanceRecordModel>> getUnsyncedRecords() async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        DatabaseHelper.tableAttendance,
        where: '${DatabaseHelper.columnSynced} = ?',
        whereArgs: [0],
        orderBy: '${DatabaseHelper.columnTimestamp} ASC',
      );
      return results.map((map) => AttendanceRecordModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheException('Failed to query unsynced attendance records: $e');
    }
  }

  @override
  Future<void> markAsSynced(int id) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseHelper.tableAttendance,
        {DatabaseHelper.columnSynced: 1},
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException('Failed to mark record as synced in SQLite: $e');
    }
  }
}
