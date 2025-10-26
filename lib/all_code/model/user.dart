class User {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final List<String> collaborations;
  final List<String> myProjects;
  final List<String> purchasedItems;

  User({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.collaborations,
    required this.myProjects,
    required this.purchasedItems,
  });

  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      uid: map['uid'] ?? id,
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoURL'],
      collaborations: List<String>.from(map['collaborations'] ?? []),
      myProjects: List<String>.from(map['myProjects'] ?? []),
      purchasedItems: List<String>.from(map['purchasedItems'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoUrl,
      'collaborations': collaborations,
      'myProjects': myProjects,
      'purchasedItems': purchasedItems,
    };
  }
}
