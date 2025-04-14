import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io' show Platform;

import '../models/task.dart';

class DBHelper {
  static Database? _db;
  static const int _version = 1;
  static const String _tableName = 'tasks';

  static Future<void> initDb() async {
    if (_db != null) {
      debugPrint('db not null');
      return;
    }
    try {
      String path = '${await getDatabasesPath()}${Platform.pathSeparator}task.db';
      debugPrint('in db path: $path');
      _db = await openDatabase(path, version: _version,
          onCreate: (Database db, int version) async {
        debugPrint('Creating new database');
        // When creating the db, create the table
        return db.execute('CREATE TABLE $_tableName ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'title STRING, note TEXT, date STRING, '
            'startTime STRING, endTime STRING, '
            'remind INTEGER, repeat STRING, '
            'color INTEGER, '
            'isCompleted INTEGER)');
      });
      print('DB Created successfully');
    } catch (e) {
      print('Error initializing database: $e');
    }
  }

  // Helper method to ensure database is initialized
  static Future<Database> _getDatabase() async {
    if (_db == null) {
      print('Database was null, initializing now');
      await initDb();
      if (_db == null) {
        throw Exception('Failed to initialize database');
      }
    }
    return _db!;
  }

  static Future<int> insert(Task? task) async {
    print('Insert function called');
    try {
      if (task == null) {
        print('Task is null, cannot insert');
        return -1;
      }
      
      final db = await _getDatabase();
      final result = await db.insert(_tableName, task.toJson());
      print('Task inserted successfully with id: $result');
      return result;
    } catch (e) {
      print('Error inserting task: $e');
      return -1;
    }
  }

  static Future<int> delete(Task task) async {
    try {
      final db = await _getDatabase();
      return await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [task.id],
      );
    } catch (e) {
      print('Error deleting task: $e');
      return -1;
    }
  }

  static Future<int> deleteAll() async {
    try {
      final db = await _getDatabase();
      return await db.delete(_tableName);
    } catch (e) {
      print('Error deleting all tasks: $e');
      return -1;
    }
  }

  static Future<List<Map<String, dynamic>>> query() async {
    print('Query called');
    try {
      final db = await _getDatabase();
      final result = await db.query(_tableName);
      print('Query successful, found ${result.length} tasks');
      return result;
    } catch (e) {
      print('Error querying tasks: $e');
      return [];
    }
  }

  static Future<int> update(int id) async {
    try {
      final db = await _getDatabase();
      return await db.rawUpdate('''
      UPDATE tasks
      SET isCompleted = ?
      WHERE id = ?
      ''', [1, id]);
    } catch (e) {
      print('Error updating task completion status: $e');
      return -1;
    }
  }

  static Future<int> updateTask(Task task) async {
    try {
      final db = await _getDatabase();
      return await db.update(
        _tableName,
        task.toJson(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    } catch (e) {
      print('Error updating task: $e');
      return -1;
    }
  }
}
