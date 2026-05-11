import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/community_post_model.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/community_service.dart';

class CommunityPostDetailScreen extends StatefulWidget {
  final String postId;
  const CommunityPostDetailScreen({super.key, required this.postId});

  @override
  State<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final communityService = CommunityService();

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Post Discussion', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: ThemeProvider.primaryNavy,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<CommunityPost?>(
                  future: communityService.getPostById(widget.postId),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final post = postSnapshot.data;
                    if (post == null) return const Center(child: Text('Post not found'));

                    return ListView(
                      children: [
                        _buildPostContent(post, user, communityService),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        StreamBuilder<List<PostComment>>(
                          stream: communityService.getComments(widget.postId),
                          builder: (context, commentSnapshot) {
                            final comments = commentSnapshot.data ?? [];
                            if (comments.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded, color: Colors.grey.shade300, size: 48),
                                      const SizedBox(height: 12),
                                      Text('No comments yet.', style: GoogleFonts.inter(color: Colors.grey.shade400)),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                return _CommentItem(comment: comment);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 100),
                      ],
                    );
                  },
                ),
              ),
              _buildCommentInput(communityService, user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostContent(CommunityPost post, UserModel user, CommunityService service) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: ThemeProvider.primaryNavy.withOpacity(0.05),
                child: Text(post.authorName[0], style: const TextStyle(color: ThemeProvider.primaryNavy, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
                    Text(DateFormat('MMM d • HH:mm').format(post.createdAt), style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(post.caption, style: GoogleFonts.inter(fontSize: 15, color: ThemeProvider.primaryNavy, height: 1.5)),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(post.imageUrl!, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          Row(
            children: [
              _DetailActionButton(
                icon: post.likes.contains(user.uid) ? Icons.thumb_up_alt_rounded : Icons.thumb_up_off_alt_rounded,
                label: '${post.likes.length} Likes',
                color: post.likes.contains(user.uid) ? ThemeProvider.accentTeal : Colors.grey.shade600,
                onTap: () => service.toggleLike(post.id, user.uid),
              ),
              const Spacer(),
              _DetailActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                color: Colors.grey.shade600,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(CommunityService service, UserModel user) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: ThemeProvider.primaryNavy,
            child: IconButton(
              onPressed: () async {
                if (_commentController.text.trim().isEmpty) return;
                await service.addComment(PostComment(
                  id: '',
                  postId: widget.postId,
                  authorId: user.uid,
                  authorName: user.name ?? 'Resident',
                  text: _commentController.text.trim(),
                  createdAt: DateTime.now(),
                ));
                _commentController.clear();
                FocusScope.of(context).unfocus();
              },
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final PostComment comment;
  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: ThemeProvider.primaryNavy.withOpacity(0.05),
            child: Text(comment.authorName[0], style: const TextStyle(fontSize: 10, color: ThemeProvider.primaryNavy, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(comment.authorName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: ThemeProvider.primaryNavy)),
                      Text(DateFormat('MMM d').format(comment.createdAt), style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.text, style: GoogleFonts.inter(fontSize: 14, color: ThemeProvider.primaryNavy, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _DetailActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
