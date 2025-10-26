import 'package:flutter/material.dart';
import 'package:muraloka/all_code/model/project.dart';
import 'package:muraloka/constant/constant.dart';

class DetailPage extends StatelessWidget {
  final Project project;

  const DetailPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    // Use ThemeManager from constant.dart
    final theme = ThemeManager.of(context);
    
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.primary,
        foregroundColor: theme.surface,
        title: Text(project.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owner: ${project.ownerId}', style: TextStyle(color: theme.textPrimary)),
            Text('Project ID: ${project.id}', style: TextStyle(color: theme.textPrimary)),
            Text('Public: ${project.isPublic ? "Yes" : "No"}', style: TextStyle(color: theme.textPrimary)),
            Text('Canvas: ${project.canvasWidth}x${project.canvasHeight}', style: TextStyle(color: theme.textPrimary)),
            Text('Created At: ${project.createdAt.toString()}', style: TextStyle(color: theme.textSecondary)),
            Text('Updated At: ${project.updatedAt.toString()}', style: TextStyle(color: theme.textSecondary)),
            const SizedBox(height: 10),
            Text('Collaborators (${project.collaboratorIds.length}):', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold)),
            for (var collaboratorId in project.collaboratorIds)
              Text('- $collaboratorId', style: TextStyle(color: theme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
