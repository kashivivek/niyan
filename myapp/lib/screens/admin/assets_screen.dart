import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/asset_model.dart';
import 'package:myapp/services/asset_service.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/widgets/responsive_layout.dart';

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final society = Provider.of<AppModeProvider>(context).activeSociety;
    if (society == null) return const Scaffold(body: Center(child: Text('No Society Selected')));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Asset Tracking', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<AssetModel>>(
        stream: AssetService().getAssets(society.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final assets = snapshot.data ?? [];
          if (assets.isEmpty) {
            return Center(
              child: Text('No assets registered.', style: GoogleFonts.inter(color: Colors.grey.shade500)),
            );
          }

          return ResponsiveCentered(
            maxWidth: 1000,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100, top: 16),
              itemCount: assets.length,
              itemBuilder: (context, index) => _AssetCard(asset: assets[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAssetSheet(context, society.id),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? ThemeProvider.accentTeal : ThemeProvider.accentBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Asset', style: GoogleFonts.outfit(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddAssetSheet(BuildContext context, String societyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAssetSheet(societyId: societyId),
    );
  }
}

class _AssetCard extends StatefulWidget {
  final AssetModel asset;
  const _AssetCard({required this.asset});

  @override
  State<_AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends State<_AssetCard> {
  bool _isLogging = false;

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;
    Color statusColor = Colors.green;
    if (asset.status == 'under_maintenance') statusColor = Colors.orange;
    if (asset.status == 'retired') statusColor = Colors.grey;
    if (asset.status == 'maintenanceNeeded') statusColor = Colors.red;

    bool needsMaintenance = false;
    if (asset.nextMaintenanceDate != null && asset.nextMaintenanceDate!.isBefore(DateTime.now())) {
      needsMaintenance = true;
      statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeProvider.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.precision_manufacturing_rounded, color: ThemeProvider.accentBlue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asset.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
                      Text('${asset.category} · ${asset.location ?? 'Unknown location'}', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    needsMaintenance ? 'OVERDUE' : asset.status.toUpperCase(),
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _infoBit('Purchase Date', DateFormat('MMM dd, yyyy').format(asset.purchaseDate)),
                const Spacer(),
                _infoBit(
                  'Next Maintenance', 
                  asset.nextMaintenanceDate != null ? DateFormat('MMM dd, yyyy').format(asset.nextMaintenanceDate!) : 'N/A',
                  color: needsMaintenance ? Colors.red : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLogging ? null : () => _confirmLogMaintenance(context),
                icon: _isLogging ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.history_edu_rounded),
                label: const Text('LOG MAINTENANCE TASK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeProvider.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBit(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: color ?? ThemeProvider.primaryNavy)),
      ],
    );
  }

  Future<void> _confirmLogMaintenance(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Log Maintenance?'),
        content: const Text('This will record a maintenance task for today and schedule the next one for 6 months from now.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('LOG TASK')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLogging = true);
      try {
        final next = DateTime.now().add(const Duration(days: 180));
        await AssetService().logMaintenance(widget.asset.id, next);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maintenance logged successfully.')));
        }
      } finally {
        if (mounted) setState(() => _isLogging = false);
      }
    }
  }
}

class _AddAssetSheet extends StatefulWidget {
  final String societyId;
  const _AddAssetSheet({required this.societyId});

  @override
  State<_AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<_AddAssetSheet> {
  final _nameCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _category = 'Electronics';
  bool _isLoading = false;

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await AssetService().addAsset(AssetModel(
        id: '',
        societyId: widget.societyId,
        name: _nameCtrl.text.trim(),
        category: _category,
        status: 'active',
        purchaseDate: DateTime.now(),
        cost: double.tryParse(_costCtrl.text.trim()) ?? 0,
        location: _locationCtrl.text.trim(),
        nextMaintenanceDate: DateTime.now().add(const Duration(days: 180)),
      ));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Asset', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Asset Name (e.g. Generator 1)')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            items: ['Electronics', 'Plumbing', 'Gym', 'Common Area', 'Security', 'Machinery']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost')),
          const SizedBox(height: 12),
          TextField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Location (e.g. Basement)')),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: ThemeProvider.accentBlue, foregroundColor: Colors.white),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Asset'),
            ),
          ),
        ],
      ),
    );
  }
}
