import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io'; // Import nécessaire

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'notes.db');
    print('Chemin de la base de données: $path'); // Ajout de ce log
    return await openDatabase(path, version: 2, onUpgrade: _onUpgrade, onCreate: _onCreate);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN created_at INTEGER');
      await db.execute('ALTER TABLE notes ADD COLUMN updated_at INTEGER');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');
  }

  Future<int> insertNote(Map<String, dynamic> note) async {
    Database db = await instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    note['created_at'] = now;
    print('Creer : ${note['created_at']}');
    note['updated_at'] = now;
    print(note);
    return await db.insert('notes', note);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    Database db = await instance.database;
    return await db.query('notes');
  }

  Future<int> updateNote(Map<String, dynamic> note) async {
    Database db = await instance.database;
    note['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    print("Note mis a jour : ${note['id']} ${note['created_at']}");
    return await db.update(
      'notes',
      note,
      where: 'id = ?',
      whereArgs: [note['id']],
    );
  }

  // Dans database_helper.dart

  Future<List<Map<String, dynamic>>> getNoteById(int id) async {
    Database db = await instance.database;
    return await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }



  Future<int> deleteNote(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Nouvelle fonction pour supprimer la base de données
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'notes.db'); // Utiliser getDatabasesPath() ici
    print('Chemin de la base de données à supprimer : $path'); // Ajout de ce log
    File databaseFile = File(path);
    if (await databaseFile.exists()) {
      await databaseFile.delete();
      print('Base de données supprimée avec succès (via DatabaseHelper).');
    } else {
      print('La base de données n\'existe pas (via DatabaseHelper).');
    }
    // Après la suppression, il peut être judicieux de réinitialiser l'instance _database à null
    // pour forcer une nouvelle initialisation lors du prochain accès.
    _database = null;
  }
}