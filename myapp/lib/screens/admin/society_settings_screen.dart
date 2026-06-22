import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/society_model.dart';
import 'package:myapp/services/society_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/providers/app_mode_provider.dart';

class SocietySettingsScreen extends StatefulWidget {
  const SocietySettingsScreen({super.key});

  @override
  State<SocietySettingsScreen> createState() => _SocietySettingsScreenState();
}

class _SocietySettingsScreenState extends State<SocietySettingsScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  late SocietySettings _settings;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final appMode = Provider.of<AppModeProvider>(context);
      _settings = appMode.activeSociety?.settings ?? const SocietySettings();
      _nameController.text = appMode.activeSociety?.name ?? '';
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final appMode = Provider.of<AppModeProvider>(context, listen: false);
      final societyService = SocietyService();
      
      // Update Name if changed
      if (_nameController.text.trim() != appMode.activeSociety?.name) {
        await societyService.updateSociety(appMode.activeSociety!.copyWith(name: _nameController.text.trim()));
      }

      await societyService.updateSocietySettings(appMode.activeSociety!.id, _settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Society settings updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Society Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('General Info'),
            _buildSettingCard(
              title: 'Society Name',
              subtitle: 'Official name displayed to residents.',
              icon: Icons.business_rounded,
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(isDense: true, border: UnderlineInputBorder()),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
            _buildSettingCard(
              title: 'Society Currency',
              subtitle: 'Base currency for all billing.',
              icon: Icons.currency_exchange_rounded,
              trailing: DropdownButton<String>(
                value: _settings.currency,
                items: ['INR', 'USD', 'EUR', 'GBP', 'AED', 'SGD', 'AUD', 'CAD']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))))
                    .toList(),
                onChanged: (v) => setState(() => _settings = _settings.copyWith(currency: v)),
                underline: const SizedBox(),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Billing & Automation'),
            _buildSettingCard(
              title: 'Auto-Generate Invoices',
              subtitle: 'Automatically create monthly bills on the due date.',
              icon: Icons.auto_awesome_rounded,
              trailing: Switch(
                value: _settings.autoGenerateInvoices,
                onChanged: (v) => setState(() => _settings = _settings.copyWith(autoGenerateInvoices: v)),
                activeColor: ThemeProvider.accentTeal,
              ),
            ),
            _buildSettingCard(
              title: 'Late Payment Fees',
              subtitle: 'Apply a penalty fee to invoices that are not paid within the grace period.',
              icon: Icons.money_off_rounded,
              trailing: Switch(
                value: _settings.lateFeeEnabled,
                onChanged: (v) => setState(() => _settings = _settings.copyWith(lateFeeEnabled: v)),
                activeColor: ThemeProvider.accentTeal,
              ),
            ),
            if (_settings.lateFeeEnabled) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _settings.lateFeeFlat?.toString() ?? '500',
                        decoration: InputDecoration(
                          labelText: 'Flat Fee Amount',
                          prefixText: '${_settings.currency} ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() => _settings = _settings.copyWith(lateFeeFlat: double.tryParse(v))),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _settings.gracePeriodDays.toString(),
                        decoration: InputDecoration(
                          labelText: 'Grace Period (Days)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() => _settings = _settings.copyWith(gracePeriodDays: int.tryParse(v) ?? 7)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            _buildSectionHeader('Compliance'),
            _buildSettingCard(
              title: 'GST Compliance',
              subtitle: 'Enable GST calculations for maintenance bills above threshold.',
              icon: Icons.gavel_rounded,
              trailing: Switch(
                value: _settings.gstEnabled,
                onChanged: (v) => setState(() => _settings = _settings.copyWith(gstEnabled: v)),
                activeColor: ThemeProvider.accentTeal,
              ),
            ),
            
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeProvider.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('SAVE SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color, letterSpacing: 1.2)),
    );
  }

  Widget _buildSettingCard({required String title, required String subtitle, required IconData icon, required Widget trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: ThemeProvider.primaryNavy.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
