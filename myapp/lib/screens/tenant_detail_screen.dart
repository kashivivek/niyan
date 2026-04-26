import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/screens/edit_tenant_screen.dart';
import 'package:myapp/providers/theme_provider.dart';

class TenantDetailScreen extends StatelessWidget {
  final TenantModel tenant;

  const TenantDetailScreen({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenant Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditTenantScreen(tenant: tenant))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: <Widget>[
            // Profile Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
                  Text(
                    tenant.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: tenant.isAssignedToUnit ? Colors.teal.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tenant.isAssignedToUnit ? 'Assigned' : 'Unassigned',
                      style: TextStyle(
                        color: tenant.isAssignedToUnit ? Colors.teal.shade700 : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact Info Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _buildInfoRow(context, Icons.phone_outlined, tenant.phoneNumber ?? 'No phone number'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                  _buildInfoRow(context, Icons.email_outlined, tenant.email ?? 'No email'),
                  if (tenant.isAssignedToUnit) ...[
                     const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                    _buildInfoRow(context, Icons.home_work_outlined, 'Assigned to Unit ${tenant.assignedUnitId}'),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (tenant.isAssignedToUnit)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_remove_outlined),
                  label: const Text('Unassign from Unit'),
                  onPressed: () => _confirmUnassign(context),
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
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ThemeProvider.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: ThemeProvider.accentBlue, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  void _confirmUnassign(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Unassignment'),
          content: Text('Are you sure you want to unassign ${tenant.name}?'),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(
              child: const Text('Unassign', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await context.read<DatabaseService>().unassignTenantFromUnit(
                    tenantId: tenant.id,
                    unitId: tenant.assignedUnitId,
                    propertyId: tenant.propertyId,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                   if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Tenant'),
          content: Text('Are you sure you want to completely remove ${tenant.name}?'),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await context.read<DatabaseService>().deleteTenant(tenant.id);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
          ],
        );
      },
    );
  }
}
