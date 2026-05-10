import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/society_model.dart';
import 'package:myapp/models/member_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/society_service.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';

class SocietySelectorScreen extends StatefulWidget {
  const SocietySelectorScreen({super.key});

  @override
  State<SocietySelectorScreen> createState() => _SocietySelectorScreenState();
}

class _SocietySelectorScreenState extends State<SocietySelectorScreen> {
  bool _isCreating = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  bool _showCreateForm = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _createSociety(UserModel user, SocietyService societyService) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreating = true);
    try {
      final societyId = await societyService.createSociety(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        createdByUserId: user.uid,
        createdByName: user.name,
        createdByEmail: user.email,
      );

      if (!mounted) return;
      final appMode = context.read<AppModeProvider>();
      final society = await societyService.getSocietyById(societyId);
      final membership = await societyService.getMember(societyId, user.uid);
      
      if (society != null && membership != null) {
        await appMode.switchToSocietyMode(society: society, membership: membership);
        if (mounted) context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final societyService = Provider.of<SocietyService>(context, listen: false);
    final appMode = Provider.of<AppModeProvider>(context, listen: false);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Switch Mode', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: StreamBuilder<List<SocietyModel>>(
        stream: societyService.getUserSocieties(user.uid),
        builder: (context, snapshot) {
          final societies = snapshot.data ?? [];
          final canCreate = user.currentRole == AppRole.societyAdmin || societies.isEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Personal Mode'),
                _buildModeCard(
                  title: 'Standalone Landlord',
                  subtitle: 'Manage personal properties and tenants.',
                  icon: Icons.person_rounded,
                  isActive: appMode.isStandaloneMode,
                  onTap: () async {
                    await appMode.switchToStandaloneMode();
                    if (context.mounted) context.go('/');
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Society ERP Mode'),
                if (societies.isEmpty && !_showCreateForm)
                  _buildEmptyState()
                else
                  ...societies.map((s) => _buildSocietyCard(s, user, societyService, appMode)),
                
                const SizedBox(height: 24),
                if (_showCreateForm)
                  _buildCreateForm(user, societyService)
                else if (canCreate)
                  _buildCreateButton()
                else
                  _buildContactAdminNote(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
    );
  }

  Widget _buildModeCard({required String title, required String subtitle, required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive ? ThemeProvider.accentTeal.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? ThemeProvider.accentTeal : Colors.grey.shade100, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isActive ? ThemeProvider.accentTeal : Colors.grey.shade50, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: isActive ? Colors.white : Colors.grey.shade400),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (isActive) const Icon(Icons.check_circle_rounded, color: ThemeProvider.accentTeal),
          ],
        ),
      ),
    );
  }

  Widget _buildSocietyCard(SocietyModel society, UserModel user, SocietyService service, AppModeProvider appMode) {
    final isActive = appMode.activeSociety?.id == society.id && appMode.isSocietyMode;
    return GestureDetector(
      onTap: () async {
        final membership = await service.getMember(society.id, user.uid);
        if (membership != null) {
          await appMode.switchToSocietyMode(society: society, membership: membership);
          if (mounted) context.go('/');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? ThemeProvider.accentTeal.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? ThemeProvider.accentTeal : Colors.grey.shade100, width: isActive ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: ThemeProvider.primaryNavy.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.apartment_rounded, color: ThemeProvider.primaryNavy),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(society.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  Text(society.city, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (isActive) const Icon(Icons.check_circle_rounded, color: ThemeProvider.accentTeal)
            else const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Icon(Icons.apartment_rounded, size: 64, color: Colors.grey.shade100),
          const SizedBox(height: 16),
          Text('No Societies Linked', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
          Text('Join or create a society to enable ERP features.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _showCreateForm = true),
        icon: const Icon(Icons.add_rounded),
        label: const Text('CREATE NEW SOCIETY'),
        style: OutlinedButton.styleFrom(
          foregroundColor: ThemeProvider.accentTeal,
          side: const BorderSide(color: ThemeProvider.accentTeal, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildContactAdminNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text('Contact your society administrator to be invited to a community.', style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade700))),
        ],
      ),
    );
  }

  Widget _buildCreateForm(UserModel user, SocietyService service) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: ThemeProvider.accentTeal.withOpacity(0.3))),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Register Society', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _showCreateForm = false)),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(_nameController, 'Name'),
            const SizedBox(height: 12),
            _buildField(_addressController, 'Address'),
            const SizedBox(height: 12),
            _buildField(_cityController, 'City'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isCreating ? null : () => _createSociety(user, service),
                child: _isCreating ? const CircularProgressIndicator(color: Colors.white) : const Text('CREATE SOCIETY'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
    );
  }
}
