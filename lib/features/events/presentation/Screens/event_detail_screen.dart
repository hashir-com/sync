import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/util/theme_util.dart';
import 'package:sync_event/features/auth/presentation/providers/auth_notifier.dart';
import 'package:sync_event/features/events/domain/entities/event_entity.dart';
import 'package:sync_event/features/events/presentation/widgets/event_detail_screen_widgets/ai_bottom_sheet.dart';
import 'package:sync_event/features/events/presentation/widgets/event_detail_screen_widgets/detail_section.dart';
import 'package:sync_event/features/events/presentation/widgets/event_detail_screen_widgets/header_image.dart';
import 'package:sync_event/widgets/error_boundary.dart';

// Main screen for displaying event details
class EventDetailScreen extends ConsumerStatefulWidget {
  final EventEntity event;

  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late ScrollController _scrollController;

  // Initialize animation and scroll controllers
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scrollController = ScrollController();
    _fadeController.forward();
  }

  // Dispose controllers
  @override
  void dispose() {
    if (_fadeController.isAnimating) _fadeController.stop();
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Build main scaffold with header and detail section
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeUtils.isDark(context);
    final user = ref.watch(authNotifierProvider).user;
    final isOrganizer = user?.uid == widget.event.organizerId;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      body: FadeTransition(
        opacity: _fadeController,
        child: ErrorBoundary(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderImage(
                  event: widget.event,
                  isOrganizer: isOrganizer,
                  isDark: isDark,
                ),
                DetailSection(
                  event: widget.event,
                  isOrganizer: isOrganizer,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
     floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AIBottomSheet(
            event: widget.event,
            isDark: isDark,
          ),
        );
      },
      icon: Icon(Icons.auto_awesome),
      label: Text('AI'),
      backgroundColor: AppColors.getPrimary(isDark),
      foregroundColor: Colors.white,
    ),
    );
  }
}
