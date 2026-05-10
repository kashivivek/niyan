import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/announcement_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/community_service.dart';

class NoticeBoardScreen extends StatelessWidget {
  const NoticeBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final appMode = Provider.of<AppModeProvider>(context);
    final communityService = Provider.of<CommunityService>(context, listen: false);

    if (user == null || appMode.activeSociety == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAdmin = user.currentRole == AppRole.societyAdmin || user.currentRole == AppRole.superAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Notice Board', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: isAdmin
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: FloatingActionButton.extended(
                onPressed: () {
                  _showPostNoticeDialog(context, user, appMode);
                },
                backgroundColor: ThemeProvider.accentBlue,
                icon: const Icon(Icons.campaign_rounded, color: Colors.white),
                label: Text('Post Notice', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            )
          : null,
      body: StreamBuilder<List<AnnouncementModel>>(
        stream: communityService.getAnnouncements(appMode.activeSociety!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final announcements = snapshot.data ?? [];
          
          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No active announcements', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return _AnnouncementCard(announcement: announcement);
            },
          );
        },
      ),
    );
  }

  Future<void> _showPostNoticeDialog(BuildContext context, UserModel user, AppModeProvider appMode) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    AnnouncementPriority priority = AnnouncementPriority.normal;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Post New Notice', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AnnouncementPriority>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                  items: AnnouncementPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.toString().split('.').last.toUpperCase()))).toList(),
                  onChanged: (v) => setDialogState(() => priority = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || contentController.text.isEmpty) return;
                
                final communityService = Provider.of<CommunityService>(context, listen: false);
                await communityService.createAnnouncement(AnnouncementModel(
                  id: '',
                  societyId: appMode.activeSociety!.id,
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  authorId: user.uid,
                  authorName: user.name ?? 'Admin',
                  priority: priority,
                  createdAt: DateTime.now(),
                ));
                
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: ThemeProvider.primaryNavy, foregroundColor: Colors.white),
              child: const Text('POST NOTICE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(announcement.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.campaign_rounded, color: priorityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy),
                    ),
                    Text(
                      'By ${announcement.authorName} • ${DateFormat('MMM d, HH:mm').format(announcement.createdAt)}',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              if (announcement.priority != AnnouncementPriority.normal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    announcement.priority.toString().split('.').last.toUpperCase(),
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            announcement.content,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
          ),
          if (announcement.attachmentUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attachment_rounded, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text('${announcement.attachmentUrls.length} Attachment(s)', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text('View', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: ThemeProvider.accentBlue)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor(AnnouncementPriority p) {
    switch (p) {
      case AnnouncementPriority.normal: return ThemeProvider.accentBlue;
      case AnnouncementPriority.high: return Colors.orange;
      case AnnouncementPriority.urgent: return Colors.red;
    }
  }
}
