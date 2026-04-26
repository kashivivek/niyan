import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/models/rent_record_model.dart';
import 'package:myapp/models/rent_status.dart';
import 'package:myapp/services/database_service.dart';

class RentTrackerScreen extends StatefulWidget {
  final TenantModel tenant;

  const RentTrackerScreen({super.key, required this.tenant});

  @override
  State<RentTrackerScreen> createState() => _RentTrackerScreenState();
}

class _RentTrackerScreenState extends State<RentTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Rent Tracker - ${widget.tenant.name}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<RentRecordModel>>(
        stream: databaseService.getRentRecordsForTenant(widget.tenant.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No rent records found.'));
          }
          final rentRecords = snapshot.data!;
          return ListView.builder(
            itemCount: rentRecords.length,
            itemBuilder: (context, index) {
              final record = rentRecords[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(DateFormat('MMMM yyyy').format(DateFormat('yyyy-MM').parse(record.month)), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: Text('Amount: \u20b9${record.amount.toStringAsFixed(2)}'),
                  trailing: Text(record.status.toString().split('.').last, style: TextStyle(color: _getStatusColor(record.status))),
                  onTap: () => _showUpdateStatusDialog(record),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(RentStatus status) {
    switch (status) {
      case RentStatus.paid:
        return Colors.green;
      case RentStatus.pending:
        return Colors.orange;
      case RentStatus.partial:
        return Colors.blue;
    }
  }

  void _showUpdateStatusDialog(RentRecordModel record) {
    showDialog(
      context: context,
      builder: (context) {
        RentStatus? selectedStatus = record.status;
        final paymentMethodController = TextEditingController(text: record.paymentMethod);
        final notesController = TextEditingController(text: record.notes);

        return AlertDialog(
          title: const Text('Update Rent Status'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<RentStatus>(
                    value: selectedStatus,
                    onChanged: (RentStatus? newValue) {
                      setState(() {
                        selectedStatus = newValue;
                      });
                    },
                    items: RentStatus.values.map((RentStatus status) {
                      return DropdownMenuItem<RentStatus>(
                        value: status,
                        child: Text(status.toString().split('.').last),
                      );
                    }).toList(),
                  ),
                  if (selectedStatus == RentStatus.paid || selectedStatus == RentStatus.partial) ...[
                    TextField(
                      controller: paymentMethodController,
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                    ),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final updatedRecord = record.copyWith(
                  status: selectedStatus,
                  paymentMethod: paymentMethodController.text,
                  notes: notesController.text,
                  paymentDate: (selectedStatus == RentStatus.paid) ? DateTime.now() : record.paymentDate, // Preserve existing date unless fully paid now
                );
                final databaseService = Provider.of<DatabaseService>(context, listen: false);
                databaseService.updateRentRecord(updatedRecord);
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
