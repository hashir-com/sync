// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/util/theme_util.dart';
import '../providers/edit_event_provider.dart';
import '../state/edit_event_state.dart';
import 'edit_event_option_tile.dart';
import 'edit_event_dialogs.dart';

class EditTitleField extends ConsumerWidget {
  final EditEventFormData formData;

  const EditTitleField({super.key, required this.formData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ThemeUtils.isDark(context);

    return TextFormField(
      initialValue: formData.title,
      onChanged: (value) {
        ref
            .read(editEventFormProvider.notifier)
            .updateFormData(formData.copyWith(title: value));
      },
      decoration: InputDecoration(
        hintText: 'Add title...',
        hintStyle: AppTextStyles.headingSmall(isDark: isDark).copyWith(
          color: AppColors.getTextSecondary(isDark).withOpacity(0.5),
          fontSize: AppSizes.fontXl,
          fontWeight: FontWeight.w400,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      style: AppTextStyles.headingSmall(isDark: isDark).copyWith(
        fontSize: AppSizes.fontXl,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class EditDescriptionTile extends ConsumerWidget {
  final EditEventFormData formData;

  const EditDescriptionTile({super.key, required this.formData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ThemeUtils.isDark(context);

    return EditEventOptionTile(
      icon: Icons.description_outlined,
      label: formData.description.isEmpty
          ? 'Add Description...'
          : formData.description,
      iconColor: AppColors.getTextSecondary(isDark),
      isRequired: true,
      onTap: () => EditDescriptionDialog.show(context, ref, formData),
    );
  }
}

class EditCoverTile extends ConsumerWidget {
  final EditEventFormData formData;

  const EditCoverTile({super.key, required this.formData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ThemeUtils.isDark(context);
    final hasImage =
        formData.newCoverImage != null || formData.existingImageUrl != null;

    return EditEventOptionTile(
      icon: Icons.add_photo_alternate_outlined,
      label: hasImage ? 'Cover Selected' : 'Add Cover photo',
      iconColor: AppColors.success,
      isRequired: true,
      trailing: hasImage
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (formData.newCoverImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    child: Image.file(
                      formData.newCoverImage!,
                      width: AppSizes.avatarMedium,
                      height: AppSizes.avatarMedium,
                      fit: BoxFit.cover,
                    ),
                  ),
                SizedBox(width: AppSizes.spacingSmall),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.getError(isDark),
                  ),
                  onPressed: () {
                    ref
                        .read(editEventFormProvider.notifier)
                        .updateFormData(
                          formData.copyWith(clearCoverImage: true),
                        );
                  },
                  iconSize: AppSizes.iconSmall,
                ),
              ],
            )
          : null,
      onTap: () => _pickImage(ref),
    );
  }

  Future<void> _pickImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      ref
          .read(editEventFormProvider.notifier)
          .updateFormData(
            formData.copyWith(newCoverImage: File(pickedFile.path)),
          );
    }
  }
}

class EditLocationTile extends ConsumerWidget {
  final EditEventFormData formData;
  final Future<Map<String, dynamic>?> Function() pickLocation;

  const EditLocationTile({
    super.key,
    required this.formData,
    required this.pickLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ThemeUtils.isDark(context);

    return EditEventOptionTile(
      key: ValueKey(formData.location),
      icon: Icons.location_on_outlined,
      label: formData.location.isEmpty ? 'Add Location' : formData.location,
      iconColor: AppColors.info,
      isRequired: true,
      onTap: () async {
        final editNotifier = ref.read(editEventFormProvider.notifier);
        final result = await pickLocation();

        if (result != null) {
          try {
            final address = result['address'] as String?;
            final latitude = (result['latitude'] as num?)?.toDouble();
            final longitude = (result['longitude'] as num?)?.toDouble();

            if (address != null && latitude != null && longitude != null) {
              editNotifier.updateFormData(
                formData.copyWith(
                  location: address,
                  latitude: latitude,
                  longitude: longitude,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error selecting location: $e',
                    style: AppTextStyles.bodyMedium(isDark: true)
                        .copyWith(color: Colors.white),
                  ),
                  backgroundColor: AppColors.getError(isDark),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                ),
              );
            }
          }
        }
      },
    );
  }
}

class EditDateTimeTile extends ConsumerWidget {
  final EditEventFormData formData;

  const EditDateTimeTile({super.key, required this.formData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startText = formData.startTime != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(formData.startTime!)
        : 'Start';
    final endText = formData.endTime != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(formData.endTime!)
        : 'End';

    return EditEventOptionTile(
      icon: Icons.calendar_today_outlined,
      label: formData.startTime == null && formData.endTime == null
          ? 'Date and Time'
          : '$startText - $endText',
      iconColor: AppColors.info,
      isRequired: true,
      onTap: () => EditDateTimeDialog.show(context, ref, formData),
    );
  }
}

class EditCapacityTile extends ConsumerWidget {
  final EditEventFormData formData;
  final int minAttendees;

  const EditCapacityTile({
    super.key,
    required this.formData,
    required this.minAttendees,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EditEventOptionTile(
      icon: Icons.people_outline_rounded,
      label: formData.maxAttendees <= 0
          ? 'Max Attendees'
          : 'Max: ${formData.maxAttendees} attendees',
      iconColor: AppColors.warning,
      isRequired: true,
      onTap: () =>
          EditCapacityDialog.show(context, ref, formData, minAttendees),
    );
  }
}

class EditPriceTile extends ConsumerWidget {
  final EditEventFormData formData;

  const EditPriceTile({super.key, required this.formData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = formData.ticketPrice ?? 0;

    return EditEventOptionTile(
      icon: Icons.confirmation_number_outlined,
      label: price == 0
          ? 'Free Event'
          : 'Starting from ₹${price.toStringAsFixed(2)}',
      iconColor: AppColors.warning,
      isRequired: true,
      onTap: () => EditPriceDialog.show(context, ref, formData),
    );
  }
}

class EditCategoryTile extends ConsumerWidget {
  final EditEventFormData formData;

  const EditCategoryTile({super.key, required this.formData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EditEventOptionTile(
      icon: Icons.category_outlined,
      label: formData.category.isEmpty ? 'Event Type' : formData.category,
      iconColor: AppColors.favorite,
      isRequired: true,
      onTap: () => EditCategoryDialog.show(context, ref, formData),
    );
  }
}

class EditDocumentTile extends ConsumerWidget {
  final EditEventFormData formData;

  const EditDocumentTile({super.key, required this.formData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ThemeUtils.isDark(context);
    final hasDocument =
        formData.newDocument != null || formData.existingDocumentUrl != null;

    String? documentName;
    if (formData.newDocument != null) {
      documentName = formData.newDocument!.path.split('/').last;
    } else if (formData.existingDocumentUrl != null) {
      documentName = formData.existingDocumentUrl!.split('/').last;
    }

    return EditEventOptionTile(
      key: ValueKey(
        hasDocument
            ? (formData.newDocument?.path ?? formData.existingDocumentUrl)
            : 'no_doc',
      ),
      icon: Icons.attach_file_rounded,
      label: hasDocument
          ? (documentName ?? 'Document attached')
          : 'Add Document (Optional)',
      iconColor: AppColors.getTextSecondary(isDark),
      isRequired: false,
      trailing: hasDocument
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDocumentPreview(context, formData, isDark),
                SizedBox(width: AppSizes.spacingXs),
                if (formData.newDocument != null)
                  IconButton(
                    icon: Icon(
                      Icons.visibility_rounded,
                      color: AppColors.getPrimary(isDark),
                    ),
                    onPressed: () =>
                        _openDocument(context, formData.newDocument!, isDark),
                    tooltip: 'Preview document',
                    iconSize: AppSizes.iconSmall,
                  ),
                IconButton(
                  icon: Icon(
                    Icons.delete_rounded,
                    color: AppColors.getError(isDark),
                  ),
                  onPressed: () {
                    ref
                        .read(editEventFormProvider.notifier)
                        .updateFormData(formData.copyWith(clearDocument: true));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Document removed',
                          style: AppTextStyles.bodyMedium(isDark: true)
                              .copyWith(color: Colors.white),
                        ),
                        backgroundColor: AppColors.getSuccess(isDark),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSmall),
                        ),
                      ),
                    );
                  },
                  tooltip: 'Remove document',
                  iconSize: AppSizes.iconSmall,
                ),
              ],
            )
          : null,
      onTap: () async {
        if (hasDocument && formData.newDocument != null) {
          _openDocument(context, formData.newDocument!, isDark);
        } else if (hasDocument && formData.existingDocumentUrl != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Document is stored online, cannot preview',
                style: AppTextStyles.bodyMedium(isDark: true)
                    .copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.getWarning(isDark),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
            ),
          );
        } else {
          await _pickDocument(context, ref, isDark);
        }
      },
    );
  }

  Widget _buildDocumentPreview(
    BuildContext context,
    EditEventFormData formData,
    bool isDark,
  ) {
    String? path;
    if (formData.newDocument != null) {
      path = formData.newDocument!.path;
    } else if (formData.existingDocumentUrl != null) {
      path = formData.existingDocumentUrl;
    }

    final extension = path?.split('.').last.toLowerCase() ?? '';
    Color bgColor;
    IconData icon;
    Color iconColor;

    switch (extension) {
      case 'pdf':
        bgColor = AppColors.error.withOpacity(0.1);
        icon = Icons.picture_as_pdf_rounded;
        iconColor = AppColors.error;
        break;
      case 'doc':
      case 'docx':
        bgColor = AppColors.info.withOpacity(0.1);
        icon = Icons.description_rounded;
        iconColor = AppColors.info;
        break;
      default:
        bgColor = AppColors.getDisabled(isDark).withOpacity(0.2);
        icon = Icons.insert_drive_file_rounded;
        iconColor = AppColors.getDisabled(isDark);
    }

    return GestureDetector(
      onTap: formData.newDocument != null
          ? () => _openDocument(context, formData.newDocument!, isDark)
          : null,
      child: Container(
        width: AppSizes.avatarMedium,
        height: AppSizes.avatarMedium,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          border: Border.all(
            color: AppColors.getBorder(isDark),
            width: AppSizes.borderWidthThin,
          ),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: AppSizes.iconMedium,
        ),
      ),
    );
  }

  Future<void> _pickDocument(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      allowMultiple: false,
    );

    if (result == null ||
        result.files.isEmpty ||
        result.files.first.path == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No document selected',
              style: AppTextStyles.bodyMedium(isDark: true)
                  .copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.getWarning(isDark),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
        );
      }
      return;
    }

    final filePath = result.files.first.path!;
    final selectedFile = File(filePath);
    if (!await selectedFile.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selected file not accessible',
              style: AppTextStyles.bodyMedium(isDark: true)
                  .copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.getError(isDark),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
        );
      }
      return;
    }

    ref
        .read(editEventFormProvider.notifier)
        .updateFormData(formData.copyWith(newDocument: selectedFile));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Document selected successfully',
            style: AppTextStyles.bodyMedium(isDark: true)
                .copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.getSuccess(isDark),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
        ),
      );
    }
  }

  Future<void> _openDocument(
    BuildContext context,
    File file,
    bool isDark,
  ) async {
    try {
      final result = await OpenFile.open(file.path);

      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.message,
                style: AppTextStyles.bodyMedium(isDark: true)
                    .copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.getWarning(isDark),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error opening document: $e',
              style: AppTextStyles.bodyMedium(isDark: true)
                  .copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.getError(isDark),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
        );
      }
    }
  }
}