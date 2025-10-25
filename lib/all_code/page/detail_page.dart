import 'package:flutter/material.dart';
import 'package:muraloka/all_code/model/project.dart';
import 'package:muraloka/constant/constant.dart';

class DetailPage extends StatelessWidget {
  final Project project;

  const DetailPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.of(context);
    return Scaffold(
      backgroundColor: theme.secondary1,
      appBar: AppBar(title: Text(project.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owner: ${project.ownerId}'),
            Text('Project ID: ${project.id}'),
            Text('Public: ${project.isPublic ? "Yes" : "No"}'),
            Text('Canvas: ${project.canvasWidth}x${project.canvasHeight}'),
            Text('Created At: ${project.createdAt.toString()}'),
            Text('Updated At: ${project.updatedAt.toString()}'),
            const SizedBox(height: 10),
            Text('Collaborators (${project.collaboratorIds.length}):'),
            for (var collaboratorId in project.collaboratorIds)
              Text('- $collaboratorId'),
          ],
        ),
      ),
    );
  }
}
