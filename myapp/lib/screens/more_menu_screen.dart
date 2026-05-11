import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/member_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/providers/app_mode_provider.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final appMode = Provider.of<AppModeProvider>(context);
    final isAdmin = appMode.activeMembership?.role == SocietyRole.admin ||
        user?.currentRole == AppRole.superAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              if (user != null) _buildProfileHeader(context, user),
              const SizedBox(height: 28),

              _buildSectionHeader('Account'),
              _buildMenuTile(
                context,
                'Edit Profile',
                Icons.person_outline_rounded,
                () => context.push('/profile/edit'),
              ),
              _buildMenuTile(
                context,
                'Notification Settings',
                Icons.notifications_rounded,
                () => context.push('/settings/notifications'),
              ),
              _buildMenuTile(
                context,
                'Account Security',
                Icons.security_rounded,
                () {},
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('Community & Society'),
              _buildMenuTile(
                context,
                'Switch Property Mode',
                Icons.swap_horiz_rounded,
                () => context.push('/select-society'),
              ),
              _buildMenuTile(
                context,
                'Document Library',
                Icons.folder_rounded,
                () => context.push('/documents'),
              ),
              if (isAdmin)
                _buildMenuTile(
                  context,
                  'Invite New Member',
                  Icons.person_add_rounded,
                  () => context.push('/society/invite'),
                  color: ThemeProvider.accentTeal,
                ),
              if (isAdmin)
                _buildMenuTile(
                  context,
                  'Society Settings',
                  Icons.settings_rounded,
                  () => context.push('/society/settings'),
                  color: ThemeProvider.primaryNavy,
                ),

              const SizedBox(height: 24),
              _buildSectionHeader('Support'),
              _buildMenuTile(context, 'Help Center', Icons.help_outline_rounded, () {}),
              _buildMenuTile(context, 'Report an Issue', Icons.bug_report_outlined, () {}),

              const SizedBox(height: 40),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: ThemeProvider.primaryNavy,
            backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                ? NetworkImage(user.photoUrl!)
                : null,
            child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                ? Text(
                    user.name?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? 'User',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: ThemeProvider.primaryNavy,
                  ),
                ),
                Text(
                  user.email ?? '',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ThemeProvider.accentTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.currentRole.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: ThemeProvider.accentTeal,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: ThemeProvider.accentTeal),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    final effectiveColor = color ?? ThemeProvider.primaryNavy;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: effectiveColor, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: ThemeProvider.primaryNavy),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('LOG OUT', style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}
