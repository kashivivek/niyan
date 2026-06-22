import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/community_post_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/community_service.dart';
import 'package:myapp/models/member_model.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _captionController = TextEditingController();
  File? _selectedImage;
  bool _isPosting = false;
  Stream<List<CommunityPost>>? _postsStream;
  String? _lastSocietyId;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _initStream(String societyId) {
    if (_postsStream != null && _lastSocietyId == societyId) return;
    _postsStream = CommunityService().getPosts(societyId);
    _lastSocietyId = societyId;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final appMode = Provider.of<AppModeProvider>(context);

    if (user == null || appMode.activeSociety == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: ThemeProvider.accentTeal)));
    }

    _initStream(appMode.activeSociety!.id);

    final membership = appMode.activeMembership;
    // Resilient admin check: Fallback to global user role if membership is still loading
    final isAdmin = membership?.role.isAdmin ?? (user.currentRole == AppRole.societyAdmin || user.currentRole == AppRole.superAdmin);
    final isManager = membership?.role == SocietyRole.committee;
    final canManagePosts = isAdmin || isManager;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Lighter slate background
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: () => _showCreatePostDialog(context, user, membership, appMode.activeSociety!.id),
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? ThemeProvider.accentTeal : ThemeProvider.primaryNavy,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('Post', style: GoogleFonts.outfit(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold)),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text('Community Forum', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: ThemeProvider.primaryNavy,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: Colors.grey.shade100),
            ),
          ),
          StreamBuilder<List<CommunityPost>>(
            stream: _postsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              final posts = snapshot.data ?? [];
              
              if (posts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade200),
                        const SizedBox(height: 16),
                        Text('No posts yet in this society.', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        itemCount: posts.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return _CommunityPostCard(post: post, isAdmin: canManagePosts);
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showCreatePostDialog(BuildContext context, UserModel user, MemberModel? membership, String societyId) async {
    _captionController.clear();
    setState(() => _selectedImage = null);

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  AppBar(
                    title: Text('Create Post', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: CloseButton(onPressed: () => Navigator.pop(context)),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _isPosting 
                          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : TextButton(
                              onPressed: () async {
                                if (_captionController.text.trim().isEmpty) return;
                                
                                setModalState(() => _isPosting = true);
                                String? imageUrl;
                                if (_selectedImage != null) {
                                  imageUrl = await CommunityService().uploadPostImage(_selectedImage!);
                                }

                                await CommunityService().createPost(CommunityPost(
                                  id: '',
                                  societyId: societyId,
                                  authorId: user.uid,
                                  authorName: membership?.displayName ?? user.name ?? 'Resident',
                                  authorAvatar: user.photoUrl,
                                  caption: _captionController.text.trim(),
                                  imageUrl: imageUrl,
                                  createdAt: DateTime.now(),
                                ));

                                setModalState(() => _isPosting = false);
                                if (context.mounted) Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: ThemeProvider.primaryNavy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text('Post'),
                            ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        TextField(
                          controller: _captionController,
                          decoration: InputDecoration(
                            hintText: "What's on your mind?",
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                          style: GoogleFonts.inter(fontSize: 16),
                          autofocus: true,
                        ),
                        if (_selectedImage != null) ...[
                          const SizedBox(height: 20),
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_selectedImage!, width: double.infinity, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black.withOpacity(0.5),
                                  child: IconButton(
                                    icon: Icon(Icons.close, color: Theme.of(context).cardColor, size: 20),
                                    onPressed: () {
                                      setModalState(() => _selectedImage = null);
                                      setState(() => _selectedImage = null);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.of(context).padding.bottom),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              setModalState(() => _selectedImage = File(pickedFile.path));
                              setState(() => _selectedImage = File(pickedFile.path));
                            }
                          },
                          icon: Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.primary),
                          tooltip: 'Add Photo',
                        ),
                        IconButton(
                          onPressed: () {}, // Future: Polls
                          icon: Icon(Icons.poll_outlined, color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
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

    return InkWell(
      onTap: () => context.push('/community/post/${post.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: ThemeProvider.primaryNavy.withOpacity(0.05),
                    child: Text(post.authorName[0], style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.authorName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.primary)),
                        Text(DateFormat('MMM d • HH:mm').format(post.createdAt), style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  if (isAdmin || post.authorId == user?.uid)
                    IconButton(
                      icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400, size: 20),
                      onPressed: () => _showOptions(context, communityService),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                post.caption, 
                style: GoogleFonts.inter(fontSize: 15, color: Theme.of(context).colorScheme.primary, height: 1.4)
              ),
            ),
            if (post.imageUrl != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Image.network(
                  post.imageUrl!, 
                  width: double.infinity, 
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Theme.of(context).dividerColor,
                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Row(
                children: [
                  _ActionButton(
                    icon: post.likes.contains(user?.uid) ? Icons.thumb_up_alt_rounded : Icons.thumb_up_off_alt_rounded,
                    label: '${post.likes.length}',
                    color: post.likes.contains(user?.uid) ? ThemeProvider.accentTeal : Colors.grey.shade600,
                    onTap: () => communityService.toggleLike(post.id, user?.uid ?? ''),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.mode_comment_outlined,
                    label: '${post.commentCount}',
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white,
                    onTap: () => context.push('/community/post/${post.id}'),
                  ),
                  const Spacer(),
                  _ActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post link copied!')));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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
