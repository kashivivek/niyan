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
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Post Discussion')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<PostComment>>(
              stream: communityService.getComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Text('No comments yet. Be the first!', style: GoogleFonts.inter(color: Colors.grey.shade400)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: ThemeProvider.accentTeal.withOpacity(0.1),
                            child: Text(comment.authorName[0], style: const TextStyle(fontSize: 12, color: ThemeProvider.accentTeal)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(comment.authorName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: ThemeProvider.primaryNavy)),
                                    const SizedBox(width: 8),
                                    Text(DateFormat('MMM d').format(comment.createdAt), style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment.text, style: GoogleFonts.inter(fontSize: 14, color: ThemeProvider.primaryNavy)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildCommentInput(communityService, user),
        ],
      ),
    );
  }

  Widget _buildCommentInput(CommunityService service, UserModel user) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
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
            },
            icon: const Icon(Icons.send_rounded, color: ThemeProvider.accentTeal),
          ),
        ],
      ),
    );
  }
}
