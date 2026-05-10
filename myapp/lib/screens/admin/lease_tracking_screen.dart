import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/lease_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/admin_service.dart';

class LeaseTrackingScreen extends StatelessWidget {
  const LeaseTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final appMode = Provider.of<AppModeProvider>(context);
    final adminService = Provider.of<AdminService>(context, listen: false);

    if (user == null || appMode.activeSociety == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Lease Tracking', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<LeaseModel>>(
        stream: adminService.getLeasesForSociety(appMode.activeSociety!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final leases = snapshot.data ?? [];
          
          if (leases.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No active leases found', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leases.length,
            itemBuilder: (context, index) {
              final lease = leases[index];
              return _LeaseCard(lease: lease);
            },
          );
        },
      ),
    );
  }
}

class _LeaseCard extends StatelessWidget {
  final LeaseModel lease;
  const _LeaseCard({required this.lease});

  @override
  Widget build(BuildContext context) {
    final bool isExpiringSoon = lease.isExpiringSoon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpiringSoon ? Colors.orange.shade200 : Colors.grey.shade100),
        boxShadow: isExpiringSoon ? [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ThemeProvider.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Unit ${lease.unitNumber}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: ThemeProvider.accentBlue)),
              ),
              const Spacer(),
              if (isExpiringSoon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 12, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text('EXPIRING SOON', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(lease.tenantName, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.date_range_outlined, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text('${DateFormat('MMM d, yyyy').format(lease.startDate)} - ${DateFormat('MMM d, yyyy').format(lease.endDate)}', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Rent', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                    Text('₹${lease.monthlyRent.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeProvider.primaryNavy)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deposit', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                    Text('₹${lease.securityDeposit.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeProvider.primaryNavy)),
                  ],
                ),
              ),
              if (lease.documentUrl != null)
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  onPressed: () {}, // Open PDF link
                ),
            ],
          ),
        ],
      ),
    );
  }
}
