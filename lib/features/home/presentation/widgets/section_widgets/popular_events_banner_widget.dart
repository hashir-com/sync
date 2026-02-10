import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'dart:async';

import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/util/responsive_util.dart';
import 'package:sync_event/features/favorites/providers/favorites_provider.dart';
import 'package:sync_event/features/home/presentation/utils/snackbar_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_event/features/home/presentation/widgets/section_widgets/banner_card_widget.dart';

class PopularEventsBanner extends ConsumerStatefulWidget {
  final List events;
  final bool isDark;

  const PopularEventsBanner({
    super.key,
    required this.events,
    required this.isDark,
  });

  @override
  ConsumerState<PopularEventsBanner> createState() =>
      _PopularEventsBannerState();
}

class _PopularEventsBannerState extends ConsumerState<PopularEventsBanner> {
  late PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel(); // Ensure no duplicate timers
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || _isScrolling) {
        return;
      }
      _isScrolling = true;
      final nextIndex = (_currentIndex + 1) % widget.events.length;
      _pageController
          .animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          )
          .then((_) {
            if (mounted) {
              setState(() {
                _currentIndex = nextIndex;
              });
            }
            _isScrolling = false;
          });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);

    if (widget.events.isEmpty) {
      return const SizedBox.shrink();
    }

    final height = ResponsiveUtil.isMobile(context) ? 220 : 260;

    return Column(
      children: [
        SizedBox(
          height: height.toDouble(),
          child: PageView.builder(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              // Pause on manual swipe, resume after 3 seconds
              _timer?.cancel();
              _isScrolling = false; // Reset flag for manual
              Timer(const Duration(seconds: 2), () {
                if (mounted) _startAutoScroll();
              });
            },
            itemCount: widget.events.length,
            itemBuilder: (context, index) {
              final event = widget.events[index];
              if (event == null) return const SizedBox.shrink();

              final isFavorite = favorites.contains(event.id ?? '');

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingMedium,
                  vertical: AppSizes.spacingSmall,
                ),
                child: BannerCard(
                  event: event,
                  isDark: widget.isDark,
                  isFavorite: isFavorite,
                  onFavoriteTap: () {
                    ref
                        .read(favoritesProvider.notifier)
                        .toggleFavorite(event.id ?? '');
                    showFavoriteSnackbarSafe(
                      context,
                      isFavorite,
                      event.title ?? 'Event',
                    );
                  },
                  onTap: () => context.push('/event-detail', extra: event),
                ),
              );
            },
          ),
        ),
        // Dots indicator
        if (widget.events.length > 1)
          Padding(
            padding: EdgeInsets.all(AppSizes.paddingMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.events.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentIndex == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppColors.getPrimary(widget.isDark)
                        : AppColors.getTextSecondary(widget.isDark),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
