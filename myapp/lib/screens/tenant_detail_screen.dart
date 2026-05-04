import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/rent_status.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/rent_record_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/screens/edit_tenant_screen.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/utils/currency_helper.dart';
import 'package:go_router/go_router.dart';

class TenantDetailScreen extends StatelessWidget {
  final TenantModel? tenant;
  final String tenantId;

  const TenantDetailScreen({super.key, this.tenant, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);
    final user = Provider.of<UserModel?>(context);

    return StreamBuilder<TenantModel>(
      stream: databaseService.getTenantStream(tenantId),
      initialData: tenant,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final currentTenant = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tenant Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/tenants/edit', extra: currentTenant),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDelete(context, databaseService, currentTenant),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: <Widget>[
                _buildProfileHeader(context, currentTenant),
                const SizedBox(height: 24),
                _buildFinancialOverview(context, currentTenant, databaseService, user?.currency),
                const SizedBox(height: 24),
                _buildContactInfo(context, currentTenant),
                const SizedBox(height: 32),
                if (currentTenant.isAssignedToUnit)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_remove_outlined),
                      label: const Text('Unassign from Unit'),
                      onPressed: () => _confirmUnassign(context, databaseService, currentTenant),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, TenantModel tenant) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: ThemeProvider.primaryNavy.withOpacity(0.05),
            backgroundImage: tenant.photoUrl != null && tenant.photoUrl!.isNotEmpty ? NetworkImage(tenant.photoUrl!) : null,
            child: tenant.photoUrl == null || tenant.photoUrl!.isEmpty
                ? Icon(Icons.person_outline_rounded, size: 50, color: ThemeProvider.primaryNavy.withOpacity(0.5))
                : null,
          ),
          const SizedBox(height: 16),
          Text(tenant.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildStatusBadge(tenant),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TenantModel tenant) {
    final isActive = tenant.status == TenantStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (isActive ? Colors.teal : Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active Tenant' : 'Past Tenant',
        style: TextStyle(color: isActive ? Colors.teal.shade700 : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildFinancialOverview(BuildContext context, TenantModel tenant, DatabaseService databaseService, String? currency) {
    return StreamBuilder<List<RentRecordModel>>(
      stream: databaseService.getRentRecordsForTenant(tenant.id),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        final totalDue = records.where((r) => r.status == RentStatus.pending).fold(0.0, (sum, r) => sum + r.amount);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Financial Overview', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildFinancialItem(Icons.security_rounded, 'Security Deposit', CurrencyHelper.format(tenant.securityDeposit, currency), Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildFinancialItem(Icons.warning_amber_rounded, 'Outstanding Balance', CurrencyHelper.format(totalDue, currency), Colors.redAccent)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinancialItem(IconData icon, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  Widget _buildContactInfo(BuildContext context, TenantModel tenant) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.phone_outlined, tenant.phoneNumber ?? 'No phone number'),
          const Divider(height: 32),
          _buildInfoRow(Icons.email_outlined, tenant.email ?? 'No email'),
          if (tenant.isAssignedToUnit) ...[
            const Divider(height: 32),
            _buildInfoRow(Icons.home_work_outlined, 'Assigned to Unit ${tenant.assignedUnitId}'),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: ThemeProvider.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: ThemeProvider.accentBlue, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  void _confirmUnassign(BuildContext context, DatabaseService databaseService, TenantModel tenant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Unassignment'),
        content: Text('Are you sure you want to unassign ${tenant.name} from Unit ${tenant.assignedUnitId}?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          TextButton(
            child: const Text('Unassign', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onPressed: () async {
              await databaseService.unassignTenantFromUnit(tenantId: tenant.id, unitId: tenant.assignedUnitId, propertyId: tenant.propertyId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DatabaseService databaseService, TenantModel tenant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tenant'),
        content: Text('Delete ${tenant.name} completely?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onPressed: () async {
              await databaseService.deleteTenant(tenant.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
    );
  }
}
