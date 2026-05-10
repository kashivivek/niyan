import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/member_model.dart';
import 'package:myapp/services/sos_service.dart';
import 'package:myapp/services/billing_service.dart';
import 'package:myapp/models/invoice_model.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/utils/currency_helper.dart';

class ResidentDashboardScreen extends StatelessWidget {
  const ResidentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final appMode = Provider.of<AppModeProvider>(context);
    final billingService = Provider.of<BillingService>(context, listen: false);

    if (user == null || appMode.activeSociety == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: ThemeProvider.accentTeal)));
    }

    final isOwner = appMode.activeMembership?.role == SocietyRole.owner || 
                    appMode.activeMembership?.role == SocietyRole.admin;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: () => _triggerSos(context, user, appMode),
          backgroundColor: Colors.red.shade600,
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
          label: Text('SOS', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section moved to header, start directly with dues or insights
            if (isOwner) ...[
              Text('Welcome back, ${(user.name?.split(' ') ?? ['Resident']).first}!', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
              const SizedBox(height: 16),
              _buildOwnerStats(context),
              const SizedBox(height: 32),
            ],

            _buildDuesSection(context, user, billingService),
            
            const SizedBox(height: 32),
            
            Text('Quick Services', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
            const SizedBox(height: 20),
            
            _buildServiceGrid(context),
            
            const SizedBox(height: 32),
            _buildActivitySection(context),
            const SizedBox(height: 120), // Bottom padding for Nav Bar
          ],
        ),
      ),
    );
  }

  Widget _buildDuesSection(BuildContext context, UserModel user, BillingService billingService) {
    return StreamBuilder<List<InvoiceModel>>(
      stream: billingService.getInvoices(residentId: user.uid),
      builder: (context, snapshot) {
        final invoices = snapshot.data ?? [];
        final totalDue = invoices
            .where((i) => i.status != InvoiceStatus.paid && i.status != InvoiceStatus.cancelled)
            .fold(0.0, (sum, i) => sum + i.grandTotal);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ThemeProvider.primaryNavy,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: ThemeProvider.primaryNavy.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.receipt_long_rounded, color: ThemeProvider.accentTeal, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('Current Dues', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyHelper.format(totalDue, user.currency),
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push('/resident-ledger'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeProvider.accentTeal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('PAY NOW'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOwnerStats(BuildContext context) {
    final appMode = Provider.of<AppModeProvider>(context, listen: false);
    final billingService = Provider.of<BillingService>(context, listen: false);

    if (appMode.activeSociety == null) return const SizedBox.shrink();

    return StreamBuilder<double>(
      stream: billingService.getSocietyTotalCollections(appMode.activeSociety!.id),
      builder: (context, snapshot) {
        final totalCollected = snapshot.data ?? 0.0;
        final currency = appMode.activeSociety!.settings.currency;
        
        return Row(
          children: [
            _OwnerStatCard(
              title: 'Occupancy', 
              value: '94%', // Mock for now, can be calculated from unit stats
              icon: Icons.house_rounded, 
              color: ThemeProvider.primaryNavy
            ),
            const SizedBox(width: 16),
            _OwnerStatCard(
              title: 'Collected', 
              value: totalCollected >= 1000 
                ? '${CurrencyHelper.getSymbol(currency)}${(totalCollected/1000).toStringAsFixed(1)}k'
                : CurrencyHelper.format(totalCollected, currency), 
              icon: Icons.payments_rounded, 
              color: ThemeProvider.accentTeal
            ),
          ],
        );
      }
    );
  }

  Widget _buildServiceGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      children: [
        _ServiceIcon(title: 'Visitors', icon: Icons.person_add_alt_1_rounded, color: ThemeProvider.accentTeal, onTap: () => context.push('/visitors/invite')),
        _ServiceIcon(title: 'Helpdesk', icon: Icons.support_agent_rounded, color: ThemeProvider.primaryNavy, onTap: () => context.push('/helpdesk')),
        _ServiceIcon(title: 'Amenities', icon: Icons.sports_tennis_rounded, color: ThemeProvider.accentTeal, onTap: () => context.push('/amenities')),
        _ServiceIcon(title: 'Notices', icon: Icons.campaign_rounded, color: ThemeProvider.primaryNavy, onTap: () => context.push('/notices')),
        _ServiceIcon(title: 'Polls', icon: Icons.how_to_vote_rounded, color: ThemeProvider.accentTeal, onTap: () => context.push('/polls')),
        _ServiceIcon(title: 'Payments', icon: Icons.payments_rounded, color: ThemeProvider.primaryNavy, onTap: () => context.push('/resident-ledger')),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
          const SizedBox(height: 16),
          _activityItem('Maintenance Bill Generated', '2 days ago', Icons.receipt_long_rounded, ThemeProvider.accentTeal),
          const Divider(height: 24),
          _activityItem('Water Tank Cleaning Notice', '3 days ago', Icons.water_drop_rounded, ThemeProvider.primaryNavy),
        ],
      ),
    );
  }

  Widget _activityItem(String title, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: ThemeProvider.primaryNavy)),
              Text(time, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _triggerSos(BuildContext context, UserModel user, AppModeProvider appMode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm SOS Alert?'),
        content: const Text('This will immediately alert security and admins of your emergency.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('SEND SOS'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SosService().triggerSos(
        societyId: appMode.activeSociety!.id,
        residentId: user.uid,
        residentName: user.name ?? 'Resident',
        unitNumber: appMode.activeMembership?.unitIds.firstOrNull ?? 'Unknown',
      );
    }
  }
}

class _OwnerStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _OwnerStatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
            Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class _ServiceIcon extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ServiceIcon({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ThemeProvider.primaryNavy)),
        ],
      ),
    );
  }
}
