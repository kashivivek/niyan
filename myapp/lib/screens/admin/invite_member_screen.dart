import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/member_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/services/society_service.dart';

class InviteMemberScreen extends StatefulWidget {
  const InviteMemberScreen({super.key});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  SocietyRole _selectedRole = SocietyRole.tenant;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final appMode = Provider.of<AppModeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Member')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grant Access', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 8),
            Text('Invite users to join ${appMode.activeSociety?.name} and assign their roles.', style: GoogleFonts.inter(color: Colors.grey.shade600)),
            const SizedBox(height: 32),
            
            _buildRoleSelector(),
            const SizedBox(height: 32),
            
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Display Name (Optional)',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: 'User Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendInvite,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('SEND INVITATION'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    final roles = [
      SocietyRole.tenant,
      SocietyRole.owner,
      SocietyRole.guard,
      SocietyRole.admin,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT ROLE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: roles.map((role) {
            final isSelected = _selectedRole == role;
            return ChoiceChip(
              label: Text(role.label),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedRole = role),
              selectedColor: ThemeProvider.accentTeal.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? ThemeProvider.accentTeal : ThemeProvider.primaryNavy,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _sendInvite() async {
    if (_emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email is required')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final appMode = Provider.of<AppModeProvider>(context, listen: false);
      final currentUser = Provider.of<UserModel?>(context, listen: false);
      final societyService = SocietyService();
      
      // 1. Try to find existing user by email in Firestore
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailCtrl.text.trim())
          .limit(1)
          .get();

      String userId;
      if (userSnap.docs.isNotEmpty) {
        userId = userSnap.docs.first.id;
      } else {
        // For this MVP, if user doesn't exist, we'll use email as ID or a random ID
        // In production, you'd handle this with a dedicated 'invites' collection
        userId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
      }

      await societyService.inviteMember(
        societyId: appMode.activeSociety!.id,
        userId: userId,
        role: _selectedRole,
        invitedBy: currentUser?.uid ?? 'Admin',
        displayName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation sent successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send invite: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
