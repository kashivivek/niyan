import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/visitor_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/visitor_service.dart';
import 'package:myapp/services/sos_service.dart';
import 'package:myapp/models/sos_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/utils/currency_helper.dart'; // Just in case we need it later

class GateDashboardScreen extends StatefulWidget {
  const GateDashboardScreen({super.key});

  @override
  State<GateDashboardScreen> createState() => _GateDashboardScreenState();
}

class _GateDashboardScreenState extends State<GateDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appMode = Provider.of<AppModeProvider>(context);
    final society = appMode.activeSociety;

    if (society == null) {
      return const Scaffold(
        body: Center(child: Text('No society selected')),
      );
    }

    return Scaffold(
      backgroundColor: ThemeProvider.primaryNavy,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
              children: [
                _buildGuardHeader(society.name),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                  children: [
                    // Global SOS banner is now in MainNavigationScreen
                    const SizedBox(height: 12),
                        TabBar(
                          controller: _tabController,
                          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 14),
                          labelColor: ThemeProvider.primaryNavy,
                          unselectedLabelColor: Colors.grey.shade400,
                          indicatorColor: ThemeProvider.accentTeal,
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(text: 'ALERTS'),
                            Tab(text: 'INSIDE'),
                            Tab(text: 'LOG'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _AlertsTab(societyId: society.id),
                              _InsideTab(societyId: society.id),
                              _LogTab(societyId: society.id),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
            ),
          ),
          if (_isScanning)
            Positioned.fill(
              child: Container(
                color: Theme.of(context).colorScheme.primary,
                child: Stack(
                  children: [
                    MobileScanner(
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final String? code = barcodes.first.rawValue;
                          if (code != null) {
                            setState(() => _isScanning = false);
                            _handleScannedCode(code, society.id);
                          }
                        }
                      },
                    ),
                    // Scanner Overlay
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: ThemeProvider.accentTeal, width: 4),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 20,
                      child: IconButton(
                        icon: Icon(Icons.close_rounded, color: Theme.of(context).cardColor, size: 32),
                        onPressed: () => setState(() => _isScanning = false),
                      ),
                    ),
                    Positioned(
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Scan Resident or Visitor QR',
                          style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isScanning ? null : Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: 'walkin',
              onPressed: () => _showWalkInSheet(context, society.id),
              backgroundColor: Colors.white,
              child: Icon(Icons.person_add_alt_1_rounded, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'scan',
              onPressed: () => setState(() => _isScanning = true),
              backgroundColor: ThemeProvider.accentTeal,
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
              label: Text('SCAN QR', style: GoogleFonts.outfit(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardHeader(String societyName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.security_rounded, color: ThemeProvider.accentTeal, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gate Operations', style: GoogleFonts.outfit(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold, fontSize: 22)),
              ],
            ),
          ),
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, _) => Text(
              DateFormat('HH:mm').format(DateTime.now()),
              style: GoogleFonts.outfit(color: Theme.of(context).cardColor, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String societyId) {
    final visitorService = context.read<VisitorService>();
    return StreamBuilder<List<VisitorModel>>(
      stream: visitorService.getCurrentlyInsideVisitors(societyId),
      builder: (context, snap) {
        final inside = snap.data?.length ?? 0;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _StatTile(label: 'INSIDE', value: '$inside', icon: Icons.group_rounded, color: ThemeProvider.accentTeal),
              const SizedBox(width: 16),
              _StatTile(label: 'TODAY', value: DateFormat('MMM d').format(DateTime.now()), icon: Icons.calendar_today_rounded, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleScannedCode(String code, String societyId) async {
    // 1. Try to see if it's a resident (UID)
    final db = context.read<DatabaseService>();
    final visitorService = context.read<VisitorService>();
    final guard = context.read<UserModel?>();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Try resident lookup
      final resident = await db.getUser(code);
      if (mounted) Navigator.pop(context); // Remove loading

      if (resident != null) {
        _showResidentInfo(resident, societyId);
        return;
      }

      // 2. Try to see if it's a pre-approved visitor (QR Code Token)
      final visitor = await visitorService.getVisitorByQrCode(code);
      if (visitor != null && visitor.societyId == societyId) {
        if (visitor.status == VisitorStatus.pre_approved) {
          await visitorService.checkIn(
            visitorId: visitor.id,
            guardId: guard?.uid ?? '',
            guardName: guard?.name ?? 'Guard',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Visitor ${visitor.visitorName} Checked In!')),
            );
          }
        } else {
          _showError('Visitor is already ${visitor.status.label}');
        }
        return;
      }

      _showError('Invalid or Unknown QR Code');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError('Error processing scan: $e');
    }
  }

  void _showResidentInfo(UserModel resident, String societyId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: ThemeProvider.accentTeal.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, size: 40, color: ThemeProvider.accentTeal),
            ),
            const SizedBox(height: 16),
            Text(resident.name ?? 'Resident', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            Text('Resident verified', style: GoogleFonts.inter(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: ThemeProvider.primaryNavy, foregroundColor: Colors.white),
                child: const Text('ALLOW ENTRY'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showWalkInSheet(BuildContext context, String societyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalkInBottomSheet(societyId: societyId),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
                Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsTab extends StatelessWidget {
  final String societyId;
  const _AlertsTab({required this.societyId});

  @override
  Widget build(BuildContext context) {
    final visitorService = context.read<VisitorService>();
    return StreamBuilder<List<VisitorModel>>(
      stream: visitorService.getArrivedVisitors(societyId),
      builder: (context, snap) {
        final visitors = snap.data ?? [];
        if (visitors.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.green.shade100),
                const SizedBox(height: 16),
                Text('No visitors waiting', style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: visitors.length,
          itemBuilder: (ctx, i) => _VisitorAlertCard(visitor: visitors[i], societyId: societyId),
        );
      },
    );
  }
}

class _InsideTab extends StatelessWidget {
  final String societyId;
  const _InsideTab({required this.societyId});

  @override
  Widget build(BuildContext context) {
    final visitorService = context.read<VisitorService>();
    return StreamBuilder<List<VisitorModel>>(
      stream: visitorService.getCurrentlyInsideVisitors(societyId),
      builder: (context, snap) {
        final visitors = snap.data ?? [];
        if (visitors.isEmpty) {
          return Center(
            child: Text('Premises are clear.', style: GoogleFonts.outfit(color: Colors.grey.shade400)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: visitors.length,
          itemBuilder: (ctx, i) => _InsideVisitorCard(visitor: visitors[i]),
        );
      },
    );
  }
}

class _LogTab extends StatelessWidget {
  final String societyId;
  const _LogTab({required this.societyId});

  @override
  Widget build(BuildContext context) {
    final visitorService = context.read<VisitorService>();
    return StreamBuilder<List<VisitorModel>>(
      stream: visitorService.getVisitorsBySociety(societyId, date: DateTime.now()),
      builder: (context, snap) {
        final visitors = snap.data ?? [];
        if (visitors.isEmpty) {
          return Center(
            child: Text('No log entries for today.', style: GoogleFonts.outfit(color: Colors.grey.shade400)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: visitors.length,
          itemBuilder: (ctx, i) => _LogCard(visitor: visitors[i]),
        );
      },
    );
  }
}

class _VisitorAlertCard extends StatefulWidget {
  final VisitorModel visitor;
  final String societyId;
  const _VisitorAlertCard({required this.visitor, required this.societyId});

  @override
  State<_VisitorAlertCard> createState() => _VisitorAlertCardState();
}

class _VisitorAlertCardState extends State<_VisitorAlertCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.visitor;
    final visitorService = context.read<VisitorService>();
    final user = context.read<UserModel?>();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(color: ThemeProvider.accentTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Text(v.type.icon, style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.visitorName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
                      Text('Unit ${v.unitNumber} · ${v.residentName}', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                if (v.isPreApproved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('PRE-APPROVED', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _loading ? null : () => _reject(visitorService, user),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('REJECT'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _checkIn(visitorService, user),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('CHECK IN'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reject(VisitorService service, UserModel? guard) async {
    setState(() => _loading = true);
    await service.rejectVisitor(visitorId: widget.visitor.id, guardId: guard?.uid ?? '', guardName: guard?.name ?? 'Guard', reason: 'Guard rejected entry');
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _checkIn(VisitorService service, UserModel? guard) async {
    setState(() => _loading = true);
    await service.checkIn(visitorId: widget.visitor.id, guardId: guard?.uid ?? '', guardName: guard?.name ?? 'Guard');
    if (mounted) setState(() => _loading = false);
  }
}

class _InsideVisitorCard extends StatelessWidget {
  final VisitorModel visitor;
  const _InsideVisitorCard({required this.visitor});

  @override
  Widget build(BuildContext context) {
    final visitorService = context.read<VisitorService>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Text(visitor.type.icon, style: const TextStyle(fontSize: 24)),
        title: Text(visitor.visitorName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        subtitle: Text('Unit ${visitor.unitNumber}'),
        trailing: TextButton(
          onPressed: () => visitorService.checkOut(visitor.id),
          child: const Text('CHECK OUT', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final VisitorModel visitor;
  const _LogCard({required this.visitor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text(visitor.type.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visitor.visitorName, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                Text('Unit ${visitor.unitNumber} · ${visitor.status.label}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkInBottomSheet extends StatefulWidget {
  final String societyId;
  const _WalkInBottomSheet({required this.societyId});

  @override
  State<_WalkInBottomSheet> createState() => _WalkInBottomSheetState();
}

class _WalkInBottomSheetState extends State<_WalkInBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  VisitorType _type = VisitorType.guest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manual Entry', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Visitor Name')),
            const SizedBox(height: 16),
            TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
            const SizedBox(height: 16),
            TextFormField(controller: _unitCtrl, decoration: const InputDecoration(labelText: 'Unit Number')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('SUBMIT ENTRY'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    final service = context.read<VisitorService>();
    final user = context.read<UserModel?>();
    await service.createWalkIn(
      societyId: widget.societyId,
      unitId: 'temp',
      propertyId: widget.societyId,
      residentId: 'temp',
      residentName: 'temp',
      unitNumber: _unitCtrl.text,
      visitorName: _nameCtrl.text,
      visitorPhone: _phoneCtrl.text,
      type: _type,
      guardId: user?.uid ?? '',
      guardName: user?.name ?? 'Guard',
    );
    if (mounted) Navigator.pop(context);
  }
}
