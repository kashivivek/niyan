import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/community_post_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/community_service.dart';
import 'package:go_router/go_router.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final appMode = Provider.of<AppModeProvider>(context);
    final communityService = CommunityService();

    if (user == null || appMode.activeSociety == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAdmin = user.currentRole == AppRole.societyAdmin || user.currentRole == AppRole.superAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: () => _showCreatePostDialog(context, user, appMode.activeSociety!.id),
          backgroundColor: ThemeProvider.accentTeal,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<CommunityPost>>(
        stream: communityService.getPosts(appMode.activeSociety!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data ?? [];
          
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Start the conversation!', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _CommunityPostCard(post: post, isAdmin: isAdmin);
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreatePostDialog(BuildContext context, UserModel user, String societyId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Community Post', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
              const SizedBox(height: 16),
              TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  hintText: "What's happening in your society?",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_captionController.text.trim().isEmpty) return;
                    await CommunityService().createPost(CommunityPost(
                      id: '',
                      societyId: societyId,
                      authorId: user.uid,
                      authorName: user.name ?? 'Resident',
                      authorAvatar: user.photoUrl,
                      caption: _captionController.text.trim(),
                      createdAt: DateTime.now(),
                    ));
                    _captionController.clear();
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: ThemeProvider.primaryNavy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('POST TO COMMUNITY'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final bool isAdmin;
  const _CommunityPostCard({required this.post, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final communityService = CommunityService();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: ThemeProvider.accentTeal.withOpacity(0.1),
                  child: Text(post.authorName[0], style: const TextStyle(color: ThemeProvider.accentTeal, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
                      Text(DateFormat('MMM d, HH:mm').format(post.createdAt), style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
                if (isAdmin || post.authorId == user?.uid)
                  IconButton(
                    icon: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade400),
                    onPressed: () => _showOptions(context, communityService),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(post.caption, style: GoogleFonts.inter(fontSize: 14, color: ThemeProvider.primaryNavy, height: 1.5)),
          ),
          const SizedBox(height: 16),
          if (post.imageUrl != null)
             ClipRRect(
               borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0)),
               child: Image.network(post.imageUrl!, width: double.infinity, fit: BoxFit.cover),
             ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Row(
              children: [
                _ActionButton(
                  icon: post.likes.contains(user?.uid) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: '${post.likes.length}',
                  color: post.likes.contains(user?.uid) ? Colors.red : Colors.grey.shade600,
                  onTap: () => communityService.toggleLike(post.id, user?.uid ?? ''),
                ),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.commentCount}',
                  color: Colors.grey.shade600,
                  onTap: () => context.push('/community/post/${post.id}'),
                ),
                const Spacer(),
                _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: Colors.grey.shade600,
                  onTap: () {
                    // In a real app, use share_plus
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unique link copied to clipboard!')));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, CommunityService service) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: Colors.red),
            title: const Text('Delete Post'),
            onTap: () async {
              await service.deletePost(post.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
