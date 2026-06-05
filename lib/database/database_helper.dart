import 'dart:math';
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
      version: 19, // Versão 19: Adição de coluna de tipo em notificações
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _seedDatabase(Database db) async {
    // Sementeira desativada a pedido do usuário para iniciar com banco limpo
    return;
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 12) {
      await db.execute('DROP TABLE IF EXISTS animal_events');
      await db.execute('DROP TABLE IF EXISTS animals');
      await db.execute('DROP TABLE IF EXISTS herds');
      await db.execute('DROP TABLE IF EXISTS users'); 
      await _createDB(db, newVersion);
    }
    if (oldVersion < 13) {
      try { await db.execute('ALTER TABLE animal_events ADD COLUMN herd_id INTEGER'); } catch(e){}
    }
    if (oldVersion < 16) {
      await db.execute('DROP TABLE IF EXISTS animal_events');
      await db.execute('DROP TABLE IF EXISTS animals');
      await db.execute('DROP TABLE IF EXISTS herds');
      await db.execute('DROP TABLE IF EXISTS users'); 
      await _createDB(db, newVersion);
    }
    if (oldVersion < 17) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS deleted_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_name TEXT NOT NULL,
          remote_id TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 18) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER,
          title TEXT,
          message TEXT,
          date TEXT,
          is_read INTEGER DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 19) {
      try {
        await db.execute('ALTER TABLE app_notifications ADD COLUMN text_value_1 TEXT');
      } catch (e) {
        print("Erro ao adicionar coluna text_value_1 em app_notifications: $e");
      }
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
        animal_count INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 0
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
        birth_date TEXT,
        death_date TEXT,
        vital_status TEXT DEFAULT 'Ativo',
        created_at TEXT,
        initial_age_months INTEGER,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (herd_id) REFERENCES herds (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS animal_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER,
        herd_id INTEGER,
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
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE,
        FOREIGN KEY (herd_id) REFERENCES herds (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS deleted_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        remote_id TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER,
        title TEXT,
        message TEXT,
        date TEXT,
        is_read INTEGER DEFAULT 0,
        text_value_1 TEXT
      )
    ''');

    await _seedDatabase(db);
  }

  // --- MÉTODOS DE ACESSO ---

  Future<int> insertHerd(String name, String category, {String management = 'Extensivo', String? location}) async {
    final db = await database;
    int id = await db.insert('herds', {
      'name': name, 
      'category': category,
      'management_type': management,
      'location': location,
      'synced': 0
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> getHerdsByCategory(String category) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT h.*, 
        (SELECT COUNT(*) FROM animals a WHERE a.herd_id = h.id) as total_animals,
        (SELECT COUNT(*) FROM animals a WHERE a.herd_id = h.id AND a.sex = 'Fêmea') as total_females,
        (SELECT COUNT(*) FROM animals a WHERE a.herd_id = h.id AND a.sex = 'Fêmea' AND a.reproductive_status = 'Prenhe') as pregnant_females,
        (SELECT AVG(a.ecc) FROM animals a WHERE a.herd_id = h.id) as avg_ecc
      FROM herds h
      WHERE h.category = ?
    ''', [category]);
  }

  Future<bool> herdNameExists(String name) async {
    final db = await database;
    final result = await db.query('herds', where: 'name = ?', whereArgs: [name]);
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getPotentialParents(String sex, String category, {int? excludeId}) async {
    final db = await database;
    String query = '''
      SELECT a.identifier, a.id, h.category 
      FROM animals a 
      INNER JOIN herds h ON a.herd_id = h.id 
      WHERE a.sex = ? AND h.category = ? AND a.vital_status = 'Ativo'
    ''';
    List<dynamic> args = [sex, category];
    if (excludeId != null) {
      query += ' AND a.id != ?';
      args.add(excludeId);
    }
    return await db.rawQuery(query, args);
  }

  Future<List<String>> getUniqueLineages() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT DISTINCT lineage FROM animals WHERE lineage IS NOT NULL AND lineage != ""'
    );
    return result.map((row) => row['lineage'] as String).toList();
  }

  Future<int> insertAnimal(Map<String, dynamic> animalData) async {
    final db = await database;
    
    // Garante que todo animal tenha uma data de criação para controle de idade
    final dataWithCreation = Map<String, dynamic>.from(animalData);
    if (!dataWithCreation.containsKey('created_at') || dataWithCreation['created_at'] == null) {
      dataWithCreation['created_at'] = DateTime.now().toIso8601String();
    }
    dataWithCreation['synced'] = 0;

    int id = await db.insert('animals', dataWithCreation);
    await db.execute('''
      UPDATE herds SET animal_count = (SELECT COUNT(*) FROM animals WHERE herd_id = ?), synced = 0 WHERE id = ?
    ''', [animalData['herd_id'], animalData['herd_id']]);
    return id;
  }

  Future<bool> animalIdentifierExists(int herdId, String identifier) async {
    final db = await database;
    final result = await db.query('animals',
        where: 'herd_id = ? AND identifier = ?',
        whereArgs: [herdId, identifier]);
    return result.isNotEmpty;
  }

  Future<int> insertEvent(int? animalId, String type, String description, {double? v1, double? v2, String? t1, String? t2, DateTime? manualDate, int? herdId, int isTask = 0, String? color_hex}) async {
    final db = await database;
    return await db.insert('animal_events', {
      'animal_id': animalId,
      'herd_id': herdId,
      'type': type,
      'date': (manualDate ?? DateTime.now()).toIso8601String(),
      'description': description,
      'value_1': v1,
      'value_2': v2,
      'text_value_1': t1,
      'text_value_2': t2,
      'is_task': isTask,
      'color_hex': color_hex,
      'synced': 0
    });
  }

  Future<List<Map<String, dynamic>>> getEventsByAnimal(int animalId) async {
    final db = await database;
    return await db.query('animal_events',
        where: 'animal_id = ?',
        whereArgs: [animalId],
        orderBy: 'date DESC');
  }

  Future<int> registerUser(String email, String password) async {
    final db = await database;
    return await db.insert('users', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query('users', where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateAnimal(int id, Map<String, dynamic> data) async {
    final db = await database;
    final updatedData = Map<String, dynamic>.from(data);
    updatedData['synced'] = 0; // Força nova sincronização
    return await db.update('animals', updatedData, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAnimal(int id) async {
    final db = await database;
    await _trackDeletion('animals', id);
    await db.delete('animals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteHerd(int id) async {
    final db = await database;
    final animals = await db.query('animals', where: 'herd_id = ?', whereArgs: [id]);
    for (var a in animals) {
      await _trackDeletion('animals', a['id']);
    }
    await _trackDeletion('herds', id);
    await db.delete('herds', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _trackDeletion(String table, dynamic id) async {
    final db = await database;
    await db.insert('deleted_records', {
      'table_name': table,
      'remote_id': id.toString()
    });
  }

  // --- LÓGICA DE EXCLUSÃO TÉCNICA (CASCATA BIOLÓGICA) ---

  Future<void> deleteActivityChain(int eventId) async {
    final db = await database;

    // 1. Busca o evento que será excluído para entender o contexto
    final eventResult = await db.query('animal_events', where: 'id = ?', whereArgs: [eventId]);
    if (eventResult.isEmpty) return;

    final event = eventResult.first;
    final String type = event['type'].toString();
    final int? animalId = event['animal_id'] as int?;
    final String eventDate = event['date'].toString();

    // Lista de tipos que compõem a "árvore reprodutiva"
    const reproTypes = [
      "Inseminação Artificial",
      "Diagnóstico de Toque",
      "Nascimento",
      "Aborto / Perda Gestacional"
    ];

    const reversibleTypes = [
      ...reproTypes,
      "Pesagem e Escore",
      "Óbito",
      "Abate",
      "Venda de Animal"
    ];

    if (animalId != null && reversibleTypes.contains(type)) {
      // 2. Se for um evento da CADEIA REPRODUTIVA, exclui todos os eventos posteriores deste animal
      if (reproTypes.contains(type)) {
        // Antes de deletar, precisamos trackear para a nuvem
        final toDelete = await db.query('animal_events', 
          where: 'animal_id = ? AND type IN (?, ?, ?, ?) AND date > ?',
          whereArgs: [animalId, ...reproTypes, eventDate]);
        
        for (var row in toDelete) {
          await _trackDeletion('events', row['id']);
        }

        await db.delete(
          'animal_events',
          where: 'animal_id = ? AND type IN (?, ?, ?, ?) AND date > ?',
          whereArgs: [animalId, ...reproTypes, eventDate],
        );
      }
      
      // ... resto do código ...
    }

    // 4. Por fim, exclui o próprio evento
    await _trackDeletion('events', eventId);
    await db.delete('animal_events', where: 'id = ?', whereArgs: [eventId]);
  }

  Future<void> appendMassiveMockData() async {
    final db = await database;
    String now = DateTime.now().toIso8601String();

    // 1. Criar rebanhos robustos
    int hB1 = await insertHerd('Fazenda Sol Nascente - Gado', 'Bovino', management: 'Intensivo', location: 'Pasto de Engorda');
    int hB2 = await insertHerd('Lote Elite Nelore', 'Bovino', management: 'Semiextensivo', location: 'Piquete 04');
    int hO = await insertHerd('Rebanho Crateús - Ovinos', 'Ovino', management: 'Extensivo', location: 'Abrigo Leste');
    int hC = await insertHerd('Caprinos de Leite', 'Caprino', management: 'Intensivo', location: 'Galpão 01');

    // 2. Gerar Animais Diversos
    
    // BOVINOS (30 animais)
    for (int i = 1; i <= 30; i++) {
      await insertAnimal({
        'herd_id': i <= 15 ? hB1 : hB2,
        'identifier': 'BOV-${100 + i}',
        'name': i % 5 == 0 ? 'Matriz Soberana $i' : 'Bezerra $i',
        'age_months': 12 + (i * 2),
        'weight': 380.0 + (i * 5),
        'ecc': (i % 3) + 2.5,
        'breed': i < 15 ? 'Nativa Pura' : 'Mestiço Sertanejo',
        'breed_name': 'Nelore',
        'sex': i == 15 || i == 30 ? 'Macho' : 'Fêmea',
        'lineage': 'Linhagem Maranhão',
        'id_pai': 'Touro Thor',
        'id_mae': 'Matriz 0${i % 5}',
        'aptitude': 'Alta produção',
        'reproductive_status': i % 3 == 0 ? 'Prenhe' : 'Vazia / Apta',
        'parity': i < 10 ? 'Nulípara' : 'Multípara',
        'vital_status': 'Ativo',
        'created_at': now
      });
    }

    // OVINOS (20 animais)
    for (int i = 1; i <= 20; i++) {
      await insertAnimal({
        'herd_id': hO,
        'identifier': 'OVI-${500 + i}',
        'name': 'Ovelha Dorper $i',
        'age_months': 8 + i,
        'weight': 35.0 + i,
        'ecc': 3.5,
        'breed': 'Mestiço Exótico',
        'breed_name': 'Dorper',
        'sex': i == 1 ? 'Macho' : 'Fêmea',
        'aptitude': 'Rústica',
        'reproductive_status': i % 4 == 0 ? 'Prenhe' : 'Vazia / Apta',
        'parity': 'Primípara',
        'vital_status': 'Ativo',
        'created_at': now
      });
    }

    // CAPRINOS (20 animais)
    for (int i = 1; i <= 20; i++) {
      await insertAnimal({
        'herd_id': hC,
        'identifier': 'CAP-${800 + i}',
        'name': 'Cabra Saanen $i',
        'age_months': 15 + i,
        'weight': 30.0 + i,
        'ecc': 3.2,
        'breed': 'Exótica Pura',
        'breed_name': 'Saanen',
        'sex': i == 5 ? 'Macho' : 'Fêmea',
        'aptitude': 'Alta produção',
        'reproductive_status': 'Em Lactação',
        'parity': 'Multípara',
        'vital_status': 'Ativo',
        'created_at': now
      });
    }

    // 3. Gerar Atividades e Gastos
    final List<Map<String, dynamic>> animals = await db.query('animals');
    
    for (int j = 0; j < 50; j++) {
      final animal = animals[j % animals.length];
      String type = "Vacinação";
      double value = 150.0 + (j * 10);
      
      if (j % 5 == 0) type = "Inseminação Artificial";
      if (j % 8 == 0) type = "Medicamento";
      if (j % 10 == 0) type = "Suplementação";

      await db.insert('animal_events', {
        'animal_id': animal['id'],
        'herd_id': animal['herd_id'],
        'type': type,
        'date': DateTime.now().subtract(Duration(days: j)).toIso8601String(),
        'description': 'Manejo de rotina - Hackathon Demo',
        'value_1': value, // Valor gasto
        'text_value_1': 'Insumo Premium',
        'is_task': 0,
        'synced': 0
      });
    }

    // 4. Gerar Próximas Tarefas (Calendário)
    for (int k = 1; k <= 15; k++) {
       await db.insert('animal_events', {
        'type': k % 2 == 0 ? 'Diagnóstico de Toque' : 'Vacinação Febre Aftosa',
        'date': DateTime.now().add(Duration(days: k)).toIso8601String(),
        'description': 'Tarefa agendada pela IA para monitoramento preventivo.',
        'is_task': 1,
        'color_hex': k % 2 == 0 ? 'FF2196F3' : 'FFF44336',
        'synced': 0
      });
    }
  }
}
