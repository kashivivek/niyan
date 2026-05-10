import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/parking_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/admin_service.dart';

class ParkingManagementScreen extends StatelessWidget {
  const ParkingManagementScreen({super.key});

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
        title: Text('Parking Management', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<ParkingSpotModel>>(
        stream: adminService.getParkingSpots(appMode.activeSociety!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final spots = snapshot.data ?? [];
          
          if (spots.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_parking_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No parking spots configured', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: spots.length,
            itemBuilder: (context, index) {
              final spot = spots[index];
              return _ParkingSpotCard(spot: spot);
            },
          );
        },
      ),
    );
  }
}

class _ParkingSpotCard extends StatelessWidget {
  final ParkingSpotModel spot;
  const _ParkingSpotCard({required this.spot});

  @override
  Widget build(BuildContext context) {
    final statusColor = spot.status == ParkingSpotStatus.available ? Colors.green : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: ThemeProvider.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(spot.type == ParkingSpotType.car ? '🚗' : '🏍️', style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${spot.blockOrLevel} - ${spot.spotNumber}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
                if (spot.assignedResidentName != null) ...[
                  const SizedBox(height: 4),
                  Text('Assigned to: ${spot.assignedResidentName}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                  Text('Unit: ${spot.assignedUnitNumber}  |  Vehicle: ${spot.vehicleNumber ?? "N/A"}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                ] else ...[
                  const SizedBox(height: 4),
                  Text('Unassigned', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                ]
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              spot.status.toString().split('.').last.toUpperCase(),
              style: GoogleFonts.outfit(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
