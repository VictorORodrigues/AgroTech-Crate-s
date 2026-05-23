import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7, // Versão 7: Adicionando nome da raça específico
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS animals');
      await db.execute('DROP TABLE IF EXISTS herds');
      await db.execute('DROP TABLE IF EXISTS users'); 
      await _createDB(db, newVersion);
    }
    if (oldVersion < 5) {
       await db.execute('''
        CREATE TABLE IF NOT EXISTS animal_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          animal_id INTEGER NOT NULL,
          type TEXT NOT NULL,
          date TEXT NOT NULL,
          description TEXT,
          FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 6) {
      // Adicionando colunas de manejo e genética gradualmente para não perder dados se possível,
      // mas como é Hackathon, vou garantir que as colunas existam.
      try { await db.execute('ALTER TABLE herds ADD COLUMN management_type TEXT DEFAULT "Extensivo"'); } catch(e){}
      try { await db.execute('ALTER TABLE animals ADD COLUMN name TEXT'); } catch(e){}
      try { await db.execute('ALTER TABLE animals ADD COLUMN lineage TEXT'); } catch(e){}
      try { await db.execute('ALTER TABLE animals ADD COLUMN id_pai TEXT'); } catch(e){}
      try { await db.execute('ALTER TABLE animals ADD COLUMN id_mae TEXT'); } catch(e){}
      try { await db.execute('ALTER TABLE animals ADD COLUMN aptitude TEXT'); } catch(e){}
      try { await db.execute('ALTER TABLE animals ADD COLUMN semen_fertility REAL'); } catch(e){}
    }
    if (oldVersion < 7) {
      try { await db.execute('ALTER TABLE animals ADD COLUMN breed_name TEXT'); } catch(e){}
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS herds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        management_type TEXT DEFAULT 'Extensivo',
        animal_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS animals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        herd_id INTEGER NOT NULL,
        identifier TEXT NOT NULL,
        name TEXT,
        age_months INTEGER,
        weight REAL,
        ecc REAL,
        breed TEXT,
        breed_name TEXT,
        sex TEXT,
        lineage TEXT,
        id_pai TEXT,
        id_mae TEXT,
        aptitude TEXT,
        semen_fertility REAL,
        reproductive_status TEXT,
        parity TEXT,
        dpp_status TEXT,
        photo_path TEXT,
        FOREIGN KEY (herd_id) REFERENCES herds (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS animal_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertHerd(String name, String category, {String management = 'Extensivo'}) async {
    final db = await instance.database;
    return await db.insert('herds', {
      'name': name, 
      'category': category,
      'management_type': management
    });
  }

  Future<List<Map<String, dynamic>>> getHerdsByCategory(String category) async {
    final db = await instance.database;
    return await db.query('herds', where: 'category = ?', whereArgs: [category]);
  }

  Future<bool> herdNameExists(String name) async {
    final db = await instance.database;
    final result = await db.query('herds', where: 'name = ?', whereArgs: [name]);
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getPotentialParents(String sex, String category, {int? excludeId}) async {
    final db = await instance.database;
    String query = '''
      SELECT a.identifier, a.id, h.category 
      FROM animals a 
      INNER JOIN herds h ON a.herd_id = h.id 
      WHERE a.sex = ? AND h.category = ?
    ''';
    List<dynamic> args = [sex, category];
    
    if (excludeId != null) {
      query += ' AND a.id != ?';
      args.add(excludeId);
    }
    
    return await db.rawQuery(query, args);
  }

  Future<List<String>> getUniqueLineages() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT DISTINCT lineage FROM animals WHERE lineage IS NOT NULL AND lineage != ""'
    );
    return result.map((row) => row['lineage'] as String).toList();
  }

  Future<int> insertAnimal(Map<String, dynamic> animalData) async {
    final db = await instance.database;
    int id = await db.insert('animals', animalData);

    await db.execute('''
      UPDATE herds SET animal_count = (
        SELECT COUNT(*) FROM animals WHERE herd_id = ?
      ) WHERE id = ?
    ''', [animalData['herd_id'], animalData['herd_id']]);

    return id;
  }

  Future<bool> animalIdentifierExists(int herdId, String identifier) async {
    final db = await instance.database;
    final result = await db.query('animals',
        where: 'herd_id = ? AND identifier = ?',
        whereArgs: [herdId, identifier]);
    return result.isNotEmpty;
  }

  Future<int> insertEvent(int animalId, String type, String description) async {
    final db = await instance.database;
    return await db.insert('animal_events', {
      'animal_id': animalId,
      'type': type,
      'date': DateTime.now().toIso8601String(),
      'description': description,
    });
  }

  Future<List<Map<String, dynamic>>> getEventsByAnimal(int animalId) async {
    final db = await instance.database;
    return await db.query('animal_events',
        where: 'animal_id = ?',
        whereArgs: [animalId],
        orderBy: 'date DESC');
  }

  Future<int> registerUser(String email, String password) async {
    final db = await instance.database;
    return await db.insert('users', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty ? result.first : null;
  }
}
