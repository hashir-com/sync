import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
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

    return SizedBox(
      height: height.toDouble(),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (_) {},
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
    );
  }
}
