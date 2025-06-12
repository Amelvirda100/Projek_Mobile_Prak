import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> get _db async {
    final path = join(await getDatabasesPath(), 'local_user.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE,
            password TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertUser(String email, String passwordHash) async {
    final db = await _db;
    await db.insert(
      'users',
      {'email': email, 'password': passwordHash},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<bool> verifyUser(String email, String passwordHash) async {
    final db = await _db;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, passwordHash],
    );
    return result.isNotEmpty;
  }
}
