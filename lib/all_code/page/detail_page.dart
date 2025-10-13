import 'package:flutter/material.dart';
import 'package:muraloka/all_code/model/project.dart';

class DetailPage extends StatelessWidget {
  final Project project;

  const DetailPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(project.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owner: ${project.ownerId}'),
            Text('Project ID: ${project.projectId}'),
            Text('Version: ${project.version}'),
            Text('Visibility: ${project.visibility}'),
            Text('Created At: ${project.createdAt.toString()}'),
            Text('Updated At: ${project.updatedAt.toString()}'),
            SizedBox(height: 10),
            Text('Collaborators:'),
            for (var collaborator in project.collaborators)
              Text('- $collaborator'),
            SizedBox(height: 10),
            Text('Active Editors:'),
            for (var editor in project.activeEditors)
              Text('- $editor'),
          ],
        ),
      ),
    );
  }
}
