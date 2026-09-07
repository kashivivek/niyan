import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/models/unit_model.dart';
import 'package:myapp/models/rent_status.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/rent_record_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/utils/currency_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

class TenantDetailScreen extends StatefulWidget {
  final TenantModel? tenant;
  final String tenantId;

  const TenantDetailScreen({super.key, this.tenant, required this.tenantId});

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  // Cached streams — created once, never recreated on rebuild
  late Stream<TenantModel> _tenantStream;
  late Stream<List<RentRecordModel>> _rentRecordsStream;

  // Cached unit info (one-shot reads to avoid nested stream subscriptions)
  String _propertyName = '';
  String _unitName = '';
  String? _lastPropertyId;
  String? _lastUnitId;

  @override
  void initState() {
    super.initState();
    final databaseService = context.read<DatabaseService>();

    // Create streams ONCE and cache them
    _tenantStream = databaseService
        .getTenantStream(widget.tenantId)
        .handleError((error) {
      developer.log('Tenant stream error (suppressed): $error');
    });

    _rentRecordsStream = databaseService
        .getRentRecordsForTenant(widget.tenantId)
        .handleError((error) {
      developer.log('Rent records stream error (suppressed): $error');
    });

    // Pre-fetch unit info if initial data is available
    if (widget.tenant != null &&
        widget.tenant!.isAssignedToUnit &&
        widget.tenant!.propertyId.isNotEmpty) {
      _fetchUnitInfo(
          databaseService, widget.tenant!.propertyId, widget.tenant!.assignedUnitId);
    }
  }

  /// One-shot read for property & unit names — avoids nested snapshot listeners
  Future<void> _fetchUnitInfo(
      DatabaseService databaseService, String propertyId, String unitId) async {
    // Skip if already loaded for this property+unit
    if (propertyId == _lastPropertyId && unitId == _lastUnitId) return;
    _lastPropertyId = propertyId;
    _lastUnitId = unitId;

    try {
      final results = await Future.wait([
        databaseService.getPropertyFuture(propertyId),
        databaseService.getUnitFuture(unitId, propertyId),
      ]);
      if (mounted) {
        setState(() {
          _propertyName = (results[0] as PropertyModel?)?.name ?? 'Property unavailable';
          _unitName = (results[1] as UnitModel?)?.unitNumber ?? 'Not assigned';
        });
      }
    } catch (e) {
      developer.log('Error fetching unit info: $e');
      if (mounted) {
        setState(() {
          _propertyName = 'Property unavailable';
          _unitName = 'Not assigned';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final user = Provider.of<UserModel?>(context);

    return StreamBuilder<TenantModel>(
      stream: _tenantStream,
      initialData: widget.tenant,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tenant Profile')),
            body: const Center(child: Text('Something went wrong. Please go back and try again.')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final currentTenant = snapshot.data!;

        // Refresh unit info when tenant's assignment changes
        if (currentTenant.isAssignedToUnit && currentTenant.propertyId.isNotEmpty) {
          _fetchUnitInfo(databaseService, currentTenant.propertyId, currentTenant.assignedUnitId);
        }

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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: Column(
              children: <Widget>[
                _buildProfileHeader(context, currentTenant),
                const SizedBox(height: 24),
                _buildFinancialOverview(context, currentTenant, user?.currency),
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
        color: Theme.of(context).cardColor,
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

  Widget _buildFinancialOverview(BuildContext context, TenantModel tenant, String? currency) {
    // Uses the CACHED _rentRecordsStream — never recreated on rebuild
    return StreamBuilder<List<RentRecordModel>>(
      stream: _rentRecordsStream,
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        final totalDue = records.where((r) => r.status == RentStatus.pending).fold(0.0, (sum, r) => sum + r.amount);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildPhoneRow(context, tenant.phoneNumber),
          const Divider(height: 32),
          _buildInfoRow(Icons.email_outlined, tenant.email ?? 'No email'),
          if (tenant.isAssignedToUnit) ...[
            const Divider(height: 32),
            _buildUnitRow(context, tenant),
          ]
        ],
      ),
    );
  }

  Widget _buildPhoneRow(BuildContext context, String? phone) {
    final hasPhone = phone != null && phone.isNotEmpty;
    return GestureDetector(
      onTap: hasPhone
          ? () async {
              final uri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            }
          : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasPhone
                  ? Colors.green.withOpacity(0.1)
                  : ThemeProvider.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.phone_outlined,
              color: hasPhone ? Colors.green.shade700 : ThemeProvider.accentBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPhone ? phone! : 'No phone number',
                  style: TextStyle(
                    fontSize: 16,
                    color: hasPhone ? Colors.green.shade800 : Colors.grey.shade600,
                    fontWeight: hasPhone ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (hasPhone)
                  Text(
                    'Tap to call',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
          if (hasPhone)
            Icon(Icons.call_rounded, color: Colors.green.shade600, size: 20),
        ],
      ),
    );
  }

  /// Uses cached property/unit names — NO nested StreamBuilder, NO CombineLatestStream
  Widget _buildUnitRow(BuildContext context, TenantModel tenant) {
    if (tenant.propertyId.isEmpty) {
      return _buildInfoRow(Icons.home_work_outlined, 'Unit: ${tenant.assignedUnitId}');
    }
    final propertyName = _propertyName.isNotEmpty ? _propertyName : 'Loading...';
    final unitName = _unitName.isNotEmpty ? _unitName : '...';
    final label = '$propertyName  ·  Unit: $unitName';
    return _buildInfoRow(Icons.home_work_outlined, label);
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
              await databaseService.unassignTenantFromUnit(tenantId: tenant.id, unitId: tenant.assignedUnitId, propertyId: tenant.propertyId, ownerId: tenant.ownerId);
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
              try {
                await databaseService.deleteTenant(tenant.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) context.pop();
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
