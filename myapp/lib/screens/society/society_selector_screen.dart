import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/society_model.dart';
import 'package:myapp/models/member_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/society_service.dart';
import 'package:myapp/services/property_service.dart';
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
  bool _showCreateForm = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _createSociety(UserModel user, SocietyService societyService, AppModeProvider appMode) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreating = true);
    try {
      final societyId = await societyService.createSociety(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        createdByUserId: user.uid,
        createdByName: user.name,
        createdByEmail: user.email,
      );

      if (!mounted) return;
      final society = await societyService.getSocietyById(societyId);
      final membership = await societyService.getMember(societyId, user.uid);

      if (society != null && membership != null) {
        await appMode.switchToSocietyMode(
          society: society,
          membership: membership,
          userId: user.uid,
        );
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
    final propertyService = Provider.of<PropertyService>(context, listen: false);
    final appMode = Provider.of<AppModeProvider>(context, listen: false);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isSocietyRole = user.currentRole == AppRole.guard ||
        user.currentRole == AppRole.societyAdmin ||
        user.currentRole == AppRole.superAdmin ||
        user.currentRole == AppRole.treasurer ||
        user.currentRole == AppRole.resident ||
        user.currentRole == AppRole.tenant;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Switch Property Mode', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: StreamBuilder<List<SocietyModel>>(
        stream: societyService.getUserSocieties(user.uid),
        builder: (context, societySnapshot) {
          final societies = societySnapshot.data ?? [];
          final hasSocieties = societies.isNotEmpty;

          return FutureBuilder<bool>(
            future: _checkHasProperties(propertyService, user.uid),
            builder: (context, propertySnapshot) {
              final hasProperties = propertySnapshot.data ?? false;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── STANDALONE LANDLORD SECTION ──
                    // Show only if the user has standalone properties
                    if (hasProperties || !isSocietyRole) ...[
                      _buildSectionHeader('Personal Mode'),
                      _buildModeCard(
                        title: 'Standalone Landlord',
                        subtitle: 'Manage personal properties and tenants.',
                        icon: Icons.home_work_rounded,
                        isActive: appMode.isStandaloneMode,
                        onTap: () async {
                          await appMode.switchToStandaloneMode(userId: user.uid);
                          if (context.mounted) context.go('/');
                        },
                      ),
                      const SizedBox(height: 32),
                    ],

                    // ── SOCIETY ERP SECTION ──
                    _buildSectionHeader('Society ERP Mode'),
                    if (societies.isEmpty && !_showCreateForm)
                      _buildSocietyEmptyState(user, isSocietyRole: isSocietyRole)
                    else
                      ...societies.map((s) => _buildSocietyCard(s, user, societyService, appMode)),

                    const SizedBox(height: 24),
                    if (_showCreateForm)
                      _buildCreateForm(user, societyService, appMode)
                    else if (user.currentRole == AppRole.societyAdmin ||
                        user.currentRole == AppRole.superAdmin ||
                        societies.isEmpty)
                      _buildCreateButton()
                    else
                      _buildContactAdminNote(),

                    // ── ADD PROPERTY PROMO (for society-only users with no properties) ──
                    if (isSocietyRole && !hasProperties) ...[
                      const SizedBox(height: 32),
                      _buildStandalonePromoCard(context),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _checkHasProperties(PropertyService service, String uid) async {
    try {
      final props = await service.getProperties(uid).first;
      return props.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
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
              decoration: BoxDecoration(
                  color: isActive ? ThemeProvider.accentTeal : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: isActive ? Colors.white : Colors.grey.shade400),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
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
          await appMode.switchToSocietyMode(
            society: society,
            membership: membership,
            userId: user.uid,
          );
          if (mounted) context.go('/');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? ThemeProvider.accentTeal.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isActive ? ThemeProvider.accentTeal : Colors.grey.shade100, width: isActive ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: ThemeProvider.primaryNavy.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.apartment_rounded, color: Theme.of(context).colorScheme.primary),
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
            if (isActive)
              const Icon(Icons.check_circle_rounded, color: ThemeProvider.accentTeal)
            else
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSocietyEmptyState(UserModel user, {required bool isSocietyRole}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Icon(Icons.apartment_rounded, size: 64, color: Colors.grey.shade100),
          const SizedBox(height: 16),
          Text('No Societies Linked',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
          Text(
            isSocietyRole
                ? 'You haven\'t been added to a society yet. Contact your admin.'
                : 'Join or create a society to enable ERP features.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStandalonePromoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ThemeProvider.primaryNavy, ThemeProvider.primaryNavy.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_work_rounded, color: ThemeProvider.accentTeal, size: 28),
              const SizedBox(width: 12),
              Text('Own Personal Properties?',
                  style: GoogleFonts.outfit(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          ...['Automated Rent Invoicing', 'Digital Payment Receipts', 'Tenant KYC & Documents'].map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: ThemeProvider.accentTeal, size: 16),
                  const SizedBox(width: 10),
                  Text(f, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/properties/add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeProvider.accentTeal,
                foregroundColor: ThemeProvider.primaryNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text('Add a Property', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
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
          Expanded(
            child: Text(
              'Contact your society administrator to be invited to a community.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm(UserModel user, SocietyService service, AppModeProvider appMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ThemeProvider.accentTeal.withOpacity(0.3)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Register Society',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _showCreateForm = false)),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(_nameController, 'Society Name'),
            const SizedBox(height: 12),
            _buildField(_addressController, 'Address'),
            const SizedBox(height: 12),
            _buildField(_cityController, 'City'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isCreating ? null : () => _createSociety(user, service, appMode),
                child: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CREATE SOCIETY'),
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
      decoration: InputDecoration(
          labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
    );
  }
}
