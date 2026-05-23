import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/database_helper.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> syncLocalToCloud() async {
    final user = _auth.currentUser;
    if (user == null) throw "Usuário não autenticado";

    final db = DatabaseHelper.instance;
    final String userPath = "users/${user.email}/herds";

    // 1. Busca todos os rebanhos locais
    final List<Map<String, dynamic>> localBovinos = await db.getHerdsByCategory('Bovino');
    final List<Map<String, dynamic>> localOvinos = await db.getHerdsByCategory('Ovino');
    final List<Map<String, dynamic>> localCaprinos = await db.getHerdsByCategory('Caprino');

    final List<Map<String, dynamic>> allHerds = [...localBovinos, ...localOvinos, ...localCaprinos];

    for (var herd in allHerds) {
      // Salva ou atualiza o rebanho no Firestore
      await _firestore.collection(userPath).doc(herd['id'].toString()).set({
        'name': herd['name'],
        'category': herd['category'],
        'animal_count': herd['animal_count'],
        'last_synced': FieldValue.serverTimestamp(),
      });

      // 2. Busca e sincroniza os animais deste rebanho
      final dbRaw = await db.database;
      final List<Map<String, dynamic>> animals = await dbRaw.query(
        'animals', 
        where: 'herd_id = ?', 
        whereArgs: [herd['id']]
      );

      for (var animal in animals) {
        await _firestore
            .collection(userPath)
            .doc(herd['id'].toString())
            .collection('animals')
            .doc(animal['id'].toString())
            .set({
              ...animal,
              'last_synced': FieldValue.serverTimestamp(),
            });
      }
    }
    print("Sincronização concluída com sucesso!");
  }
}
