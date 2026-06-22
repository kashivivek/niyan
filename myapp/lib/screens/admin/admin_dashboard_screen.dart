import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/widgets/vibrant_dashboard_tile.dart';
import 'package:myapp/services/billing_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _hasCheckedInvoices = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedInvoices) {
      _checkAutoGeneration();
      _hasCheckedInvoices = true;
    }
  }

  Future<void> _checkAutoGeneration() async {
    final appMode = Provider.of<AppModeProvider>(context, listen: false);
    if (appMode.activeSociety != null && appMode.activeSociety!.settings.autoGenerateInvoices) {
      final billing = BillingService();
      await billing.autoGenerateMonthlyInvoices(appMode.activeSociety!.id, appMode.activeSociety!.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final appMode = Provider.of<AppModeProvider>(context);

    if (user == null || appMode.activeSociety == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: ThemeProvider.accentTeal),
              SizedBox(height: 16),
              Text('Initializing Society Dashboard...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  Text(
                    'Welcome back, ${(user.name?.split(' ') ?? ['Admin']).first}!',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Here is what needs your attention today.',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 28),
                  // Section 1: Critical Actions / Highlights
                  Text(
                    'Critical Alerts',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeaturedCard(
                          context,
                          'Pending Invoices',
                          '42 Overdue',
                          Icons.receipt_long_rounded,
                          ThemeProvider.primaryNavy,
                          () => context.push('/invoices'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildFeaturedCard(
                          context,
                          'Open Tickets',
                          '12 Urgent',
                          Icons.build_circle_rounded,
                          ThemeProvider.accentTeal,
                          () => context.push('/helpdesk'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Section 2: Management Tools
                  Text(
                    'Management Tools',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Desktop: 5 cols, laptop: 4, tablet: 3, mobile: 2
                      final cols = constraints.maxWidth > 1100 ? 5 : (constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 3 : 2));
                      final ratio = constraints.maxWidth > 1100 ? 1.0 : 1.1;
                      return GridView.count(
                        crossAxisCount: cols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: ratio,
                        children: [
                          VibrantDashboardTile(
                            title: 'Gate Control',
                            subtitle: 'Live entry logs',
                            icon: Icons.shield_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            onTap: () => context.push('/gate'),
                            badgeText: 'Live',
                          ),
                          VibrantDashboardTile(
                            title: 'Notices',
                            subtitle: 'Broadcast alerts',
                            icon: Icons.campaign_rounded,
                            color: ThemeProvider.accentTeal,
                            onTap: () => context.push('/notices'),
                          ),
                          VibrantDashboardTile(
                            title: 'Assets',
                            subtitle: 'Equipment & Maint.',
                            icon: Icons.precision_manufacturing_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            onTap: () => context.push('/assets'),
                          ),
                          VibrantDashboardTile(
                            title: 'Amenities',
                            subtitle: 'Facility bookings',
                            icon: Icons.sports_tennis_rounded,
                            color: ThemeProvider.accentTeal,
                            onTap: () => context.push('/amenities'),
                          ),
                          VibrantDashboardTile(
                            title: 'Settings',
                            subtitle: 'Rules & Automation',
                            icon: Icons.settings_suggest_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            onTap: () => context.push('/society/settings'),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Section 3: Recent Activity
                  _buildActivitySection(context),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }


  Widget _buildFeaturedCard(BuildContext context, String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).cardColor, size: 24),
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).cardColor,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem('Visitor Check-in: Delivery', '10 mins ago', Icons.local_shipping_rounded, ThemeProvider.accentTeal),
          const Divider(height: 24),
          _buildActivityItem('New Ticket: Water Leak', '1 hour ago', Icons.water_drop_rounded, Colors.redAccent),
          const Divider(height: 24),
          _buildActivityItem('Payment: Unit A-102', '2 hours ago', Icons.payments_rounded, Colors.green),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
              ),
              Text(
                time,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
