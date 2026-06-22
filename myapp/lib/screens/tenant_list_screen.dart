import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/screens/add_tenant_screen.dart';
import 'package:myapp/screens/tenant_detail_screen.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';

class TenantListScreen extends StatelessWidget {
  const TenantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final user = Provider.of<UserModel?>(context);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<TenantModel>>(
        stream: databaseService.getAllTenants(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final tenants = snapshot.data ?? [];
          if (tenants.isEmpty) {
            return _buildEmptyState(context);
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              mainAxisExtent: 110,
            ),
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              return TenantCard(tenant: tenants[index]);
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? ThemeProvider.accentTeal : ThemeProvider.primaryNavy,
          onPressed: () => context.push('/tenants/add'),
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: Text(AppLocalizations.of(context)?.addTenant ?? 'Add Tenant', style: GoogleFonts.outfit(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)?.noTenantsFound ?? 'No tenants found', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

class TenantCard extends StatelessWidget {
  final TenantModel tenant;

  const TenantCard({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/tenant/${tenant.id}', extra: tenant),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: isDark ? ThemeProvider.accentTeal.withOpacity(0.1) : ThemeProvider.primaryNavy.withOpacity(0.05),
                  backgroundImage: tenant.photoUrl != null && tenant.photoUrl!.isNotEmpty
                      ? NetworkImage(tenant.photoUrl!)
                      : null,
                  child: tenant.photoUrl == null || tenant.photoUrl!.isEmpty
                      ? Icon(Icons.person_outline_rounded, size: 35, color: isDark ? Colors.white54 : ThemeProvider.primaryNavy.withOpacity(0.5))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tenant.phoneNumber ?? 'No phone listed',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13),
                      ),
                      if (tenant.isAssignedToUnit && tenant.assignedUnitId.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.home_work_outlined, size: 12, color: Colors.teal.shade400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Unit ${tenant.assignedUnitId}',
                                style: TextStyle(color: Colors.teal.shade600, fontSize: 11, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tenant.isAssignedToUnit 
                        ? (isDark ? Colors.teal.shade900.withOpacity(0.4) : Colors.teal.shade50) 
                        : (isDark ? Colors.orange.shade900.withOpacity(0.4) : Colors.orange.shade50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tenant.isAssignedToUnit 
                        ? (AppLocalizations.of(context)?.assigned ?? 'Assigned') 
                        : (AppLocalizations.of(context)?.unassigned ?? 'Unassigned'),
                    style: TextStyle(
                      color: tenant.isAssignedToUnit ? Colors.teal.shade700 : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
