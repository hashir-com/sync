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