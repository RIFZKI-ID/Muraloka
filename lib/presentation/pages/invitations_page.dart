import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../all_code/data_api/invitation_repository.dart';
import '../../all_code/data_api/project_repository.dart';
import '../../all_code/model/collaboration_invitation.dart';
import '../../di.dart';
import '../../all_code/page/layer_paint_page.dart';
import '../../constant/constant.dart';

class InvitationsPage extends StatefulWidget {
  const InvitationsPage({Key? key}) : super(key: key);

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  late final InvitationRepository _invitationRepo;
  late final ProjectRepository _projectRepo;
  String? _userEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeRepos();
  }

  Future<void> _initializeRepos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    _userEmail = user.email;
    _invitationRepo = locator<InvitationRepository>();
    _projectRepo = ProjectRepository(appId: user.uid);
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collaboration Invitations')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userEmail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collaboration Invitations')),
        body: const Center(
          child: Text('Please login to view invitations'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaboration Invitations'),
        backgroundColor: AppColors.primary1,
      ),
      body: StreamBuilder<List<CollaborationInvitation>>(
        stream: _invitationRepo.streamInvitationsForEmail(_userEmail!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final invitations = snapshot.data ?? [];

          if (invitations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 64, color: AppColors.mediumGrey),
                  SizedBox(height: 16),
                  Text(
                    'No pending invitations',
                    style: TextStyle(fontSize: 18, color: AppColors.mediumGrey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              return _buildInvitationCard(invitation);
            },
          );
        },
      ),
    );
  }

  Widget _buildInvitationCard(CollaborationInvitation invitation) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Name
            Text(
              invitation.projectName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Owner Info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.mediumGrey),
                const SizedBox(width: 4),
                Text(
                  'From: ${invitation.ownerName}',
                  style: const TextStyle(color: AppColors.mediumGrey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.mediumGrey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(invitation.createdAt),
                  style: const TextStyle(color: AppColors.mediumGrey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _rejectInvitation(invitation),
                  icon: const Icon(Icons.close, color: AppColors.error),
                  label: const Text(
                    'Reject',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _acceptInvitation(invitation),
                  icon: const Icon(Icons.check),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.lightSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _acceptInvitation(CollaborationInvitation invitation) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Accept invitation
      await _invitationRepo.acceptInvitation(invitation.id, user.uid);
      
      // Add user to project collaborators
      final project = await _projectRepo.getSharedProject(invitation.projectId);
      if (project != null) {
        final updatedCollaborators = [...project.collaboratorIds, user.uid];
        final updatedPendingInvitations = project.pendingInvitations
            .where((email) => email != user.email)
            .toList();
        
        await _projectRepo.updateSharedProject(
          invitation.projectId,
          {
            'collaboratorIds': updatedCollaborators,
            'pendingInvitations': updatedPendingInvitations,
          },
        );
      }

      // Hide loading
      if (mounted) Navigator.of(context).pop();

      // Show success and navigate to project
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Invitation accepted! Opening project...'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Navigate to paint page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LayerPaintPage(projectId: invitation.projectId),
          ),
        );
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error accepting invitation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectInvitation(CollaborationInvitation invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Invitation'),
        content: Text(
          'Are you sure you want to reject the invitation to "${invitation.projectName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.lightSurface,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Reject invitation
      await _invitationRepo.rejectInvitation(invitation.id);
      
      // Remove from pending invitations
      final project = await _projectRepo.getSharedProject(invitation.projectId);
      if (project != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final updatedPendingInvitations = project.pendingInvitations
              .where((email) => email != user.email)
              .toList();
          
          await _projectRepo.updateSharedProject(
            invitation.projectId,
            {'pendingInvitations': updatedPendingInvitations},
          );
        }
      }

      // Hide loading
      if (mounted) Navigator.of(context).pop();

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation rejected'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error rejecting invitation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
