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

    final db = await openDatabase(
      path,
      version: 12, // Versão 12: Suporte a tarefas no calendário
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    // Chama a semente de dados após inicializar
    await _seedDatabase(db);

    return db;
  }

  Future<void> _seedDatabase(Database db) async {
    // Verifica se já existem rebanhos para não duplicar dados toda vez
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM herds'));
    if (count != null && count > 0) return;

    print("Seeding database with mock data...");

    // 1. Inserir Rebanhos
    int herdBovino = await db.insert('herds', {
      'name': 'Elite Nelore Gado',
      'category': 'Bovino',
      'management_type': 'Intensivo',
      'location': 'Galpão Principal',
      'animal_count': 6
    });

    int herdOvino = await db.insert('herds', {
      'name': 'Santa Inês Premium',
      'category': 'Ovino',
      'management_type': 'Semiextensivo',
      'location': 'Piquete 04',
      'animal_count': 5
    });

    int herdCaprino = await db.insert('herds', {
      'name': 'Leiteiras do Sertão',
      'category': 'Caprino',
      'management_type': 'Extensivo',
      'location': 'Caatinga Norte',
      'animal_count': 5
    });

    // 2. Inserir Animais (Bovinos)
    await db.insert('animals', {
      'herd_id': herdBovino,
      'identifier': 'VACA-01',
      'name': 'Mimosa',
      'age_months': 48,
      'weight': 450.5,
      'ecc': 3.5,
      'breed': 'Mestiço Sertanejo',
      'breed_name': 'Nelore x Guzerá',
      'sex': 'Fêmea',
      'reproductive_status': 'Prenhe',
      'parity': 'Multípara'
    });

    await db.insert('animals', {
      'herd_id': herdBovino,
      'identifier': 'VACA-02',
      'name': 'Estrela',
      'age_months': 36,
      'weight': 420.0,
      'ecc': 3.0,
      'breed': 'Nativa Pura',
      'breed_name': 'Nelore',
      'sex': 'Fêmea',
      'reproductive_status': 'Inseminada',
      'parity': 'Primípara'
    });

    await db.insert('animals', {
      'herd_id': herdBovino,
      'identifier': 'VACA-03',
      'name': 'Pretinha',
      'age_months': 54,
      'weight': 480.0,
      'ecc': 3.8,
      'breed': 'SRD (Comum)',
      'breed_name': 'Mestiça',
      'sex': 'Fêmea',
      'reproductive_status': 'Em Lactação',
      'parity': 'Multípara'
    });

    await db.insert('animals', {
      'herd_id': herdBovino,
      'identifier': 'NOVILHA-04',
      'name': 'Esperança',
      'age_months': 14,
      'weight': 280.0,
      'ecc': 3.2,
      'breed': 'Mestiço Exótico',
      'breed_name': 'Nelore x Angus',
      'sex': 'Fêmea',
      'reproductive_status': 'Vazia / Apta',
      'parity': 'Nulípara'
    });

    await db.insert('animals', {
      'herd_id': herdBovino,
      'identifier': 'TOURO-99',
      'name': 'Bruto',
      'age_months': 60,
      'weight': 850.0,
      'ecc': 4.0,
      'breed': 'Exótica Pura',
      'breed_name': 'Nelore PO',
      'sex': 'Macho',
      'aptitude': 'Alta produção',
      'semen_fertility': 0.85
    });

    await db.insert('animals', {
      'herd_id': herdBovino,
      'identifier': 'BEZERRO-05',
      'name': 'Trovão',
      'age_months': 4,
      'weight': 120.0,
      'ecc': 3.5,
      'breed': 'Mestiço Sertanejo',
      'breed_name': 'Nelore',
      'sex': 'Macho',
      'aptitude': 'Alta produção',
      'semen_fertility': 0.0
    });

    // 3. Inserir Animais (Ovinos)
    await db.insert('animals', {
      'herd_id': herdOvino,
      'identifier': 'OV-10',
      'name': 'Branquinha',
      'age_months': 24,
      'weight': 45.0,
      'ecc': 3.2,
      'breed': 'Mestiço Exótico',
      'breed_name': 'Santa Inês',
      'sex': 'Fêmea',
      'reproductive_status': 'Vazia / Apta',
      'parity': 'Nulípara'
    });

    await db.insert('animals', {
      'herd_id': herdOvino,
      'identifier': 'OV-11',
      'name': 'Bolinha',
      'age_months': 36,
      'weight': 52.0,
      'ecc': 3.5,
      'breed': 'Nativa Pura',
      'breed_name': 'Morada Nova',
      'sex': 'Fêmea',
      'reproductive_status': 'Prenhe',
      'parity': 'Multípara'
    });

    await db.insert('animals', {
      'herd_id': herdOvino,
      'identifier': 'OV-12',
      'name': 'Mel',
      'age_months': 12,
      'weight': 38.0,
      'ecc': 3.0,
      'breed': 'SRD (Comum)',
      'breed_name': 'Mestiça',
      'sex': 'Fêmea',
      'reproductive_status': 'Inseminada',
      'parity': 'Nulípara'
    });

    await db.insert('animals', {
      'herd_id': herdOvino,
      'identifier': 'MACHO-05',
      'name': 'Pé de Chumbo',
      'age_months': 30,
      'weight': 65.0,
      'ecc': 3.8,
      'breed': 'Nativa Pura',
      'breed_name': 'Morada Nova',
      'sex': 'Macho',
      'aptitude': 'Rústico',
      'semen_fertility': 0.90
    });

    await db.insert('animals', {
      'herd_id': herdOvino,
      'identifier': 'BORREGO-06',
      'name': 'Pequeno',
      'age_months': 2,
      'weight': 12.0,
      'ecc': 3.4,
      'breed': 'Mestiço Exótico',
      'breed_name': 'Santa Inês',
      'sex': 'Macho',
      'aptitude': 'Alta produção',
      'semen_fertility': 0.0
    });

    // 4. Inserir Animais (Caprinos)
    await db.insert('animals', {
      'herd_id': herdCaprino,
      'identifier': 'CAB-01',
      'name': 'Leitosa',
      'age_months': 40,
      'weight': 38.5,
      'ecc': 3.0,
      'breed': 'Exótica Pura',
      'breed_name': 'Saanen',
      'sex': 'Fêmea',
      'reproductive_status': 'Em Lactação',
      'parity': 'Multípara'
    });

    await db.insert('animals', {
      'herd_id': herdCaprino,
      'identifier': 'CAB-02',
      'name': 'Sertaneja',
      'age_months': 20,
      'weight': 32.0,
      'ecc': 2.8,
      'breed': 'Nativa Pura',
      'breed_name': 'Moxotó',
      'sex': 'Fêmea',
      'reproductive_status': 'Vazia / Apta',
      'parity': 'Nulípara'
    });

    await db.insert('animals', {
      'herd_id': herdCaprino,
      'identifier': 'CAB-03',
      'name': 'Flor',
      'age_months': 28,
      'weight': 35.0,
      'ecc': 3.1,
      'breed': 'Mestiço Sertanejo',
      'breed_name': 'Anglo Nubiana x Local',
      'sex': 'Fêmea',
      'reproductive_status': 'Inseminada',
      'parity': 'Primípara'
    });

    await db.insert('animals', {
      'herd_id': herdCaprino,
      'identifier': 'BODE-90',
      'name': 'Barba',
      'age_months': 45,
      'weight': 70.0,
      'ecc': 3.9,
      'breed': 'Nativa Pura',
      'breed_name': 'Repartida',
      'sex': 'Macho',
      'aptitude': 'Rústico',
      'semen_fertility': 0.88
    });

    await db.insert('animals', {
      'herd_id': herdCaprino,
      'identifier': 'CABRITO-04',
      'name': 'Saltitante',
      'age_months': 3,
      'weight': 10.5,
      'ecc': 3.3,
      'breed': 'Exótica Pura',
      'breed_name': 'Saanen',
      'sex': 'Macho',
      'aptitude': 'Alta produção',
      'semen_fertility': 0.0
    });

    print("Seed complete!");
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
    if (oldVersion < 8) {
      try { await db.execute('ALTER TABLE herds ADD COLUMN location TEXT'); } catch(e){}
    }
    if (oldVersion < 9) {
      try { await db.execute('ALTER TABLE animals ADD COLUMN pdf_path TEXT'); } catch(e){}
    }
    if (oldVersion < 10) {
      try { await db.execute('ALTER TABLE animal_events ADD COLUMN value_1 REAL'); } catch(e){}
      try { await db.execute('ALTER TABLE animal_events ADD COLUMN value_2 REAL'); } catch(e){}
    }
    if (oldVersion < 11) {
      try { await db.execute('ALTER TABLE animal_events ADD COLUMN text_value_1 TEXT'); } catch(e){}
      try { await db.execute('ALTER TABLE animal_events ADD COLUMN text_value_2 TEXT'); } catch(e){}
    }
    if (oldVersion < 12) {
      try { await db.execute('ALTER TABLE animal_events ADD COLUMN is_task INTEGER DEFAULT 0'); } catch(e){}
      try { await db.execute('ALTER TABLE animal_events ADD COLUMN is_all_day INTEGER DEFAULT 0'); } catch(e){}
      try { await db.execute('ALTER TABLE animal_events ADD COLUMN color_hex TEXT'); } catch(e){}
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
        location TEXT,
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
        pdf_path TEXT,
        FOREIGN KEY (herd_id) REFERENCES herds (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS animal_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        value_1 REAL,
        value_2 REAL,
        text_value_1 TEXT,
        text_value_2 TEXT,
        is_task INTEGER DEFAULT 0,
        is_all_day INTEGER DEFAULT 0,
        color_hex TEXT,
        FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertHerd(String name, String category, {String management = 'Extensivo', String? location}) async {
    final db = await instance.database;
    return await db.insert('herds', {
      'name': name, 
      'category': category,
      'management_type': management,
      'location': location
    });
  }

  Future<List<Map<String, dynamic>>> getHerdsByCategory(String category) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT h.*, 
          (SELECT COUNT(*) FROM animals a WHERE a.herd_id = h.id) as total_animals,
          (SELECT COUNT(*) FROM animals a WHERE a.herd_id = h.id AND a.sex = 'Fêmea') as total_females,
          (SELECT COUNT(*) FROM animals a WHERE a.herd_id = h.id AND a.sex = 'Fêmea' AND a.reproductive_status = 'Prenhe') as pregnant_females,
          (SELECT AVG(a.ecc) FROM animals a WHERE a.herd_id = h.id) as avg_ecc
        FROM herds h
        WHERE h.category = ?
      ''', [category]);
      return result;
    } catch (e) {
      print("Database Error: $e");
      return [];
    }
  }

  Future<bool> herdNameExists(String name) async {
    try {
      final db = await instance.database;
      final result = await db.query('herds', where: 'name = ?', whereArgs: [name]);
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPotentialParents(String sex, String category, {int? excludeId}) async {
    try {
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
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getUniqueLineages() async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT DISTINCT lineage FROM animals WHERE lineage IS NOT NULL AND lineage != ""'
      );
      return result.map((row) => row['lineage'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> insertAnimal(Map<String, dynamic> animalData) async {
    try {
      final db = await instance.database;
      int id = await db.insert('animals', animalData);

      await db.execute('''
        UPDATE herds SET animal_count = (
          SELECT COUNT(*) FROM animals WHERE herd_id = ?
        ) WHERE id = ?
      ''', [animalData['herd_id'], animalData['herd_id']]);

      return id;
    } catch (e) {
      print("Error inserting animal: $e");
      return -1;
    }
  }

  Future<bool> animalIdentifierExists(int herdId, String identifier) async {
    final db = await instance.database;
    final result = await db.query('animals',
        where: 'herd_id = ? AND identifier = ?',
        whereArgs: [herdId, identifier]);
    return result.isNotEmpty;
  }

  Future<int> insertEvent(int animalId, String type, String description, {double? v1, double? v2, String? t1, String? t2, DateTime? manualDate}) async {
    final db = await instance.database;
    return await db.insert('animal_events', {
      'animal_id': animalId,
      'type': type,
      'date': (manualDate ?? DateTime.now()).toIso8601String(),
      'description': description,
      'value_1': v1,
      'value_2': v2,
      'text_value_1': t1,
      'text_value_2': t2,
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
