import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/models/rent_record_model.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/tenant_model.dart'; // Import TenantModel

class RentCollectionScreen extends StatelessWidget {
  const RentCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rent Collection'),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<RentRecordModel>>(
              stream: databaseService.getAllRentRecords(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No rent records found.'));
                }

                final rentRecords = snapshot.data!;

                return ListView.builder(
                  itemCount: rentRecords.length,
                  itemBuilder: (context, index) {
                    final record = rentRecords[index];
                    return FutureBuilder<TenantModel?>(
                      future: databaseService.getTenant(record.tenantId).first,
                      builder: (context, tenantSnapshot) {
                        if (tenantSnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(title: Text('Loading tenant...'));
                        }

                        final tenantName = tenantSnapshot.data?.name ?? 'Unknown Tenant';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text('Tenant: $tenantName'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Property: ${record.propertyId} - Unit: ${record.unitId}'),
                                Text('Month: ${record.month}'),
                                if (record.paymentDate != null)
                                  Text('Payment Date: ${DateFormat.yMMMd().format(record.paymentDate!)}')
                              ],
                            ),
                            trailing: Text(
                              '\$${record.amount.toStringAsFixed(2)}\n${record.status.toString().split('.').last}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: record.status.toString().split('.').last == 'paid' ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
