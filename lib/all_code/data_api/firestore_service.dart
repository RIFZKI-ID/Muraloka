import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muraloka/all_code/model/project.dart';
import 'package:muraloka/all_code/model/user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===LOGIC CRUD OPERATION FROM FIREBASE===

  Future<List<User>> fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs.map((doc) {
      return User.fromMap(doc.data(), doc.id);
    }).toList();
  }

  Stream<List<Project>> getProjectsByVisibility(String visibility) {
    return _firestore
        .collection('projects')
        .where('visibility', isEqualTo: visibility)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Project.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}
