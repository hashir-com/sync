import 'dart:io';

class EditEventFormData {
  final String title;
  final String description;
  final String location;
  final String category;
  final int maxAttendees;
  final double? ticketPrice;
  final DateTime? startTime;
  final DateTime? endTime;
  final File? newCoverImage;
  final File? newDocument;
  final String? existingImageUrl;
  final String? existingDocumentUrl;
  final double? latitude;
  final double? longitude;

  EditEventFormData({
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.maxAttendees,
    this.ticketPrice,
    this.startTime,
    this.endTime,
    this.newCoverImage,
    this.newDocument,
    this.existingImageUrl,
    this.existingDocumentUrl,
    this.latitude,
    this.longitude,
  });

  EditEventFormData copyWith({
    String? title,
    String? description,
    String? location,
    String? category,
    int? maxAttendees,
    double? ticketPrice,
    DateTime? startTime,
    DateTime? endTime,
    File? newCoverImage,
    File? newDocument,
    String? existingImageUrl,
    String? existingDocumentUrl,
    double? latitude,
    double? longitude,
    bool clearCoverImage = false,
    bool clearDocument = false,
  }) {
    return EditEventFormData(
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      category: category ?? this.category,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      newCoverImage: clearCoverImage ? null : (newCoverImage ?? this.newCoverImage),
      newDocument: clearDocument ? null : (newDocument ?? this.newDocument),
      existingImageUrl: clearCoverImage ? null : (existingImageUrl ?? this.existingImageUrl),
      existingDocumentUrl: clearDocument ? null : (existingDocumentUrl ?? this.existingDocumentUrl),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class EditEventSubmissionState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  EditEventSubmissionState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  EditEventSubmissionState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return EditEventSubmissionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}