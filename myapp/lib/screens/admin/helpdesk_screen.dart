import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/ticket_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/admin_service.dart';

class HelpdeskScreen extends StatefulWidget {
  const HelpdeskScreen({super.key});

  @override
  State<HelpdeskScreen> createState() => _HelpdeskScreenState();
}

class _HelpdeskScreenState extends State<HelpdeskScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final appMode = Provider.of<AppModeProvider>(context);
    final adminService = Provider.of<AdminService>(context, listen: false);

    if (user == null || appMode.activeSociety == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isResident = true; // In a full implementation, check role
    final stream = isResident
        ? adminService.getTicketsForResident(user.uid)
        : adminService.getTicketsForSociety(appMode.activeSociety!.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Helpdesk', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w400, fontSize: 13),
          labelColor: ThemeProvider.accentBlue,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: ThemeProvider.accentBlue,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTicketSheet(context, user, appMode.activeSociety!.id),
        backgroundColor: ThemeProvider.accentBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('New Ticket', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<TicketModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allTickets = snapshot.data ?? [];
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTicketList(allTickets.where((t) => t.status == TicketStatus.open || t.status == TicketStatus.in_progress).toList()),
              _buildTicketList(allTickets.where((t) => t.status == TicketStatus.resolved || t.status == TicketStatus.closed).toList()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTicketList(List<TicketModel> tickets) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No tickets found', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _TicketCard(ticket: ticket);
      },
    );
  }

  void _showCreateTicketSheet(BuildContext context, UserModel user, String societyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateTicketSheet(societyId: societyId, residentId: user.uid, residentName: user.name ?? 'Resident'),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(ticket.status);
    final priorityColor = _getPriorityColor(ticket.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket.status.label.toUpperCase(),
                  style: GoogleFonts.outfit(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${ticket.priority.label.toUpperCase()} PRIORITY',
                  style: GoogleFonts.outfit(fontSize: 10, color: priorityColor, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, HH:mm').format(ticket.createdAt),
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ticket.title,
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy),
          ),
          const SizedBox(height: 4),
          Text(
            ticket.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.category_outlined, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(ticket.category.label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
              const Spacer(),
              if (ticket.assignedToName != null) ...[
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(ticket.assignedToName!, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
              ] else
                Text('Unassigned', style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade400)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open: return Colors.orange;
      case TicketStatus.in_progress: return Colors.blue;
      case TicketStatus.resolved: return Colors.green;
      case TicketStatus.closed: return Colors.grey;
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low: return Colors.green;
      case TicketPriority.medium: return Colors.blue;
      case TicketPriority.high: return Colors.orange;
      case TicketPriority.urgent: return Colors.red;
    }
  }
}

class _CreateTicketSheet extends StatefulWidget {
  final String societyId;
  final String residentId;
  final String residentName;

  const _CreateTicketSheet({
    required this.societyId,
    required this.residentId,
    required this.residentName,
  });

  @override
  State<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends State<_CreateTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TicketCategory _category = TicketCategory.plumbing;
  TicketPriority _priority = TicketPriority.medium;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    
    final adminService = context.read<AdminService>();
    try {
      await adminService.createTicket(TicketModel(
        id: '',
        societyId: widget.societyId,
        unitId: 'Unit-Placeholder', // Replace with actual unit
        residentId: widget.residentId,
        residentName: widget.residentName,
        unitNumber: '101', // Replace
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        priority: _priority,
        createdAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 100),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Raise a Ticket', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: ThemeProvider.primaryNavy)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Issue Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TicketCategory>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: TicketCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TicketPriority>(
              value: _priority,
              decoration: InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: TicketPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeProvider.accentBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Submit Ticket', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
