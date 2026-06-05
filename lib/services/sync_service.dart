import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Função principal que tenta sincronizar dados locais com a nuvem
  Future<void> syncLocalToCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) return;

    final db = await DatabaseHelper.instance.database;
    final userId = user.uid;

    // 1. Sincronizar REBANHOS
    final unsyncedHerds = await db.query('herds', where: 'synced = 0');
    for (var herd in unsyncedHerds) {
      try {
        Map<String, dynamic> cloudData = Map.from(herd);
        cloudData.remove('synced');
        final localId = cloudData.remove('id');

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('herds')
            .doc(localId.toString())
            .set(cloudData, SetOptions(merge: true));

        await db.update('herds', {'synced': 1}, where: 'id = ?', whereArgs: [localId]);
      } catch (e) {
        print("Erro ao sincronizar rebanho: $e");
      }
    }

    // 2. Sincronizar ANIMAIS
    final unsyncedAnimals = await db.query('animals', where: 'synced = 0');
    for (var animal in unsyncedAnimals) {
      try {
        Map<String, dynamic> cloudData = Map.from(animal);
        cloudData.remove('synced');
        final localId = cloudData['id']; // Pega o ID sem remover dos dados

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('animals')
            .doc(localId.toString())
            .set(cloudData, SetOptions(merge: true));

        await db.update('animals', {'synced': 1}, where: 'id = ?', whereArgs: [localId]);
      } catch (e) {
        print("Erro ao sincronizar animal: $e");
      }
    }

    // 3. Sincronizar EVENTOS/ATIVIDADES
    final unsyncedEvents = await db.query('animal_events', where: 'synced = 0');
    for (var event in unsyncedEvents) {
      try {
        Map<String, dynamic> cloudData = Map.from(event);
        cloudData.remove('synced');
        final localId = cloudData.remove('id');

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('events')
            .doc(localId.toString())
            .set(cloudData, SetOptions(merge: true));

        await db.update('animal_events', {'synced': 1}, where: 'id = ?', whereArgs: [localId]);
      } catch (e) {
        print("Erro ao sincronizar evento: $e");
      }
    }

    // 4. Sincronizar DELEÇÕES
    final deletedRecords = await db.query('deleted_records');
    for (var record in deletedRecords) {
      try {
        final table = record['table_name'].toString();
        final remoteId = record['remote_id'].toString();

        await _firestore
            .collection('users')
            .doc(userId)
            .collection(table)
            .doc(remoteId)
            .delete();

        await db.delete('deleted_records', where: 'id = ?', whereArgs: [record['id']]);
      } catch (e) {
        print("Erro ao sincronizar deleção: $e");
      }
    }
  }

  /// Função para baixar dados da nuvem (útil ao reinstalar o app)
  Future<void> syncCloudToLocal() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final db = await DatabaseHelper.instance.database;
    final userId = user.uid;
    final _storage = GetStorage();

    print("SYNC: Iniciando download de dados para o usuário $userId");

    try {
      // 0. Recuperar Perfil do Usuário
      final profileDoc = await _firestore.collection('users').doc(userId).get();
      if (profileDoc.exists && profileDoc.data() != null) {
        final profile = profileDoc.data()!;
        
        // Só considera concluído se houver campos básicos
        if (profile.containsKey('userName') || profile.containsKey('farmName')) {
          _storage.write('userName', profile['userName'] ?? "");
          _storage.write('userPhone', profile['userPhone'] ?? "");
          _storage.write('farmName', profile['farmName'] ?? "");
          _storage.write('location', profile['location'] ?? "");
          _storage.write('userPhotoPath', profile['userPhotoPath'] ?? "");
          _storage.write('onboardingCompleted', true);
          print("SYNC: Perfil restaurado e onboarding marcado como CONCLUÍDO.");
        }
      }

      // 1. Baixar Rebanhos
      final herdsSnapshot = await _firestore.collection('users').doc(userId).collection('herds').get();
      if (herdsSnapshot.docs.isNotEmpty) {
        _storage.write('onboardingCompleted', true); // Se tem animais, já passou pelo onboarding
      }
      for (var doc in herdsSnapshot.docs) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id); // RECUPERA O ID ORIGINAL
        data['synced'] = 1;
        await db.insert('herds', data, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 2. Baixar Animais
      final animalsSnapshot = await _firestore.collection('users').doc(userId).collection('animals').get();
      for (var doc in animalsSnapshot.docs) {
        final data = doc.data();
        // data['id'] = int.tryParse(doc.id); // REMOVIDO: O ID agora está dentro dos dados
        data['synced'] = 1;
        await db.insert('animals', data, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      // 3. Baixar Eventos
      final eventsSnapshot = await _firestore.collection('users').doc(userId).collection('events').get();
      for (var doc in eventsSnapshot.docs) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id); // RECUPERA O ID ORIGINAL
        data['synced'] = 1;
        await db.insert('animal_events', data, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      print("SYNC: Download concluído com sucesso.");
    } catch (e) {
      print("SYNC ERROR: Falha ao baixar dados: $e");
    }
  }

  /// Salva o perfil do usuário na nuvem
  Future<void> saveUserProfileToCloud({
    required String userName,
    required String userPhone,
    required String farmName,
    required String location,
    String? userPhotoPath,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'userName': userName,
        'userPhone': userPhone,
        'farmName': farmName,
        'location': location,
        'userPhotoPath': userPhotoPath ?? "",
        'onboardingTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Erro ao salvar perfil na nuvem: $e");
    }
  }
}
