import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/ticket_model.dart';
import 'package:myapp/models/amenity_model.dart';
import 'package:myapp/models/lease_model.dart';
import 'package:myapp/models/parking_model.dart';
import 'dart:developer' as developer;

/// Service for Administrative Workflows: Helpdesk, Amenities, Leases, and Parking.
class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──────────────────────────────────────────────
  // HELPDESK / TICKETS
  // ──────────────────────────────────────────────

  Stream<List<TicketModel>> getTicketsForSociety(String societyId) {
    return _db
        .collection('tickets')
        .where('societyId', isEqualTo: societyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TicketModel.fromFirestore(d)).toList());
  }

  Stream<List<TicketModel>> getTicketsForResident(String residentId) {
    return _db
        .collection('tickets')
        .where('residentId', isEqualTo: residentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TicketModel.fromFirestore(d)).toList());
  }

  Future<String> createTicket(TicketModel ticket) async {
    // -------------------------------------------------------------
    // [AI Feature Placeholder] Smart Helpdesk Routing
    // In a real implementation, this would call a Firebase Extension 
    // for OpenAI or a Cloud Function. We mock the categorization here.
    // -------------------------------------------------------------
    TicketCategory finalCategory = ticket.category;
    TicketPriority finalPriority = ticket.priority;

    final lowerDesc = ticket.description.toLowerCase();
    final lowerTitle = ticket.title.toLowerCase();
    final combinedText = '$lowerTitle $lowerDesc';

    if (combinedText.contains('leak') || combinedText.contains('pipe') || combinedText.contains('water')) {
      finalCategory = TicketCategory.plumbing;
      if (combinedText.contains('urgent') || combinedText.contains('flooding')) {
        finalPriority = TicketPriority.high;
      }
    } else if (combinedText.contains('power') || combinedText.contains('electricity') || combinedText.contains('wire')) {
      finalCategory = TicketCategory.electrical;
      finalPriority = TicketPriority.high;
    } else if (combinedText.contains('clean') || combinedText.contains('garbage') || combinedText.contains('trash')) {
      finalCategory = TicketCategory.cleaning;
    }

    final ref = _db.collection('tickets').doc();
    final newTicket = TicketModel(
      id: ref.id,
      societyId: ticket.societyId,
      unitId: ticket.unitId,
      residentId: ticket.residentId,
      residentName: ticket.residentName,
      unitNumber: ticket.unitNumber,
      title: ticket.title,
      description: ticket.description,
      category: finalCategory,
      priority: finalPriority,
      status: TicketStatus.open,
      createdAt: DateTime.now(),
    );
    await ref.set(newTicket.toFirestore());
    developer.log('Ticket created: ${ref.id}');
    return ref.id;
  }

  Future<void> updateTicketStatus(String ticketId, TicketStatus status, {String? resolutionNotes}) {
    final updateData = <String, dynamic>{
      'status': status.toString(),
      'updatedAt': Timestamp.now(),
    };
    if (status == TicketStatus.resolved || status == TicketStatus.closed) {
      updateData['resolvedAt'] = Timestamp.now();
    }
    if (resolutionNotes != null) {
      updateData['resolutionNotes'] = resolutionNotes;
    }
    return _db.collection('tickets').doc(ticketId).update(updateData);
  }

  // ──────────────────────────────────────────────
  // AMENITIES & BOOKINGS
  // ──────────────────────────────────────────────

  Stream<List<AmenityModel>> getAmenities(String societyId) {
    return _db
        .collection('amenities')
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AmenityModel.fromFirestore(d)).toList());
  }

  Future<String> addAmenity(AmenityModel amenity) async {
    final ref = _db.collection('amenities').doc();
    final newAmenity = AmenityModel(
      id: ref.id,
      societyId: amenity.societyId,
      name: amenity.name,
      description: amenity.description,
      icon: amenity.icon,
      status: amenity.status,
      hourlyRate: amenity.hourlyRate,
      maxCapacity: amenity.maxCapacity,
      openHours: amenity.openHours,
    );
    await ref.set(newAmenity.toFirestore());
    return ref.id;
  }

  Stream<List<AmenityBookingModel>> getBookingsForAmenity(String amenityId) {
    return _db
        .collection('amenityBookings')
        .where('amenityId', isEqualTo: amenityId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AmenityBookingModel.fromFirestore(d)).toList());
  }

  Stream<List<AmenityBookingModel>> getBookingsForResident(String residentId) {
    return _db
        .collection('amenityBookings')
        .where('residentId', isEqualTo: residentId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AmenityBookingModel.fromFirestore(d)).toList());
  }

  Future<String> createAmenityBooking(AmenityBookingModel booking) async {
    final ref = _db.collection('amenityBookings').doc();
    final newBooking = AmenityBookingModel(
      id: ref.id,
      societyId: booking.societyId,
      amenityId: booking.amenityId,
      amenityName: booking.amenityName,
      residentId: booking.residentId,
      residentName: booking.residentName,
      unitNumber: booking.unitNumber,
      startTime: booking.startTime,
      endTime: booking.endTime,
      status: booking.status,
      totalCost: booking.totalCost,
      createdAt: DateTime.now(),
    );
    await ref.set(newBooking.toFirestore());
    return ref.id;
  }

  // ──────────────────────────────────────────────
  // LEASE TRACKING
  // ──────────────────────────────────────────────

  Stream<List<LeaseModel>> getLeasesForSociety(String societyId) {
    return _db
        .collection('leases')
        .where('societyId', isEqualTo: societyId)
        .orderBy('endDate', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => LeaseModel.fromFirestore(d)).toList());
  }

  Future<String> addLease(LeaseModel lease) async {
    final ref = _db.collection('leases').doc();
    final newLease = LeaseModel(
      id: ref.id,
      societyId: lease.societyId,
      propertyId: lease.propertyId,
      unitId: lease.unitId,
      unitNumber: lease.unitNumber,
      tenantId: lease.tenantId,
      tenantName: lease.tenantName,
      ownerId: lease.ownerId,
      startDate: lease.startDate,
      endDate: lease.endDate,
      monthlyRent: lease.monthlyRent,
      securityDeposit: lease.securityDeposit,
      status: lease.status,
      documentUrl: lease.documentUrl,
      notes: lease.notes,
      createdAt: DateTime.now(),
    );
    await ref.set(newLease.toFirestore());
    return ref.id;
  }

  // ──────────────────────────────────────────────
  // PARKING MANAGEMENT
  // ──────────────────────────────────────────────

  Stream<List<ParkingSpotModel>> getParkingSpots(String societyId) {
    return _db
        .collection('parkingSpots')
        .where('societyId', isEqualTo: societyId)
        .orderBy('spotNumber')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ParkingSpotModel.fromFirestore(d)).toList());
  }

  Future<String> addParkingSpot(ParkingSpotModel spot) async {
    final ref = _db.collection('parkingSpots').doc();
    final newSpot = ParkingSpotModel(
      id: ref.id,
      societyId: spot.societyId,
      spotNumber: spot.spotNumber,
      blockOrLevel: spot.blockOrLevel,
      type: spot.type,
      status: spot.status,
    );
    await ref.set(newSpot.toFirestore());
    return ref.id;
  }

  Future<void> assignParkingSpot({
    required String spotId,
    required String unitId,
    required String unitNumber,
    required String residentId,
    required String residentName,
    String? vehicleNumber,
  }) {
    return _db.collection('parkingSpots').doc(spotId).update({
      'status': ParkingSpotStatus.occupied.toString(),
      'assignedUnitId': unitId,
      'assignedUnitNumber': unitNumber,
      'assignedResidentId': residentId,
      'assignedResidentName': residentName,
      'vehicleNumber': vehicleNumber,
      'assignmentDate': Timestamp.now(),
    });
  }

  Future<void> unassignParkingSpot(String spotId) {
    return _db.collection('parkingSpots').doc(spotId).update({
      'status': ParkingSpotStatus.available.toString(),
      'assignedUnitId': null,
      'assignedUnitNumber': null,
      'assignedResidentId': null,
      'assignedResidentName': null,
      'vehicleNumber': null,
      'assignmentDate': null,
    });
  }
}
