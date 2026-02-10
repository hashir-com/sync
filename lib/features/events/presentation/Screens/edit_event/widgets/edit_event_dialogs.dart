import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/util/theme_util.dart';
import 'package:sync_event/features/events/data/models/category_model.dart';
import '../../../providers/category_providers.dart';
import '../providers/edit_event_provider.dart';
import '../state/edit_event_state.dart';
import 'dart:math' as math;

class EditDescriptionDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    EditEventFormData formData,
  ) {
    final isDark = ThemeUtils.isDark(context);
    final controller = TextEditingController(text: formData.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getCard(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        title: Text(
          'Event Description',
          style: AppTextStyles.headingSmall(isDark: isDark),
        ),
        content: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter description...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
          style: AppTextStyles.bodyLarge(isDark: isDark),
          maxLines: 5,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Description cannot be empty',
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
                return;
              }
              ref
                  .read(editEventFormProvider.notifier)
                  .updateFormData(
                    formData.copyWith(description: controller.text),
                  );
              Navigator.pop(ctx);
            },
            child: Text(
              'Save',
              style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                color: AppColors.getPrimary(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditLocationDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    EditEventFormData formData,
  ) {
    final isDark = ThemeUtils.isDark(context);
    final controller = TextEditingController(text: formData.location);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getCard(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        title: Text(
          'Event Location',
          style: AppTextStyles.headingSmall(isDark: isDark),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter location',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
          style: AppTextStyles.bodyLarge(isDark: isDark),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Location cannot be empty',
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
                return;
              }
              ref
                  .read(editEventFormProvider.notifier)
                  .updateFormData(formData.copyWith(location: controller.text));
              Navigator.pop(ctx);
            },
            child: Text(
              'Save',
              style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                color: AppColors.getPrimary(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditDateTimeDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    EditEventFormData formData,
  ) {
    final isDark = ThemeUtils.isDark(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final currentFormData = ref.watch(editEventFormProvider)!;

          return AlertDialog(
            backgroundColor: AppColors.getCard(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            ),
            title: Text(
              'Select Date & Time',
              style: AppTextStyles.headingSmall(isDark: isDark),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await _pickDateTime(context, ref, currentFormData, true);
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.event_rounded,
                    size: AppSizes.iconSmall,
                  ),
                  label: Text(
                    currentFormData.startTime == null
                        ? 'Pick Start Time'
                        : DateFormat(
                            'dd MMM yyyy, HH:mm',
                          ).format(currentFormData.startTime!),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLarge,
                      vertical: AppSizes.paddingMedium,
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.spacingMedium),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (currentFormData.startTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please select start time first',
                            style: AppTextStyles.bodyMedium(isDark: true)
                                .copyWith(color: Colors.white),
                          ),
                          backgroundColor: AppColors.getWarning(isDark),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSmall),
                          ),
                        ),
                      );
                      return;
                    }
                    await _pickDateTime(context, ref, currentFormData, false);
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.event_available_rounded,
                    size: AppSizes.iconSmall,
                  ),
                  label: Text(
                    currentFormData.endTime == null
                        ? 'Pick End Time'
                        : DateFormat(
                            'dd MMM yyyy, HH:mm',
                          ).format(currentFormData.endTime!),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLarge,
                      vertical: AppSizes.paddingMedium,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (currentFormData.startTime == null ||
                      currentFormData.endTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please select both start and end time',
                          style: AppTextStyles.bodyMedium(isDark: true)
                              .copyWith(color: Colors.white),
                        ),
                        backgroundColor: AppColors.getWarning(isDark),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSmall),
                        ),
                      ),
                    );
                    return;
                  }
                  if (currentFormData.startTime!.isAfter(
                    currentFormData.endTime!,
                  )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'End time must be after start time',
                          style: AppTextStyles.bodyMedium(isDark: true)
                              .copyWith(color: Colors.white),
                        ),
                        backgroundColor: AppColors.getError(isDark),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSmall),
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext);
                },
                child: Text(
                  'Done',
                  style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                    color: AppColors.getPrimary(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _pickDateTime(
    BuildContext context,
    WidgetRef ref,
    EditEventFormData formData,
    bool isStart,
  ) async {
    final initialDate = isStart
        ? (formData.startTime ?? DateTime.now())
        : (formData.endTime ?? formData.startTime ?? DateTime.now());

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (isStart) {
      ref
          .read(editEventFormProvider.notifier)
          .updateFormData(formData.copyWith(startTime: dateTime));
    } else {
      ref
          .read(editEventFormProvider.notifier)
          .updateFormData(formData.copyWith(endTime: dateTime));
    }
  }
}

class EditCapacityDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    EditEventFormData formData,
    int minAttendees,
  ) {
    final isDark = ThemeUtils.isDark(context);
    final controller = TextEditingController(
      text: formData.maxAttendees.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getCard(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        title: Text(
          'Max Attendees',
          style: AppTextStyles.headingSmall(isDark: isDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter maximum attendees',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
              ),
              style: AppTextStyles.bodyLarge(isDark: isDark),
              autofocus: true,
            ),
            SizedBox(height: AppSizes.spacingSmall),
            Text(
              'Minimum: $minAttendees (current attendees)',
              style: AppTextStyles.bodySmall(isDark: isDark),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value == null || value < minAttendees) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Must be at least $minAttendees',
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
                return;
              }
              ref
                  .read(editEventFormProvider.notifier)
                  .updateFormData(formData.copyWith(maxAttendees: value));
              Navigator.pop(ctx);
            },
            child: Text(
              'Save',
              style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                color: AppColors.getPrimary(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditPriceDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    EditEventFormData formData,
  ) {
    final isDark = ThemeUtils.isDark(context);
    final controller = TextEditingController(
      text: (formData.ticketPrice ?? 0).toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getCard(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        title: Text(
          'Ticket Price',
          style: AppTextStyles.headingSmall(isDark: isDark),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter price (0 for free)',
            prefixText: '₹ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
          style: AppTextStyles.bodyLarge(isDark: isDark),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text) ?? 0;
              if (value < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Price cannot be negative',
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
                return;
              }
              ref
                  .read(editEventFormProvider.notifier)
                  .updateFormData(formData.copyWith(ticketPrice: value));
              Navigator.pop(ctx);
            },
            child: Text(
              'Save',
              style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                color: AppColors.getPrimary(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditCategoryDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    EditEventFormData formData,
  ) {
    final isDark = ThemeUtils.isDark(context);
    final repository = ref.read(categoryRepositoryProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getCard(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        title: Text(
          'Event Type',
          style: AppTextStyles.headingSmall(isDark: isDark),
        ),
        content: StreamBuilder<List<CategoryModel>>(
          stream: repository.getActiveCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.paddingXl),
                  child: CircularProgressIndicator(
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: EdgeInsets.all(AppSizes.paddingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.getError(isDark),
                      size: AppSizes.iconXxl,
                    ),
                    SizedBox(height: AppSizes.spacingSmall),
                    Text(
                      'Failed to load categories',
                      style: AppTextStyles.bodyMedium(isDark: isDark),
                    ),
                  ],
                ),
              );
            }

            final categories = snapshot.data ?? [];

            if (categories.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(AppSizes.paddingXl),
                child: Text(
                  'No categories available',
                  style: AppTextStyles.bodyMedium(isDark: isDark),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: categories.map((category) {
                  return RadioListTile<String>(
                    title: Row(
                      children: [
                        if (category.icon != null &&
                            category.icon!.isNotEmpty) ...[
                          Text(
                            category.icon!,
                            style: TextStyle(fontSize: AppSizes.fontXl),
                          ),
                          SizedBox(width: AppSizes.spacingSmall),
                        ],
                        Expanded(
                          child: Text(
                            category.name,
                            style: AppTextStyles.bodyLarge(isDark: isDark),
                          ),
                        ),
                      ],
                    ),
                    value: category.name,
                    groupValue: formData.category,
                    activeColor: AppColors.getPrimary(isDark),
                    onChanged: (String? value) {
                      if (value != null && value.isNotEmpty) {
                        ref
                            .read(editEventFormProvider.notifier)
                            .updateFormData(formData.copyWith(category: value));
                        Navigator.pop(ctx);
                      }
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                color: AppColors.getTextSecondary(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// Add after EditCategoryDialog class
class EditCapacityByCategoryDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    EditEventFormData formData,
    int minAttendees,
  ) {
    final isDark = ThemeUtils.isDark(context);

    // Initialize temp state from existing data
    bool tempIsOpenCommon = formData.maxAttendees >= 99999;
    Map<String, bool> tempIsOpenCategory = {
      'vip': (formData.categoryCapacities['vip'] ?? 0) >= 99999,
      'premium': (formData.categoryCapacities['premium'] ?? 0) >= 99999,
      'regular': (formData.categoryCapacities['regular'] ?? 0) >= 99999,
    };

    // Auto-tick common if all are unlimited
    if (tempIsOpenCategory['vip']! &&
        tempIsOpenCategory['premium']! &&
        tempIsOpenCategory['regular']!) {
      tempIsOpenCommon = true;
    }

    final tempControllers = {
      'vip': TextEditingController(
        text: (formData.categoryCapacities['vip'] ?? 0) < 99999
            ? (formData.categoryCapacities['vip'] ?? 0).toString()
            : '',
      ),
      'premium': TextEditingController(
        text: (formData.categoryCapacities['premium'] ?? 0) < 99999
            ? (formData.categoryCapacities['premium'] ?? 0).toString()
            : '',
      ),
      'regular': TextEditingController(
        text: (formData.categoryCapacities['regular'] ?? 0) < 99999
            ? (formData.categoryCapacities['regular'] ?? 0).toString()
            : '',
      ),
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.getCard(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          title: Text(
            'Capacity Settings',
            style: AppTextStyles.headingSmall(isDark: isDark),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Common Open Capacity
                _buildCommonCapacityTile(
                  isDark: isDark,
                  isOpenCommon: tempIsOpenCommon,
                  onCommonChanged: (value) {
                    setDialogState(() {
                      tempIsOpenCommon = value;
                      if (value) {
                        tempIsOpenCategory['vip'] = false;
                        tempIsOpenCategory['premium'] = false;
                        tempIsOpenCategory['regular'] = false;
                        tempControllers.forEach((_, ctrl) => ctrl.clear());
                      }
                    });
                  },
                ),
                SizedBox(height: AppSizes.spacingMedium),

                // Individual Limits
                if (!tempIsOpenCommon) ...[
                  Text(
                    'Individual Limits',
                    style: AppTextStyles.titleMedium(isDark: isDark)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppSizes.spacingSmall),
                  _buildCapacityTile(
                    isDark: isDark,
                    title: 'VIP Tickets',
                    icon: Icons.star,
                    iconColor: AppColors.warning,
                    isOpen: tempIsOpenCategory['vip']!,
                    controller: tempControllers['vip']!,
                    hint: 'VIP capacity',
                    onOpenChanged: (isOpen) {
                      setDialogState(() {
                        tempIsOpenCategory['vip'] = isOpen ?? false;
                        if (tempIsOpenCategory['vip']!) {
                          tempControllers['vip']!.clear();
                        }
                      });
                    },
                  ),
                  SizedBox(height: AppSizes.spacingSmall),
                  _buildCapacityTile(
                    isDark: isDark,
                    title: 'Premium Tickets',
                    icon: Icons.diamond,
                    iconColor: AppColors.primary,
                    isOpen: tempIsOpenCategory['premium']!,
                    controller: tempControllers['premium']!,
                    hint: 'Premium capacity',
                    onOpenChanged: (isOpen) {
                      setDialogState(() {
                        tempIsOpenCategory['premium'] = isOpen ?? false;
                        if (tempIsOpenCategory['premium']!) {
                          tempControllers['premium']!.clear();
                        }
                      });
                    },
                  ),
                  SizedBox(height: AppSizes.spacingSmall),
                  _buildCapacityTile(
                    isDark: isDark,
                    title: 'Regular Tickets',
                    icon: Icons.person_outline,
                    iconColor: AppColors.secondary,
                    isOpen: tempIsOpenCategory['regular']!,
                    controller: tempControllers['regular']!,
                    hint: 'Regular capacity',
                    onOpenChanged: (isOpen) {
                      setDialogState(() {
                        tempIsOpenCategory['regular'] = isOpen ?? false;
                        if (tempIsOpenCategory['regular']!) {
                          tempControllers['regular']!.clear();
                        }
                      });
                    },
                  ),
                ],
                SizedBox(height: AppSizes.spacingSmall),
                Text(
                  'Minimum: $minAttendees (current attendees)',
                  style: AppTextStyles.bodySmall(isDark: isDark),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Save logic
                if (tempIsOpenCommon) {
                  final updated = formData.copyWith(
                    maxAttendees: 99999,
                    categoryCapacities: {
                      'vip': 99999,
                      'premium': 99999,
                      'regular': 99999,
                    },
                  );
                  ref.read(editEventFormProvider.notifier).updateFormData(updated);
                } else {
                  final vipCap = tempIsOpenCategory['vip']!
                      ? 99999
                      : (int.tryParse(tempControllers['vip']!.text.trim()) ?? 0);
                  final premiumCap = tempIsOpenCategory['premium']!
                      ? 99999
                      : (int.tryParse(tempControllers['premium']!.text.trim()) ?? 0);
                  final regularCap = tempIsOpenCategory['regular']!
                      ? 99999
                      : (int.tryParse(tempControllers['regular']!.text.trim()) ?? 0);

                  final totalFinite =
                      (vipCap < 99999 ? vipCap : 0) +
                      (premiumCap < 99999 ? premiumCap : 0) +
                      (regularCap < 99999 ? regularCap : 0);

                  if (totalFinite < minAttendees) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Total capacity must be at least $minAttendees',
                          style: AppTextStyles.bodyMedium(isDark: true)
                              .copyWith(color: Colors.white),
                        ),
                        backgroundColor: AppColors.getError(isDark),
                      ),
                    );
                    return;
                  }

                  final updated = formData.copyWith(
                    maxAttendees: vipCap + premiumCap + regularCap,
                    categoryCapacities: {
                      'vip': vipCap,
                      'premium': premiumCap,
                      'regular': regularCap,
                    },
                  );
                  ref.read(editEventFormProvider.notifier).updateFormData(updated);
                }
                Navigator.pop(ctx);
              },
              child: Text(
                'Save',
                style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                  color: AppColors.getPrimary(isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildCommonCapacityTile({
    required bool isDark,
    required bool isOpenCommon,
    required void Function(bool) onCommonChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.getPrimary(isDark).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(
          color: AppColors.getPrimary(isDark).withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: () => onCommonChanged(!isOpenCommon),
        child: Row(
          children: [
            Checkbox(
              value: isOpenCommon,
              onChanged: (v) => onCommonChanged(v ?? false),
              activeColor: AppColors.getPrimary(isDark),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Open Capacity (All Unlimited)',
                    style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.getPrimary(isDark),
                    ),
                  ),
                  Text(
                    'Unlimited attendees for all categories',
                    style: AppTextStyles.bodySmall(isDark: isDark)
                        .copyWith(color: AppColors.getTextSecondary(isDark)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildCapacityTile({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isOpen,
    required TextEditingController controller,
    required String hint,
    required void Function(bool?) onOpenChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSizes.paddingXs),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: AppSizes.iconSmall),
              ),
              SizedBox(width: AppSizes.spacingSmall),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium(isDark: isDark)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spacingSmall),
          InkWell(
            onTap: () => onOpenChanged(!isOpen),
            child: Row(
              children: [
                Checkbox(
                  value: isOpen,
                  onChanged: onOpenChanged,
                  activeColor: AppColors.getPrimary(isDark),
                ),
                Expanded(
                  child: Text(
                    'Unlimited ($title)',
                    style: AppTextStyles.bodyMedium(isDark: isDark),
                  ),
                ),
              ],
            ),
          ),
          if (!isOpen) ...[
            SizedBox(height: AppSizes.spacingSmall),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ],
      ),
    );
  }
}

class EditPriceByCategoryDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    EditEventFormData formData,
  ) {
    final isDark = ThemeUtils.isDark(context);

    bool tempIsFree = (formData.categoryPrices['vip'] ?? 0) == 0 &&
        (formData.categoryPrices['premium'] ?? 0) == 0 &&
        (formData.categoryPrices['regular'] ?? 0) == 0;

    Map<String, bool> tempIsFreeCategory = {
      'vip': (formData.categoryPrices['vip'] ?? 0) == 0,
      'premium': (formData.categoryPrices['premium'] ?? 0) == 0,
      'regular': (formData.categoryPrices['regular'] ?? 0) == 0,
    };

    final tempControllers = {
      'vip': TextEditingController(
        text: (formData.categoryPrices['vip'] ?? 0) > 0
            ? formData.categoryPrices['vip']!.toStringAsFixed(2)
            : '',
      ),
      'premium': TextEditingController(
        text: (formData.categoryPrices['premium'] ?? 0) > 0
            ? formData.categoryPrices['premium']!.toStringAsFixed(2)
            : '',
      ),
      'regular': TextEditingController(
        text: (formData.categoryPrices['regular'] ?? 0) > 0
            ? formData.categoryPrices['regular']!.toStringAsFixed(2)
            : '',
      ),
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.getCard(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          title: Text(
            'Ticket Price per Category',
            style: AppTextStyles.headingSmall(isDark: isDark),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Common Free Option
                _buildCommonFreeTile(
                  isDark: isDark,
                  isFree: tempIsFree,
                  onFreeChanged: (value) {
                    setDialogState(() {
                      tempIsFree = value;
                      if (value) {
                        tempIsFreeCategory['vip'] = true;
                        tempIsFreeCategory['premium'] = true;
                        tempIsFreeCategory['regular'] = true;
                        tempControllers.forEach((_, ctrl) => ctrl.clear());
                      }
                    });
                  },
                ),
                SizedBox(height: AppSizes.spacingMedium),

                // Individual Prices
                if (!tempIsFree) ...[
                  Text(
                    'Individual Prices',
                    style: AppTextStyles.titleMedium(isDark: isDark)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppSizes.spacingSmall),
                  _buildPriceTile(
                    isDark: isDark,
                    title: 'VIP Tickets',
                    icon: Icons.star,
                    iconColor: AppColors.warning,
                    isFree: tempIsFreeCategory['vip']!,
                    controller: tempControllers['vip']!,
                    hint: 'VIP price',
                    category: 'vip',
                    tempIsFreeCategory: tempIsFreeCategory,
                    setDialogState: setDialogState,
                  ),
                  SizedBox(height: AppSizes.spacingSmall),
                  _buildPriceTile(
                    isDark: isDark,
                    title: 'Premium Tickets',
                    icon: Icons.diamond,
                    iconColor: AppColors.primary,
                    isFree: tempIsFreeCategory['premium']!,
                    controller: tempControllers['premium']!,
                    hint: 'Premium price',
                    category: 'premium',
                    tempIsFreeCategory: tempIsFreeCategory,
                    setDialogState: setDialogState,
                  ),
                  SizedBox(height: AppSizes.spacingSmall),
                  _buildPriceTile(
                    isDark: isDark,
                    title: 'Regular Tickets',
                    icon: Icons.person_outline,
                    iconColor: AppColors.secondary,
                    isFree: tempIsFreeCategory['regular']!,
                    controller: tempControllers['regular']!,
                    hint: 'Regular price',
                    category: 'regular',
                    tempIsFreeCategory: tempIsFreeCategory,
                    setDialogState: setDialogState,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                  color: AppColors.getTextSecondary(isDark),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final vip = tempIsFreeCategory['vip']!
                    ? 0.0
                    : (double.tryParse(tempControllers['vip']!.text.trim()) ?? 0.0);
                final premium = tempIsFreeCategory['premium']!
                    ? 0.0
                    : (double.tryParse(tempControllers['premium']!.text.trim()) ?? 0.0);
                final regular = tempIsFreeCategory['regular']!
                    ? 0.0
                    : (double.tryParse(tempControllers['regular']!.text.trim()) ?? 0.0);

                final updated = formData.copyWith(
                  ticketPrice: math.min(
                    vip > 0 ? vip : double.infinity,
                    math.min(
                      premium > 0 ? premium : double.infinity,
                      regular > 0 ? regular : double.infinity,
                    ),
                  ) == double.infinity
                      ? 0
                      : math.min(
                          vip > 0 ? vip : double.infinity,
                          math.min(
                            premium > 0 ? premium : double.infinity,
                            regular > 0 ? regular : double.infinity,
                          ),
                        ),
                  categoryPrices: {
                    'vip': vip,
                    'premium': premium,
                    'regular': regular,
                  },
                );
                ref.read(editEventFormProvider.notifier).updateFormData(updated);
                Navigator.pop(ctx);
              },
              child: Text(
                'Save',
                style: AppTextStyles.labelLarge(isDark: isDark).copyWith(
                  color: AppColors.getPrimary(isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildCommonFreeTile({
    required bool isDark,
    required bool isFree,
    required void Function(bool) onFreeChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.getPrimary(isDark).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(
          color: AppColors.getPrimary(isDark).withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: () => onFreeChanged(!isFree),
        child: Row(
          children: [
            Checkbox(
              value: isFree,
              onChanged: (v) => onFreeChanged(v ?? false),
              activeColor: AppColors.getPrimary(isDark),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Free Event (All Categories Free)',
                    style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.getPrimary(isDark),
                    ),
                  ),
                  Text(
                    'No cost for all categories',
                    style: AppTextStyles.bodySmall(isDark: isDark)
                        .copyWith(color: AppColors.getTextSecondary(isDark)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPriceTile({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isFree,
    required TextEditingController controller,
    required String hint,
    required String category,
    required Map<String, bool> tempIsFreeCategory,
    required StateSetter setDialogState,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSizes.paddingXs),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: AppSizes.iconSmall),
              ),
              SizedBox(width: AppSizes.spacingSmall),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium(isDark: isDark)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spacingSmall),
          InkWell(
            onTap: () {
              setDialogState(() {
                tempIsFreeCategory[category] = !isFree;
                if (tempIsFreeCategory[category]!) {
                  controller.clear();
                }
              });
            },
            child: Row(
              children: [
                Checkbox(
                  value: isFree,
                  onChanged: (v) {
                    setDialogState(() {
                      tempIsFreeCategory[category] = v ?? false;
                      if (tempIsFreeCategory[category]!) {
                        controller.clear();
                      }
                    });
                  },
                  activeColor: AppColors.getPrimary(isDark),
                ),
                Expanded(
                  child: Text(
                    'Free $title',
                    style: AppTextStyles.bodyMedium(isDark: isDark),
                  ),
                ),
              ],
            ),
          ),
          if (!isFree) ...[
            SizedBox(height: AppSizes.spacingSmall),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ],
      ),
    );
  }
}