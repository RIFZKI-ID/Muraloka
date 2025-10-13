import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  String? id;
  List<String> collaborators;
  DateTime createdAt;
  String ownerId;
  String projectId;
  String title;
  DateTime updatedAt;
  int version;
  String visibility;
  List<String> activeEditors;

  Project({
    this.id,
    required this.collaborators,
    required this.createdAt,
    required this.ownerId,
    required this.projectId,
    required this.title,
    required this.updatedAt,
    required this.version,
    required this.visibility,
    required this.activeEditors,
  });

  // Mengonversi data dari Firestore ke format model ini
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      collaborators: List<String>.from(map['collaborators'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      ownerId: map['ownerId'],
      projectId: map['projectId'],
      title: map['title'],
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      version: map['version'],
      visibility: map['visibility'],
      activeEditors: List<String>.from(map['active_editors'] ?? []),
    );
  }

  // Mengonversi model ini ke map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'collaborators': collaborators,
      'createdAt': createdAt,
      'ownerId': ownerId,
      'projectId': projectId,
      'title': title,
      'updatedAt': updatedAt,
      'version': version,
      'visibility': visibility,
      'active_editors': activeEditors,
    };
  }

  // Menambahkan metode copyWith untuk membuat salinan dengan beberapa properti yang diubah
  Project copyWith({
    String? id,
    List<String>? collaborators,
    DateTime? createdAt,
    String? ownerId,
    String? projectId,
    String? title,
    DateTime? updatedAt,
    int? version,
    String? visibility,
    List<String>? activeEditors,
  }) {
    return Project(
      id: id ?? this.id,
      collaborators: collaborators ?? this.collaborators,
      createdAt: createdAt ?? this.createdAt,
      ownerId: ownerId ?? this.ownerId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      visibility: visibility ?? this.visibility,
      activeEditors: activeEditors ?? this.activeEditors,
    );
  }
}
