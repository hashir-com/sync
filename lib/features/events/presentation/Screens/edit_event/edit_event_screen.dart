import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/util/theme_util.dart';
import 'package:sync_event/features/events/domain/entities/event_entity.dart';
import 'providers/edit_event_provider.dart';
import 'widgets/edit_event_form.dart';
import 'validators/edit_event_validator.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final EventEntity event;

  const EditEventScreen({super.key, required this.event});

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editEventFormProvider.notifier).initialize(widget.event);
    });
  }

  Future<Map<String, dynamic>?> _pickLocation() async {
    try {
      final result = await context.push<Map<String, dynamic>>(
        '/location-picker',
      );
      return result;
    } catch (e) {
      if (mounted) {
        final isDark = ThemeUtils.isDark(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error opening location picker: $e',
              style: AppTextStyles.bodyMedium(isDark: true)
                  .copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.getError(isDark),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            margin: EdgeInsets.all(AppSizes.paddingLarge),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _handleUpdate() async {
    final formData = ref.read(editEventFormProvider);
    if (formData == null) return;

    // Validate all fields
    final validations = [
      EditEventValidator.validateTitle(formData.title),
      EditEventValidator.validateDescription(formData.description),
      EditEventValidator.validateCoverImage(
        formData.newCoverImage != null,
        formData.existingImageUrl != null,
      ),
      EditEventValidator.validateLocation(
        formData.location,
        formData.latitude,
        formData.longitude,
      ),
      EditEventValidator.validateDateTime(formData.startTime, formData.endTime),
      EditEventValidator.validateMaxAttendees(
        formData.maxAttendees,
        widget.event.attendees.length,
      ),
      EditEventValidator.validateTicketPrice(formData.ticketPrice),
      EditEventValidator.validateCategory(formData.category),
    ];

    for (final validation in validations) {
      if (!validation.isValid) {
        _showError(validation.errorMessage!);
        return;
      }
    }

    // Create updated event
    final updatedEvent = EventEntity(
      id: widget.event.id,
      title: formData.title.trim(),
      description: formData.description.trim(),
      location: formData.location.trim(),
      startTime: formData.startTime!,
      endTime: formData.endTime!,
      organizerId: widget.event.organizerId,
      organizerName: widget.event.organizerName,
      attendees: widget.event.attendees,
      maxAttendees: formData.maxAttendees,
      category: formData.category,
      latitude: formData.latitude ?? widget.event.latitude,
      longitude: formData.longitude ?? widget.event.longitude,
      createdAt: widget.event.createdAt,
      updatedAt: DateTime.now(),
      ticketPrice: formData.ticketPrice,
      imageUrl: formData.existingImageUrl,
      documentUrl: formData.existingDocumentUrl,
      status: 'pending',
      approvalReason: null,
      rejectionReason: null, availableTickets: 0,
    );

    // Submit update
    await ref
        .read(editEventSubmissionProvider.notifier)
        .updateEvent(
          updatedEvent,
          coverFile: formData.newCoverImage,
          docFile: formData.newDocument,
        );
  }

  void _showError(String message) {
    final isDark = ThemeUtils.isDark(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium(isDark: true)
              .copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.getError(isDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        margin: EdgeInsets.all(AppSizes.paddingLarge),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formData = ref.watch(editEventFormProvider);
    final submissionState = ref.watch(editEventSubmissionProvider);
    final isDark = ThemeUtils.isDark(context);

    ref.listen(editEventSubmissionProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Event updated and submitted for review!',
              style: AppTextStyles.bodyMedium(isDark: true)
                  .copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.getSuccess(isDark),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            margin: EdgeInsets.all(AppSizes.paddingLarge),
          ),
        );
        context.pop();
      } else if (next.error != null) {
        _showError('Failed to update event: ${next.error}');
      }
    });

    if (formData == null) {
      return Scaffold(
        backgroundColor: AppColors.getBackground(isDark),
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.getPrimary(isDark),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: AppColors.getTextPrimary(isDark),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Event',
          style: AppTextStyles.titleLarge(isDark: isDark),
        ),
      ),
      body: EditEventForm(
        event: widget.event,
        formData: formData,
        isLoading: submissionState.isLoading,
        onUpdate: _handleUpdate,
        pickLocation: _pickLocation,
      ),
    );
  }
}