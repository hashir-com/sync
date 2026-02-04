import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EventEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime startTime;
  final DateTime endTime;
  final String? imageUrl;
  final String? documentUrl;
  final String organizerId;
  final String organizerName;
  final List<String> attendees;
  final int maxAttendees;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? ticketPrice;
  final String status;
  final String? approvalReason;
  final String? rejectionReason;
  final Map<String, int> categoryCapacities;
  final Map<String, double> categoryPrices;
  final List<int> takenSeats;
  final int availableTickets;

  const EventEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    required this.startTime,
    required this.endTime,
    this.imageUrl,
    this.documentUrl,
    required this.organizerId,
    required this.organizerName,
    this.attendees = const [],
    required this.maxAttendees,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.ticketPrice,
    this.status = 'pending',
    this.approvalReason,
    this.rejectionReason,
    this.takenSeats = const [],
    this.categoryCapacities = const {'vip': 0, 'premium': 0, 'regular': 0},
    this.categoryPrices = const {'vip': 0.0, 'premium': 0.0, 'regular': 0.0},
    required this.availableTickets,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        location,
        latitude,
        longitude,
        startTime,
        endTime,
        imageUrl,
        documentUrl,
        organizerId,
        organizerName,
        attendees,
        maxAttendees,
        category,
        createdAt,
        updatedAt,
        ticketPrice,
        status,
        approvalReason,
        rejectionReason,
        takenSeats,
        categoryCapacities,
        categoryPrices,
        availableTickets,
      ];

  factory EventEntity.fromJson(Map<String, dynamic> json) {
    return EventEntity(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: (json['endTime'] as Timestamp).toDate(),
      imageUrl: json['imageUrl'],
      documentUrl: json['documentUrl'],
      organizerId: json['organizerId'],
      organizerName: json['organizerName'],
      attendees: List<String>.from(json['attendees'] ?? []),
      maxAttendees: (json['maxAttendees'] as num?)?.toInt() ?? 0,
      category: json['category'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      ticketPrice: json['ticketPrice'] != null ? (json['ticketPrice'] as num).toDouble() : null,
      status: json['status'],
      approvalReason: json['approvalReason'],
      rejectionReason: json['rejectionReason'],
      takenSeats: List<int>.from(json['takenSeats'] ?? []),
      categoryCapacities: Map<String, int>.from(
        (json['categoryCapacities'] ?? {'vip': 0, 'premium': 0, 'regular': 0})
            .map((key, value) => MapEntry(key, (value as num).toInt())),
      ),
      categoryPrices: Map<String, double>.from(
        json['categoryPrices'] ?? {'vip': 0.0, 'premium': 0.0, 'regular': 0.0},
      ),
      availableTickets: (json['availableTickets'] as num?)?.toInt() ?? (json['maxAttendees'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'imageUrl': imageUrl,
      'documentUrl': documentUrl,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'attendees': attendees,
      'maxAttendees': maxAttendees,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'ticketPrice': ticketPrice,
      'status': status,
      'approvalReason': approvalReason,
      'rejectionReason': rejectionReason,
      'takenSeats': takenSeats,
      'categoryCapacities': categoryCapacities,
      'categoryPrices': categoryPrices,
      'availableTickets': availableTickets,
    };
  }

    /// Event has started but not yet ended
  bool get hasStarted =>
      DateTime.now().isAfter(startTime) &&
      DateTime.now().isBefore(endTime);

  /// Event is completely over
  bool get hasEnded =>
      DateTime.now().isAfter(endTime);

  /// Event is upcoming
  bool get isUpcoming =>
      DateTime.now().isBefore(startTime);


  // Helper for formatted date
  String get formattedDate => DateFormat('d MMMM, yyyy').format(startTime);

  // Helper for formatted day and time
  String get formattedDayTime => DateFormat('EEEE, h:mm a').format(startTime);

  // Helper for formatted duration
  String get formattedDuration => '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}';

  // Helper for location subtitle
  String get locationSubtitle => location.contains(',') ? location.split(',').skip(1).join(',').trim() : 'Event location';

}