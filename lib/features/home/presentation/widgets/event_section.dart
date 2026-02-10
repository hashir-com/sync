// // ignore_for_file: unnecessary_null_comparison, deprecated_member_use

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:sync_event/core/constants/app_colors.dart';
// import 'package:sync_event/core/constants/app_sizes.dart';
// import 'package:sync_event/core/constants/app_text_styles.dart';
// import 'package:sync_event/core/util/theme_util.dart';
// import 'package:sync_event/features/events/presentation/providers/event_providers.dart';
// import 'package:sync_event/features/favorites/providers/favorites_provider.dart';
// import 'package:sync_event/features/home/presentation/screen/filter_bottom_sheet.dart';

// // User Location Provider for City Name

// final userCityProvider = FutureProvider<String>((ref) async {
//   try {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return 'Your City';

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }

//     if (permission == LocationPermission.deniedForever ||
//         permission == LocationPermission.denied) {
//       return 'Your City';
//     }

//     final position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.medium,
//     );

//     final placemarks = await placemarkFromCoordinates(
//       position.latitude,
//       position.longitude,
//     );

//     if (placemarks.isNotEmpty) {
//       return placemarks.first.locality ?? 'Your City';
//     }
//     return 'Your City';
//   } catch (e) {
//     return 'Your City';
//   }
// });

// // Location State Provider

// final locationStateProvider =
//     StateNotifierProvider<LocationNotifier, LocationState>((ref) {
//       return LocationNotifier();
//     });

// class LocationState {
//   final Position? position;
//   final bool isDenied;
//   final bool isLoading;
//   final bool isServiceDisabled;

//   LocationState({
//     this.position,
//     this.isDenied = false,
//     this.isLoading = true,
//     this.isServiceDisabled = false,
//   });

//   LocationState copyWith({
//     Position? position,
//     bool? isDenied,
//     bool? isLoading,
//     bool? isServiceDisabled,
//   }) {
//     return LocationState(
//       position: position ?? this.position,
//       isDenied: isDenied ?? this.isDenied,
//       isLoading: isLoading ?? this.isLoading,
//       isServiceDisabled: isServiceDisabled ?? this.isServiceDisabled,
//     );
//   }
// }

// class LocationNotifier extends StateNotifier<LocationState> {
//   LocationNotifier() : super(LocationState()) {
//     _checkLocationPermission();
//   }

//   Future<void> _checkLocationPermission() async {
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         state = state.copyWith(
//           isServiceDisabled: true,
//           isDenied: false,
//           isLoading: false,
//         );
//         return;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }

//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         state = state.copyWith(
//           isDenied: true,
//           isServiceDisabled: false,
//           isLoading: false,
//         );
//         return;
//       }

//       final pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       state = state.copyWith(
//         position: pos,
//         isDenied: false,
//         isServiceDisabled: false,
//         isLoading: false,
//       );
//     } catch (e) {
//       state = state.copyWith(isDenied: true, isLoading: false);
//     }
//   }

//   void retry() {
//     state = LocationState();
//     _checkLocationPermission();
//   }

//   Future<void> openLocationSettings() async {
//     try {
//       await Geolocator.openLocationSettings();
//     } catch (e) {
//       // Handle error silently
//     }
//   }

//   Future<void> openAppSettings() async {
//     try {
//       await Geolocator.openAppSettings();
//     } catch (e) {
//       // Handle error silently
//     }
//   }
// }

// // Page State Providers

// final nearbyEventsPageProvider = StateProvider<double>((ref) => 0.0);
// final topCityEventsPageProvider = StateProvider<double>((ref) => 0.0);
// final sportsEventsPageProvider = StateProvider<double>((ref) => 0.0);
// final musicEventsPageProvider = StateProvider<double>((ref) => 0.0);
// final freeEventsPageProvider = StateProvider<double>((ref) => 0.0);
// final bannerPageProvider = StateProvider<int>((ref) => 0);

// // SAFE SNACKBAR HELPER

// void showFavoriteSnackbarSafe(
//   BuildContext context,
//   bool wasFavorite,
//   String title,
// ) {
//   if (!context.mounted) return;

//   try {
//     final snackBar = SnackBar(
//       content: Row(
//         children: [
//           Icon(
//             wasFavorite ? Icons.favorite_border : Icons.favorite,
//             color: Colors.white,
//             size: 20,
//           ),
//           SizedBox(width: AppSizes.spacingMedium),
//           Expanded(
//             child: Text(
//               wasFavorite ? 'Removed from favorites' : 'Added to favorites',
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//       duration: const Duration(milliseconds: 2000),
//       behavior: SnackBarBehavior.floating,
//       backgroundColor: wasFavorite ? Colors.grey[700] : Colors.red,
//       margin: EdgeInsets.all(AppSizes.spacingMedium),
//     );

//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(snackBar);
//     }
//   } catch (e) {
//     // Fail silently
//   }
// }

// // Main Event Section Widget

// class EventSection extends ConsumerWidget {
//   const EventSection({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final eventsAsync = ref.watch(approvedEventsStreamProvider);
//     final isDark = ThemeUtils.isDark(context);
//     final userCityAsync = ref.watch(userCityProvider);

//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(height: AppSizes.spacingXxl),

//           // ------- 1. POPULAR EVENTS BANNER -------
//           _SectionHeader(
//             title: 'Upcoming Popular Events',
//             isDark: isDark,
//             onViewAll: () {
//               try {
//                 ref.read(eventFilterProvider.notifier).reset();
//                 context.push('/events');
//               } catch (e) {
//                 // Handle error
//               }
//             },
//           ),

//           SizedBox(height: AppSizes.spacingLarge),

//           eventsAsync.when(
//             data: (events) {
//               if (events.isEmpty) {
//                 return _EmptyState(
//                   message: 'No events available',
//                   icon: Icons.event_busy_rounded,
//                   isDark: isDark,
//                 );
//               }

//               // SAFE SORTING WITH NULL CHECKS
//               final sortedEvents = List.from(events.where((e) => e != null))
//                 ..sort((a, b) {
//                   try {
//                     return (a?.startTime ?? DateTime.now()).compareTo(
//                       b?.startTime ?? DateTime.now(),
//                     );
//                   } catch (e) {
//                     return 0;
//                   }
//                 });

//               if (sortedEvents.isEmpty) {
//                 return _EmptyState(
//                   message: 'No events available',
//                   icon: Icons.event_busy_rounded,
//                   isDark: isDark,
//                 );
//               }

//               return _PopularEventsBanner(
//                 events: sortedEvents.take(10).toList(),
//                 isDark: isDark,
//               );
//             },
//             loading: () => _BannerShimmer(isDark: isDark),
//             error: (error, _) => _ErrorState(
//               message: 'Failed to load events',
//               onRetry: () => ref.refresh(approvedEventsStreamProvider),
//               isDark: isDark,
//             ),
//           ),

//           SizedBox(height: AppSizes.spacingXxxl),

//           // ------- 2. NEARBY EVENTS SECTION -------
//           _SectionHeader(
//             title: 'Popular Events Near You',
//             isDark: isDark,
//             onViewAll: () {
//               try {
//                 context.push('/events');
//               } catch (e) {
//                 // Handle error
//               }
//             },
//           ),

//           SizedBox(height: AppSizes.spacingLarge),

//           _NearbyEventsSection(eventsAsync: eventsAsync, isDark: isDark),

//           SizedBox(height: AppSizes.spacingXl),

//           // ------- 3. SPORTS EVENTS SECTION -------
//           _SectionHeader(
//             title: 'Sports Events',
//             isDark: isDark,
//             onViewAll: () {
//               try {
//                 ref.read(eventFilterProvider.notifier).updateCategories([
//                   'Sports',
//                 ]);
//                 context.push('/events');
//               } catch (e) {
//                 // Handle error
//               }
//             },
//           ),

//           SizedBox(height: AppSizes.spacingLarge),

//           eventsAsync.when(
//             data: (events) {
//               final sportEvents = (events)
//                   .where(
//                     (event) =>
//                         (event.category.toLowerCase() == 'sports' ||
//                         event.category.toLowerCase().contains('sport') == true),
//                   )
//                   .take(10)
//                   .toList();

//               if (sportEvents.isEmpty) {
//                 return _EmptyState(
//                   message: 'No sports events available',
//                   icon: Icons.sports_basketball_rounded,
//                   isDark: isDark,
//                 );
//               }

//               return _SmallEventCardList(events: sportEvents, isDark: isDark);
//             },
//             loading: () => _SmallCardShimmer(isDark: isDark),
//             error: (_, __) => const SizedBox.shrink(),
//           ),

//           SizedBox(height: AppSizes.spacingXl),

//           // ------- 4. MUSIC EVENTS SECTION -------
//           _SectionHeader(
//             title: 'Music Events',
//             isDark: isDark,
//             onViewAll: () {
//               try {
//                 ref.read(eventFilterProvider.notifier).updateCategories([
//                   'Music',
//                 ]);
//                 context.push('/events');
//               } catch (e) {
//                 // Handle error
//               }
//             },
//           ),

//           SizedBox(height: AppSizes.spacingLarge),

//           eventsAsync.when(
//             data: (events) {
//               final musicEvents = (events)
//                   .where(
//                     (event) =>
//                         (event.category.toLowerCase() == 'music' ||
//                         event.category.toLowerCase().contains('music') == true),
//                   )
//                   .take(10)
//                   .toList();

//               if (musicEvents.isEmpty) {
//                 return _EmptyState(
//                   message: 'No music events available',
//                   icon: Icons.music_note_rounded,
//                   isDark: isDark,
//                 );
//               }

//               return _SmallEventCardList(events: musicEvents, isDark: isDark);
//             },
//             loading: () => _SmallCardShimmer(isDark: isDark),
//             error: (_, __) => const SizedBox.shrink(),
//           ),

//           SizedBox(height: AppSizes.spacingXl),

//           // ------- 5. FREE EVENTS SECTION -------
//           _SectionHeader(
//             title: 'Free Events',
//             isDark: isDark,
//             onViewAll: () {
//               try {
//                 ref.read(eventFilterProvider.notifier).updatePriceRange(0, 0);
//                 context.push('/events');
//               } catch (e) {
//                 // Handle error
//               }
//             },
//           ),

//           SizedBox(height: AppSizes.spacingLarge),

//           eventsAsync.when(
//             data: (events) {
//               final freeEvents = (events)
//                   .where((event) => (event.ticketPrice ?? 0) == 0)
//                   .take(10)
//                   .toList();

//               if (freeEvents.isEmpty) {
//                 return _EmptyState(
//                   message: 'No free events available',
//                   icon: Icons.local_offer_rounded,
//                   isDark: isDark,
//                 );
//               }

//               return _SmallEventCardList(events: freeEvents, isDark: isDark);
//             },
//             loading: () => _SmallCardShimmer(isDark: isDark),
//             error: (_, __) => const SizedBox.shrink(),
//           ),

//           SizedBox(height: AppSizes.spacingXl),

//           // ------- 6. TOP IN USER'S CITY SECTION -------
//           userCityAsync.when(
//             data: (userCity) {
//               return Column(
//                 children: [
//                   _SectionHeader(
//                     title: 'Top in $userCity',
//                     isDark: isDark,
//                     onViewAll: () {
//                       try {
//                         ref
//                             .read(eventFilterProvider.notifier)
//                             .updateLocation(userCity);
//                         context.push('/events');
//                       } catch (e) {
//                         // Handle error
//                       }
//                     },
//                   ),
//                   SizedBox(height: AppSizes.spacingLarge),
//                   _TopCityEventsSection(
//                     eventsAsync: eventsAsync,
//                     isDark: isDark,
//                     cityName: userCity,
//                   ),
//                   SizedBox(height: AppSizes.spacingXxxl),
//                 ],
//               );
//             },
//             loading: () => const SizedBox.shrink(),
//             error: (_, __) => const SizedBox.shrink(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Popular Events Banner with Auto-Scroll (ENHANCED)

// class _PopularEventsBanner extends ConsumerStatefulWidget {
//   final List events;
//   final bool isDark;

//   const _PopularEventsBanner({required this.events, required this.isDark});

//   @override
//   ConsumerState<_PopularEventsBanner> createState() =>
//       _PopularEventsBannerState();
// }

// class _PopularEventsBannerState extends ConsumerState<_PopularEventsBanner> {
//   late PageController _pageController;

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(initialPage: 0);
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final favorites = ref.watch(favoritesProvider);

//     if (widget.events.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     return SizedBox(
//       height: 240,
//       child: PageView.builder(
//         controller: _pageController,
//         onPageChanged: (_) {},
//         itemCount: widget.events.length,
//         itemBuilder: (context, index) {
//           final event = widget.events[index];
//           if (event == null) return const SizedBox.shrink();

//           final isFavorite = favorites.contains(event.id ?? '');

//           return Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: AppSizes.spacingMedium,
//               vertical: AppSizes.spacingSmall,
//             ),
//             child: _BannerCard(
//               event: event,
//               isDark: widget.isDark,
//               isFavorite: isFavorite,
//               onFavoriteTap: () {
//                 try {
//                   ref
//                       .read(favoritesProvider.notifier)
//                       .toggleFavorite(event.id ?? '');
//                   showFavoriteSnackbarSafe(
//                     context,
//                     isFavorite,
//                     event.title ?? 'Event',
//                   );
//                 } catch (e) {
//                   // Handle error
//                 }
//               },
//               onTap: () {
//                 try {
//                   context.push('/event-detail', extra: event);
//                 } catch (e) {
//                   // Handle error
//                 }
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // Banner Card Widget

// class _BannerCard extends StatelessWidget {
//   final dynamic event;
//   final bool isDark;
//   final bool isFavorite;
//   final VoidCallback onFavoriteTap;
//   final VoidCallback onTap;

//   const _BannerCard({
//     required this.event,
//     required this.isDark,
//     required this.isFavorite,
//     required this.onFavoriteTap,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     DateTime startTime = event.startTime ?? DateTime.now();
//     final dateFormat = DateFormat('MMM d, yyyy');
//     final formattedDate = dateFormat.format(startTime);
//     final attendeesCount = (event.attendees?.length ?? 0).clamp(0, 999);

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               blurRadius: 16,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Stack(
//           children: [
//             // Background Image
//             ClipRRect(
//               borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
//               child: Container(
//                 color: AppColors.getSurface(isDark),
//                 child: event.imageUrl != null && event.imageUrl!.isNotEmpty
//                     ? Image.network(
//                         event.imageUrl!,
//                         width: double.infinity,
//                         height: double.infinity,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Center(
//                             child: Icon(
//                               Icons.event_rounded,
//                               size: AppSizes.iconXxl,
//                               color: AppColors.getTextSecondary(
//                                 isDark,
//                               ).withOpacity(0.5),
//                             ),
//                           );
//                         },
//                       )
//                     : Center(
//                         child: Icon(
//                           Icons.event_rounded,
//                           size: AppSizes.iconXxl,
//                           color: AppColors.getTextSecondary(
//                             isDark,
//                           ).withOpacity(0.5),
//                         ),
//                       ),
//               ),
//             ),

//             // Gradient Overlay
//             ClipRRect(
//               borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
//                   ),
//                 ),
//               ),
//             ),

//             // Favorite Button
//             Positioned(
//               top: AppSizes.paddingMedium,
//               right: AppSizes.paddingMedium,
//               child: GestureDetector(
//                 onTap: onFavoriteTap,
//                 child: Container(
//                   padding: EdgeInsets.all(AppSizes.paddingSmall),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.4),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     isFavorite ? Icons.favorite : Icons.favorite_border,
//                     color: isFavorite ? Colors.red : Colors.white,
//                     size: AppSizes.iconMedium,
//                   ),
//                 ),
//               ),
//             ),

//             // Content at Bottom
//             Positioned(
//               bottom: 0,
//               left: 0,
//               right: 0,
//               child: Padding(
//                 padding: EdgeInsets.all(AppSizes.paddingLarge),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       event.title ?? 'Event',
//                       style: AppTextStyles.headingSmall(isDark: false).copyWith(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w900,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     SizedBox(height: AppSizes.spacingSmall),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.calendar_today_rounded,
//                           color: Colors.white70,
//                           size: AppSizes.iconSmall,
//                         ),
//                         SizedBox(width: AppSizes.spacingXs),
//                         Expanded(
//                           child: Text(
//                             formattedDate,
//                             style: AppTextStyles.bodySmall(
//                               isDark: false,
//                             ).copyWith(color: Colors.white70),
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: AppSizes.spacingSmall),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.people_rounded,
//                           color: Colors.white70,
//                           size: AppSizes.iconSmall,
//                         ),
//                         SizedBox(width: AppSizes.spacingXs),
//                         Expanded(
//                           child: Text(
//                             '$attendeesCount going',
//                             style: AppTextStyles.bodySmall(
//                               isDark: false,
//                             ).copyWith(color: Colors.white70),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Small Event Card List with Smooth Scrolling

// class _SmallEventCardList extends ConsumerWidget {
//   final List events;
//   final bool isDark;

//   const _SmallEventCardList({required this.events, required this.isDark});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final favorites = ref.watch(favoritesProvider);

//     if (events.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     return SizedBox(
//       height: 260,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         physics: const BouncingScrollPhysics(),
//         padding: EdgeInsets.symmetric(
//           horizontal: AppSizes.screenPaddingHorizontal,
//         ),
//         itemCount: events.length,
//         itemBuilder: (context, index) {
//           final event = events[index];
//           if (event == null) return const SizedBox(width: 10);

//           final isFavorite = favorites.contains(event.id ?? '');

//           return Padding(
//             padding: EdgeInsets.only(
//               right: index == events.length - 1 ? 0 : AppSizes.spacingMedium,
//             ),
//             child: _SmallEventCard(
//               event: event,
//               isDark: isDark,
//               isFavorite: isFavorite,
//               onFavoriteTap: () {
//                 try {
//                   ref
//                       .read(favoritesProvider.notifier)
//                       .toggleFavorite(event.id ?? '');
//                   showFavoriteSnackbarSafe(
//                     context,
//                     isFavorite,
//                     event.title ?? 'Event',
//                   );
//                 } catch (e) {
//                   // Handle error
//                 }
//               },
//               onTap: () {
//                 try {
//                   context.push('/event-detail', extra: event);
//                 } catch (e) {
//                   // Handle error
//                 }
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // Small Event Card (MORE ROUNDED)

// class _SmallEventCard extends StatelessWidget {
//   final dynamic event;
//   final bool isDark;
//   final bool isFavorite;
//   final VoidCallback onFavoriteTap;
//   final VoidCallback onTap;

//   const _SmallEventCard({
//     required this.event,
//     required this.isDark,
//     required this.isFavorite,
//     required this.onFavoriteTap,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     DateTime startTime = event.startTime ?? DateTime.now();
//     final dateFormat = DateFormat('MMM d');
//     final formattedDate = dateFormat.format(startTime);
//     final attendeesCount = (event.attendees?.length ?? 0).clamp(0, 999);

//     return GestureDetector(
//       onTap: onTap,
//       child: SizedBox(
//         width: 160,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Image Container
//             SizedBox(
//               height: 180,
//               child: Stack(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(24),
//                     child: Container(
//                       width: double.infinity,
//                       height: double.infinity,
//                       color: AppColors.getSurface(isDark),
//                       child:
//                           event.imageUrl != null && event.imageUrl!.isNotEmpty
//                           ? Image.network(
//                               event.imageUrl!,
//                               width: double.infinity,
//                               height: double.infinity,
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) {
//                                 return Center(
//                                   child: Icon(
//                                     Icons.event_rounded,
//                                     color: AppColors.getTextSecondary(
//                                       isDark,
//                                     ).withOpacity(0.5),
//                                   ),
//                                 );
//                               },
//                             )
//                           : Center(
//                               child: Icon(
//                                 Icons.event_rounded,
//                                 color: AppColors.getTextSecondary(
//                                   isDark,
//                                 ).withOpacity(0.5),
//                               ),
//                             ),
//                     ),
//                   ),
//                   Positioned(
//                     top: AppSizes.paddingXs,
//                     left: AppSizes.paddingXs,
//                     child: Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: AppSizes.paddingSmall,
//                         vertical: AppSizes.paddingXs / 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(
//                           AppSizes.radiusSmall,
//                         ),
//                       ),
//                       child: Text(
//                         formattedDate,
//                         style: AppTextStyles.labelSmall(
//                           isDark: false,
//                         ).copyWith(fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     top: AppSizes.paddingXs,
//                     right: AppSizes.paddingXs,
//                     child: GestureDetector(
//                       onTap: onFavoriteTap,
//                       child: Container(
//                         padding: EdgeInsets.all(AppSizes.paddingXs),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.3),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           isFavorite ? Icons.favorite : Icons.favorite_border,
//                           color: isFavorite ? Colors.red : Colors.white,
//                           size: AppSizes.iconSmall,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: AppSizes.spacingXs),
//             Text(
//               event.title ?? 'Event',
//               style: AppTextStyles.titleSmall(
//                 isDark: isDark,
//               ).copyWith(fontWeight: FontWeight.w700),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             SizedBox(height: AppSizes.spacingXs / 2),
//             Text(
//               event.location ?? 'Unknown',
//               style: AppTextStyles.bodySmall(isDark: isDark),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             SizedBox(height: AppSizes.spacingXs),
//             Row(
//               children: [
//                 Icon(
//                   Icons.people_rounded,
//                   size: 12,
//                   color: AppColors.getPrimary(isDark),
//                 ),
//                 SizedBox(width: AppSizes.spacingXs / 2),
//                 Expanded(
//                   child: Text(
//                     '$attendeesCount going',
//                     style: AppTextStyles.labelSmall(
//                       isDark: isDark,
//                     ).copyWith(color: AppColors.getPrimary(isDark)),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Nearby Events Section (FIXED)

// class _NearbyEventsSection extends ConsumerWidget {
//   final AsyncValue eventsAsync;
//   final bool isDark;

//   const _NearbyEventsSection({required this.eventsAsync, required this.isDark});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final locationState = ref.watch(locationStateProvider);
//     final favorites = ref.watch(favoritesProvider);

//     if (locationState.isServiceDisabled) {
//       return _LocationServiceDisabledState(
//         isDark: isDark,
//         onEnableLocation: () async {
//           try {
//             final notifier = ref.read(locationStateProvider.notifier);
//             await notifier.openLocationSettings();
//             await Future.delayed(const Duration(seconds: 1));
//             notifier.retry();
//           } catch (e) {
//             // Handle error
//           }
//         },
//       );
//     }

//     if (locationState.isDenied) {
//       return _LocationDeniedState(
//         isDark: isDark,
//         onRetry: () async {
//           try {
//             final notifier = ref.read(locationStateProvider.notifier);
//             await notifier.openAppSettings();
//             await Future.delayed(const Duration(seconds: 1));
//             notifier.retry();
//           } catch (e) {
//             // Handle error
//           }
//         },
//       );
//     }

//     if (locationState.isLoading || locationState.position == null) {
//       return _SmallCardShimmer(isDark: isDark);
//     }

//     return eventsAsync.when(
//       data: (events) {
//         final nearbyEvents = (events ?? []).where((e) => e != null).toList();

//         if (nearbyEvents.isEmpty) {
//           return _EmptyState(
//             message: 'No nearby events found',
//             icon: Icons.location_off_rounded,
//             isDark: isDark,
//           );
//         }

//         // SAFE SORTING
//         nearbyEvents.sort((a, b) {
//           try {
//             final distA = Geolocator.distanceBetween(
//               locationState.position!.latitude,
//               locationState.position!.longitude,
//               (a?.latitude ?? 0.0),
//               (a?.longitude ?? 0.0),
//             );
//             final distB = Geolocator.distanceBetween(
//               locationState.position!.latitude,
//               locationState.position!.longitude,
//               (b?.latitude ?? 0.0),
//               (b?.longitude ?? 0.0),
//             );
//             return distA.compareTo(distB);
//           } catch (e) {
//             return 0;
//           }
//         });

//         return SizedBox(
//           height: 260,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             physics: const BouncingScrollPhysics(),
//             padding: EdgeInsets.symmetric(
//               horizontal: AppSizes.screenPaddingHorizontal,
//             ),
//             itemCount: nearbyEvents.length,
//             itemBuilder: (context, index) {
//               final event = nearbyEvents[index];
//               if (event == null) return const SizedBox(width: 10);

//               final isFavorite = favorites.contains(event.id ?? '');

//               try {
//                 final distanceMeters = Geolocator.distanceBetween(
//                   locationState.position!.latitude,
//                   locationState.position!.longitude,
//                   event.latitude ?? 0.0,
//                   event.longitude ?? 0.0,
//                 );
//                 final distanceKm = (distanceMeters / 1000).toStringAsFixed(1);

//                 return Padding(
//                   padding: EdgeInsets.only(
//                     right: index == nearbyEvents.length - 1
//                         ? 0
//                         : AppSizes.spacingMedium,
//                   ),
//                   child: _NearbySmallEventCard(
//                     event: event,
//                     isDark: isDark,
//                     distanceKm: distanceKm,
//                     isFavorite: isFavorite,
//                     onFavoriteTap: () {
//                       try {
//                         ref
//                             .read(favoritesProvider.notifier)
//                             .toggleFavorite(event.id ?? '');
//                         showFavoriteSnackbarSafe(
//                           context,
//                           isFavorite,
//                           event.title ?? 'Event',
//                         );
//                       } catch (e) {
//                         // Handle error
//                       }
//                     },
//                     onTap: () {
//                       try {
//                         context.push('/event-detail', extra: event);
//                       } catch (e) {
//                         // Handle error
//                       }
//                     },
//                   ),
//                 );
//               } catch (e) {
//                 return const SizedBox(width: 10);
//               }
//             },
//           ),
//         );
//       },
//       loading: () => _SmallCardShimmer(isDark: isDark),
//       error: (_, __) => _ErrorState(
//         message: 'Failed to load nearby events',
//         onRetry: () => ref.refresh(approvedEventsStreamProvider),
//         isDark: isDark,
//       ),
//     );
//   }
// }

// // Nearby Small Event Card with Distance

// class _NearbySmallEventCard extends StatelessWidget {
//   final dynamic event;
//   final bool isDark;
//   final String distanceKm;
//   final bool isFavorite;
//   final VoidCallback onFavoriteTap;
//   final VoidCallback onTap;

//   const _NearbySmallEventCard({
//     required this.event,
//     required this.isDark,
//     required this.distanceKm,
//     required this.isFavorite,
//     required this.onFavoriteTap,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     DateTime startTime = event.startTime ?? DateTime.now();
//     final dateFormat = DateFormat('MMM d');
//     final formattedDate = dateFormat.format(startTime);
//     final distance = double.tryParse(distanceKm) ?? 0;
//     final Color distanceColor = distance <= 40 ? Colors.green : Colors.orange;

//     return GestureDetector(
//       onTap: onTap,
//       child: SizedBox(
//         width: 160,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(
//               height: 180,
//               child: Stack(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
//                     child: Container(
//                       width: double.infinity,
//                       height: double.infinity,
//                       color: AppColors.getSurface(isDark),
//                       child:
//                           event.imageUrl != null && event.imageUrl!.isNotEmpty
//                           ? Image.network(
//                               event.imageUrl!,
//                               width: double.infinity,
//                               height: double.infinity,
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) {
//                                 return Center(
//                                   child: Icon(
//                                     Icons.event_rounded,
//                                     color: AppColors.getTextSecondary(
//                                       isDark,
//                                     ).withOpacity(0.5),
//                                   ),
//                                 );
//                               },
//                             )
//                           : Center(
//                               child: Icon(
//                                 Icons.event_rounded,
//                                 color: AppColors.getTextSecondary(
//                                   isDark,
//                                 ).withOpacity(0.5),
//                               ),
//                             ),
//                     ),
//                   ),
//                   Positioned(
//                     top: AppSizes.paddingXs,
//                     left: AppSizes.paddingXs,
//                     child: Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: AppSizes.paddingSmall,
//                         vertical: AppSizes.paddingXs / 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(
//                           AppSizes.radiusSmall,
//                         ),
//                       ),
//                       child: Text(
//                         formattedDate,
//                         style: AppTextStyles.labelSmall(
//                           isDark: false,
//                         ).copyWith(fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     top: AppSizes.paddingXs,
//                     right: AppSizes.paddingXs,
//                     child: GestureDetector(
//                       onTap: onFavoriteTap,
//                       child: Container(
//                         padding: EdgeInsets.all(AppSizes.paddingXs),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.3),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           isFavorite ? Icons.favorite : Icons.favorite_border,
//                           color: isFavorite ? Colors.red : Colors.white,
//                           size: AppSizes.iconSmall,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: AppSizes.spacingXs),
//             Text(
//               event.title ?? 'Event',
//               style: AppTextStyles.titleSmall(
//                 isDark: isDark,
//               ).copyWith(fontWeight: FontWeight.w700),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             SizedBox(height: AppSizes.spacingXs / 2),
//             Text(
//               event.location ?? 'Unknown',
//               style: AppTextStyles.bodySmall(isDark: isDark),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             SizedBox(height: AppSizes.spacingXs),
//             Row(
//               children: [
//                 Icon(Icons.location_on_rounded, size: 12, color: distanceColor),
//                 SizedBox(width: AppSizes.spacingXs / 2),
//                 Expanded(
//                   child: Text(
//                     '$distanceKm km away',
//                     style: AppTextStyles.labelSmall(
//                       isDark: isDark,
//                     ).copyWith(color: distanceColor),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Top City Events Section (FIXED)

// class _TopCityEventsSection extends ConsumerWidget {
//   final AsyncValue eventsAsync;
//   final bool isDark;
//   final String cityName;

//   const _TopCityEventsSection({
//     required this.eventsAsync,
//     required this.isDark,
//     required this.cityName,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final favorites = ref.watch(favoritesProvider);

//     return eventsAsync.when(
//       data: (events) {
//         final allEvents = events ?? [];
//         List<dynamic> cityEvents = allEvents
//             .where(
//               (event) =>
//                   event != null &&
//                   event.location?.toLowerCase().contains(
//                         cityName.toLowerCase(),
//                       ) ==
//                       true,
//             )
//             .toList();

//         if (cityEvents.isEmpty) {
//           return _EmptyState(
//             message: 'No events in $cityName',
//             icon: Icons.location_off_rounded,
//             isDark: isDark,
//           );
//         }

//         try {
//           cityEvents.sort(
//             (a, b) => (b?.attendees?.length ?? 0).compareTo(
//               a?.attendees?.length ?? 0,
//             ),
//           );
//         } catch (e) {
//           // Fallback if sort fails
//         }

//         final topEvents = cityEvents.take(10).toList();

//         return SizedBox(
//           height: 260,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             physics: const BouncingScrollPhysics(),
//             padding: EdgeInsets.symmetric(
//               horizontal: AppSizes.screenPaddingHorizontal,
//             ),
//             itemCount: topEvents.length,
//             itemBuilder: (context, index) {
//               final event = topEvents[index];
//               if (event == null) return const SizedBox(width: 10);

//               final isFavorite = favorites.contains(event.id ?? '');
//               final attendeesCount = (event.attendees?.length ?? 0).clamp(
//                 0,
//                 999,
//               );

//               return Padding(
//                 padding: EdgeInsets.only(
//                   right: index == topEvents.length - 1
//                       ? 0
//                       : AppSizes.spacingMedium,
//                 ),
//                 child: _TopCitySmallEventCard(
//                   event: event,
//                   isDark: isDark,
//                   rating: (4.5 + (attendeesCount % 5) * 0.1).toStringAsFixed(1),
//                   isFavorite: isFavorite,
//                   onFavoriteTap: () {
//                     try {
//                       ref
//                           .read(favoritesProvider.notifier)
//                           .toggleFavorite(event.id ?? '');
//                       showFavoriteSnackbarSafe(
//                         context,
//                         isFavorite,
//                         event.title ?? 'Event',
//                       );
//                     } catch (e) {
//                       // Handle error
//                     }
//                   },
//                   onTap: () {
//                     try {
//                       context.push('/event-detail', extra: event);
//                     } catch (e) {
//                       // Handle error
//                     }
//                   },
//                 ),
//               );
//             },
//           ),
//         );
//       },
//       loading: () => _SmallCardShimmer(isDark: isDark),
//       error: (_, __) => _EmptyState(
//         message: 'Failed to load events',
//         icon: Icons.error_outline_rounded,
//         isDark: isDark,
//       ),
//     );
//   }
// }

// // Top City Small Event Card with Rating

// class _TopCitySmallEventCard extends StatelessWidget {
//   final dynamic event;
//   final bool isDark;
//   final String rating;
//   final bool isFavorite;
//   final VoidCallback onFavoriteTap;
//   final VoidCallback onTap;

//   const _TopCitySmallEventCard({
//     required this.event,
//     required this.isDark,
//     required this.rating,
//     required this.isFavorite,
//     required this.onFavoriteTap,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     DateTime startTime = event.startTime ?? DateTime.now();
//     final dateFormat = DateFormat('MMM d');
//     final formattedDate = dateFormat.format(startTime);
//     final attendeesCount = (event.attendees?.length ?? 0).clamp(0, 999);

//     return GestureDetector(
//       onTap: onTap,
//       child: SizedBox(
//         width: 160,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(
//               height: 180,
//               child: Stack(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
//                     child: Container(
//                       width: double.infinity,
//                       height: double.infinity,
//                       color: AppColors.getSurface(isDark),
//                       child:
//                           event.imageUrl != null && event.imageUrl!.isNotEmpty
//                           ? Image.network(
//                               event.imageUrl!,
//                               width: double.infinity,
//                               height: double.infinity,
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) {
//                                 return Center(
//                                   child: Icon(
//                                     Icons.event_rounded,
//                                     color: AppColors.getTextSecondary(
//                                       isDark,
//                                     ).withOpacity(0.5),
//                                   ),
//                                 );
//                               },
//                             )
//                           : Center(
//                               child: Icon(
//                                 Icons.event_rounded,
//                                 color: AppColors.getTextSecondary(
//                                   isDark,
//                                 ).withOpacity(0.5),
//                               ),
//                             ),
//                     ),
//                   ),
//                   Positioned(
//                     top: AppSizes.paddingXs,
//                     left: AppSizes.paddingXs,
//                     child: Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: AppSizes.paddingSmall,
//                         vertical: AppSizes.paddingXs / 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(
//                           AppSizes.radiusSmall,
//                         ),
//                       ),
//                       child: Text(
//                         formattedDate,
//                         style: AppTextStyles.labelSmall(
//                           isDark: false,
//                         ).copyWith(fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     top: AppSizes.paddingXs,
//                     right: AppSizes.paddingXs,
//                     child: GestureDetector(
//                       onTap: onFavoriteTap,
//                       child: Container(
//                         padding: EdgeInsets.all(AppSizes.paddingXs),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.3),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           isFavorite ? Icons.favorite : Icons.favorite_border,
//                           color: isFavorite ? Colors.red : Colors.white,
//                           size: AppSizes.iconSmall,
//                         ),
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     bottom: AppSizes.paddingXs,
//                     right: AppSizes.paddingXs,
//                     child: Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: AppSizes.paddingXs,
//                         vertical: AppSizes.paddingXs / 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.amber,
//                         borderRadius: BorderRadius.circular(
//                           AppSizes.radiusSmall,
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             Icons.star_rounded,
//                             size: 10,
//                             color: Colors.white,
//                           ),
//                           SizedBox(width: 2),
//                           Text(
//                             rating,
//                             style: AppTextStyles.labelSmall(isDark: false)
//                                 .copyWith(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: AppSizes.spacingXs),
//             Text(
//               event.title ?? 'Event',
//               style: AppTextStyles.titleSmall(
//                 isDark: isDark,
//               ).copyWith(fontWeight: FontWeight.w700),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             SizedBox(height: AppSizes.spacingXs / 2),
//             Text(
//               event.location ?? 'Unknown',
//               style: AppTextStyles.bodySmall(isDark: isDark),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             SizedBox(height: AppSizes.spacingXs),
//             Row(
//               children: [
//                 Icon(
//                   Icons.people_rounded,
//                   size: 12,
//                   color: AppColors.getPrimary(isDark),
//                 ),
//                 SizedBox(width: AppSizes.spacingXs / 2),
//                 Expanded(
//                   child: Text(
//                     '$attendeesCount going',
//                     style: AppTextStyles.labelSmall(
//                       isDark: isDark,
//                     ).copyWith(color: AppColors.getPrimary(isDark)),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Section Header

// class _SectionHeader extends StatelessWidget {
//   final String title;
//   final bool isDark;
//   final VoidCallback onViewAll;

//   const _SectionHeader({
//     required this.title,
//     required this.isDark,
//     required this.onViewAll,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: AppSizes.screenPaddingHorizontal,
//       ),
//       child: Row(
//         children: [
//           TextButton(
//             onPressed: onViewAll,
//             child: Text(
//               title,
//               style: AppTextStyles.headingxSmall(isDark: isDark),
//             ),
//           ),
//           SizedBox(width: 10.w),
//           InkWell(
//             onTap: onViewAll,
//             child: Icon(
//               Icons.arrow_forward_ios_rounded,
//               size: AppSizes.iconSmall,
//               color: AppColors.getTextPrimary(isDark),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Location Service Disabled State

// class _LocationServiceDisabledState extends StatelessWidget {
//   final bool isDark;
//   final VoidCallback onEnableLocation;

//   const _LocationServiceDisabledState({
//     required this.isDark,
//     required this.onEnableLocation,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.symmetric(
//         horizontal: AppSizes.screenPaddingHorizontal,
//       ),
//       padding: EdgeInsets.all(AppSizes.paddingXxl),
//       decoration: BoxDecoration(
//         color: AppColors.getCard(isDark),
//         borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
//         border: Border.all(color: AppColors.getBorder(isDark)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.location_off_rounded,
//             size: AppSizes.iconXxl,
//             color: AppColors.getWarning(isDark),
//           ),
//           SizedBox(height: AppSizes.spacingLarge),
//           Text(
//             'Location Service Disabled',
//             style: AppTextStyles.titleMedium(
//               isDark: isDark,
//             ).copyWith(fontWeight: FontWeight.w700),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: AppSizes.spacingSmall),
//           Text(
//             'Please turn on location services to discover events near you',
//             style: AppTextStyles.bodyMedium(isDark: isDark),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: AppSizes.spacingXl),
//           ElevatedButton.icon(
//             onPressed: onEnableLocation,
//             icon: Icon(Icons.location_on_rounded, size: AppSizes.iconSmall),
//             label: const Text('Turn On Location'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.getPrimary(isDark),
//               foregroundColor: Colors.white,
//               padding: EdgeInsets.symmetric(
//                 horizontal: AppSizes.paddingXxl,
//                 vertical: AppSizes.paddingMedium,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Location Denied State

// class _LocationDeniedState extends StatelessWidget {
//   final bool isDark;
//   final VoidCallback onRetry;

//   const _LocationDeniedState({required this.isDark, required this.onRetry});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.symmetric(
//         horizontal: AppSizes.screenPaddingHorizontal,
//       ),
//       padding: EdgeInsets.all(AppSizes.paddingXxl),
//       decoration: BoxDecoration(
//         color: AppColors.getCard(isDark),
//         borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
//         border: Border.all(color: AppColors.getBorder(isDark)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.location_off_rounded,
//             size: AppSizes.iconXxl,
//             color: AppColors.getError(isDark),
//           ),
//           SizedBox(height: AppSizes.spacingLarge),
//           Text(
//             'Location Permission Denied',
//             style: AppTextStyles.titleMedium(
//               isDark: isDark,
//             ).copyWith(fontWeight: FontWeight.w700),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: AppSizes.spacingSmall),
//           Text(
//             'Grant location permission in settings to find nearby events',
//             style: AppTextStyles.bodyMedium(isDark: isDark),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: AppSizes.spacingXl),
//           ElevatedButton.icon(
//             onPressed: onRetry,
//             icon: Icon(Icons.settings_rounded, size: AppSizes.iconSmall),
//             label: const Text('Open Settings'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.getPrimary(isDark),
//               foregroundColor: Colors.white,
//               padding: EdgeInsets.symmetric(
//                 horizontal: AppSizes.paddingXxl,
//                 vertical: AppSizes.paddingMedium,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Banner Shimmer

// class _BannerShimmer extends StatelessWidget {
//   final bool isDark;

//   const _BannerShimmer({required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 240,
//       child: Shimmer.fromColors(
//         baseColor: AppColors.getShimmerBase(isDark),
//         highlightColor: AppColors.getShimmerHighlight(isDark),
//         child: Container(
//           margin: EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
//           decoration: BoxDecoration(
//             color: AppColors.getSurface(isDark),
//             borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Small Card Shimmer

// class _SmallCardShimmer extends StatelessWidget {
//   final bool isDark;

//   const _SmallCardShimmer({required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 260,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         physics: const NeverScrollableScrollPhysics(),
//         padding: EdgeInsets.symmetric(
//           horizontal: AppSizes.screenPaddingHorizontal,
//         ),
//         itemCount: 3,
//         itemBuilder: (context, index) {
//           return Padding(
//             padding: EdgeInsets.only(right: AppSizes.spacingMedium),
//             child: SizedBox(
//               width: 160,
//               child: Shimmer.fromColors(
//                 baseColor: AppColors.getShimmerBase(isDark),
//                 highlightColor: AppColors.getShimmerHighlight(isDark),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: AppColors.getSurface(isDark),
//                           borderRadius: BorderRadius.circular(24),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: AppSizes.spacingXs),
//                     Container(
//                       width: double.infinity,
//                       height: 12,
//                       color: AppColors.getSurface(isDark),
//                     ),
//                     SizedBox(height: AppSizes.spacingXs),
//                     Container(
//                       width: 100,
//                       height: 10,
//                       color: AppColors.getSurface(isDark),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // Empty State Widget

// class _EmptyState extends StatelessWidget {
//   final String message;
//   final IconData icon;
//   final bool isDark;

//   const _EmptyState({
//     required this.message,
//     required this.icon,
//     required this.isDark,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.all(AppSizes.paddingXxl),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             icon,
//             size: AppSizes.iconXxl,
//             color: AppColors.getTextSecondary(isDark),
//           ),
//           SizedBox(height: AppSizes.spacingLarge),
//           Text(message, style: AppTextStyles.bodyMedium(isDark: isDark)),
//         ],
//       ),
//     );
//   }
// }

// // Error State Widget

// class _ErrorState extends StatelessWidget {
//   final String message;
//   final VoidCallback onRetry;
//   final bool isDark;

//   const _ErrorState({
//     required this.message,
//     required this.onRetry,
//     required this.isDark,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.all(AppSizes.paddingXxl),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.error_outline_rounded,
//             size: AppSizes.iconXxl,
//             color: AppColors.getError(isDark),
//           ),
//           SizedBox(height: AppSizes.spacingLarge),
//           Text(
//             message,
//             style: AppTextStyles.bodyMedium(isDark: isDark),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: AppSizes.spacingLarge),
//           TextButton(onPressed: onRetry, child: const Text('Try Again')),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/util/theme_util.dart';
import 'package:sync_event/features/events/presentation/providers/event_providers.dart';
import 'package:sync_event/features/home/presentation/providers/location_provider.dart';
import 'package:sync_event/features/home/presentation/screen/filter_bottom_sheet.dart';
import 'package:sync_event/features/home/presentation/widgets/section_widgets/banner_shimmer_widget.dart';
import 'package:sync_event/features/home/presentation/widgets/section_widgets/empty_state_widget.dart';
import 'package:sync_event/features/home/presentation/widgets/section_widgets/error_state_widget.dart';
import 'package:sync_event/features/home/presentation/widgets/section_widgets/nearby_events_section_widget.dart';
import 'package:sync_event/features/home/presentation/widgets/section_widgets/popular_events_banner_widget.dart';
import 'package:sync_event/features/home/presentation/widgets/section_widgets/section_header_widget.dart';
import 'package:sync_event/features/home/presentation/widgets/section_widgets/small_card_shimmer_widget.dart';
import 'package:sync_event/features/home/presentation/widgets/section_widgets/small_event_card_list_widget.dart';
import 'package:sync_event/features/home/presentation/widgets/section_widgets/top_city_events_section.dart';

class EventSection extends ConsumerWidget {
  const EventSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(approvedEventsStreamProvider);
    final isDark = ThemeUtils.isDark(context);
    final userCityAsync = ref.watch(userCityProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSizes.spacingXxl),

          // 1. POPULAR EVENTS BANNER
          SectionHeader(
            title: 'Upcoming Popular Events',
            isDark: isDark,
            onViewAll: () {
              ref.read(eventFilterProvider.notifier).reset();
              context.push('/events');
            },
          ),
          SizedBox(height: AppSizes.spacingLarge),

          eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return EmptyState(
                  message: 'No events available',
                  icon: Icons.event_busy_rounded,
                  isDark: isDark,
                );
              }

              // ignore: unnecessary_null_comparison
              final sortedEvents = List.from(events.where((e) => e != null))
                ..sort(
                  (a, b) => (a?.startTime ?? DateTime.now()).compareTo(
                    b?.startTime ?? DateTime.now(),
                  ),
                );

              if (sortedEvents.isEmpty) {
                return EmptyState(
                  message: 'No events available',
                  icon: Icons.event_busy_rounded,
                  isDark: isDark,
                );
              }

              return PopularEventsBanner(
                events: sortedEvents.take(10).toList(),
                isDark: isDark,
              );
            },
            loading: () => BannerShimmer(isDark: isDark),
            error: (error, _) => ErrorState(
              message: 'Failed to load events',
              onRetry: () => ref.refresh(approvedEventsStreamProvider),
              isDark: isDark,
            ),
          ),

          SizedBox(height: AppSizes.spacingXxxl),

          // 2. NEARBY EVENTS
          SectionHeader(
            title: 'Popular Events Near You',
            isDark: isDark,
            onViewAll: () => context.push('/events'),
          ),
          SizedBox(height: AppSizes.spacingLarge),
          NearbyEventsSection(eventsAsync: eventsAsync, isDark: isDark),

          SizedBox(height: AppSizes.spacingXl),

          // 3. SPORTS EVENTS
          SectionHeader(
            title: 'Sports Events',
            isDark: isDark,
            onViewAll: () {
              ref.read(eventFilterProvider.notifier).updateCategories([
                'Sports',
              ]);
              context.push('/events');
            },
          ),
          SizedBox(height: AppSizes.spacingLarge),

          eventsAsync.when(
            data: (events) {
              final sportEvents = events
                  .where(
                    (event) =>
                        event.category.toLowerCase() == 'sports' ||event.category.toLowerCase() == 't20 world cup 2026' ||
                        event.category.toLowerCase().contains('sport'),
                  )
                  .take(10)
                  .toList();

              if (sportEvents.isEmpty) {
                return EmptyState(
                  message: 'No sports events available',
                  icon: Icons.sports_basketball_rounded,
                  isDark: isDark,
                );
              }

              return SmallEventCardList(events: sportEvents, isDark: isDark);
            },
            loading: () => SmallCardShimmer(isDark: isDark),
            error: (_, __) => const SizedBox.shrink(),
          ),

          SizedBox(height: AppSizes.spacingXl),

          // 3. Movie EVENTS
          SectionHeader(
            title: 'Movie Events',
            isDark: isDark,
            onViewAll: () {
              ref.read(eventFilterProvider.notifier).updateCategories([
                'Movie',
              ]);
              context.push('/events');
            },
          ),
          SizedBox(height: AppSizes.spacingLarge),

          eventsAsync.when(
            data: (events) {
              final movieEvents = events
                  .where(
                    (event) =>
                        event.category.toLowerCase() == 'movie' ||
                        event.category.toLowerCase().contains('movie'),
                  )
                  .take(10)
                  .toList();

              if (movieEvents.isEmpty) {
                return EmptyState(
                  message: 'No movie events available',
                  icon: Icons.movie_rounded,
                  isDark: isDark,
                );
              }

              return SmallEventCardList(events: movieEvents, isDark: isDark);
            },
            loading: () => SmallCardShimmer(isDark: isDark),
            error: (_, __) => const SizedBox.shrink(),
          ),

          SizedBox(height: AppSizes.spacingXl),

          // 4. MUSIC EVENTS
          SectionHeader(
            title: 'Music Events',
            isDark: isDark,
            onViewAll: () {
              ref.read(eventFilterProvider.notifier).updateCategories([
                'Music',
              ]);
              context.push('/events');
            },
          ),
          SizedBox(height: AppSizes.spacingLarge),

          eventsAsync.when(
            data: (events) {
              final musicEvents = events
                  .where(
                    (event) =>
                        event.category.toLowerCase() == 'music' ||
                        event.category.toLowerCase().contains('music'),
                  )
                  .take(10)
                  .toList();

              if (musicEvents.isEmpty) {
                return EmptyState(
                  message: 'No music events available',
                  icon: Icons.music_note_rounded,
                  isDark: isDark,
                );
              }

              return SmallEventCardList(events: musicEvents, isDark: isDark);
            },
            loading: () => SmallCardShimmer(isDark: isDark),
            error: (_, __) => const SizedBox.shrink(),
          ),

          SizedBox(height: AppSizes.spacingXl),

          // 5. FREE EVENTS
          SectionHeader(
            title: 'Free Events',
            isDark: isDark,
            onViewAll: () {
              ref.read(eventFilterProvider.notifier).updatePriceRange(0, 0);
              context.push('/events');
            },
          ),
          SizedBox(height: AppSizes.spacingLarge),

          eventsAsync.when(
            data: (events) {
              final freeEvents = events
                  .where((event) => (event.ticketPrice ?? 0) == 0)
                  .take(10)
                  .toList();

              if (freeEvents.isEmpty) {
                return EmptyState(
                  message: 'No free events available',
                  icon: Icons.local_offer_rounded,
                  isDark: isDark,
                );
              }

              return SmallEventCardList(events: freeEvents, isDark: isDark);
            },
            loading: () => SmallCardShimmer(isDark: isDark),
            error: (_, __) => const SizedBox.shrink(),
          ),

          SizedBox(height: AppSizes.spacingXl),

          // 6. TOP IN USER'S CITY
          userCityAsync.when(
            data: (userCity) {
              return Column(
                children: [
                  SectionHeader(
                    title: 'Top in $userCity',
                    isDark: isDark,
                    onViewAll: () {
                      ref
                          .read(eventFilterProvider.notifier)
                          .updateLocation(userCity);
                      context.push('/events');
                    },
                  ),
                  SizedBox(height: AppSizes.spacingLarge),
                  TopCityEventsSection(
                    eventsAsync: eventsAsync,
                    isDark: isDark,
                    cityName: userCity,
                  ),
                  SizedBox(height: AppSizes.spacingXxxl),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
