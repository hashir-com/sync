import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, Factory; // Fixed: Only kIsWeb from foundation
import 'package:flutter/gestures.dart'
    show
        OneSequenceGestureRecognizer,
        EagerGestureRecognizer; // Gestures for Factory, etc.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sync_event/features/events/domain/entities/event_entity.dart';
import 'package:sync_event/features/map/domain/services/location_service.dart';
import 'package:sync_event/features/map/presentation/widgets/event_card.dart';
import 'package:sync_event/features/map/presentation/widgets/loading_indicator.dart';
import 'package:sync_event/features/map/presentation/widgets/search_bar.dart';
import 'package:sync_event/features/map/presentation/widgets/search_results.dart';
import 'package:sync_event/features/map/presentation/provider/map_providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LocationService _locationService = LocationService();
  bool _listenerSetup = false;
  GoogleMapController? _mapController; // Local controller reference
  bool _isMapInitialized = false; // Flag: Set initial position only once
  LatLng? _lastTarget; // Preserve last target across rebuilds
  double _lastZoom = 12.0; // Preserve last zoom
  double _lastTilt = 0.0; // Preserve last tilt (flat for stability)

  @override
  void initState() {
    super.initState();
    _initializeSearchController();
  }
  

  void _initializeSearchController() {
    _searchController.addListener(() {
      final currentText = _searchController.text;
      if (ref.read(searchQueryProvider) != currentText) {
        ref.read(searchQueryProvider.notifier).state = currentText;
        print('MapScreen: Search query updated to "$currentText"');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsMapProvider);
    final selectedEvent = ref.watch(selectedEventProvider);

    if (!_listenerSetup) {
      _setupEventListener();
      _listenerSetup = true;
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildMap(eventsAsync),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SearchBarWidget(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onLocateTap: _handleLocateMe,
              ),
            ),
            Positioned(
              top: 90,
              left: 16,
              right: 16,
              child: const SearchResultsWidget(),
            ),
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: const Center(child: LoadingIndicatorWidget()),
            ),
            if (selectedEvent != null)
  Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1.0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: EventDetailCard(  //  FIXED - No Positioned here
        key: ValueKey(selectedEvent.id),
        event: selectedEvent,
      ),
    ),
  ),
          ],
        ),
      ),
    );
  }

  // BuildMap: Render Google Map with markers
  // CRITICAL FIX: Use switch for exhaustive handling and compiler satisfaction
  Widget _buildMap(AsyncValue<List<EventEntity>> eventsAsync) {
    return switch (eventsAsync) {
      AsyncData(value: final events) => _buildMapData(events),
      const AsyncLoading() => const Center(child: CircularProgressIndicator()),
      AsyncError(error: final err) => _buildMapError(err),
      // TODO: Handle this case.
      AsyncValue<List<EventEntity>>() => throw UnimplementedError(),
    };
  }

  // Build map data widget
  Widget _buildMapData(List<EventEntity> events) {
    // CRITICAL: Only log on significant changes (debounce rebuild logs)
    if (events.isNotEmpty) {
      print('MapScreen: Rendering map with ${events.length} events');
    }

    final markers = ref.watch(markerStateProvider);

    return GoogleMap(
      key: const ValueKey('sync_event_map'), // Stable key to preserve state
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      mapType: MapType
          .normal, // Explicit: normal to avoid hybrid tile issues in release
      // CRITICAL FIX: initialCameraPosition uses preserved state (target/zoom/tilt)
      initialCameraPosition: CameraPosition(
        target: _lastTarget ?? _getDefaultTarget(events),
        zoom: _lastZoom,
        tilt: _lastTilt,
      ),
      markers: markers,

      myLocationButtonEnabled: false,
      myLocationEnabled: false,

      // CRITICAL FIX: Return empty set for mobile, not null
      gestureRecognizers: kIsWeb
          ? <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            }
          : <
              Factory<OneSequenceGestureRecognizer>
            >{}, // Empty set instead of null

      onMapCreated: (controller) {
        _mapController = controller; // Local ref
        ref.read(mapControllerProvider.notifier).state =
            controller; // Provider ref

        // CRITICAL: Set initial position ONLY once, via controller
        if (!_isMapInitialized) {
          _animateToInitialPosition(events);
          _isMapInitialized = true;
        }

        // CRITICAL: Different timing for web vs mobile
        if (kIsWeb) {
          // Web: Immediate assignment
          Future.microtask(() {
            if (mounted) {
              print('MapScreen: Map created (web)');
            }
          });
        } else {
          // Mobile: Post-frame callback
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              print('MapScreen: Map created (mobile)');
              controller.setMapStyle(null); // Reset style for release mode
            }
          });
        }
      },

      // CRITICAL FIX: Update preserved camera state during moves
      onCameraMove: (CameraPosition position) {
        _lastTarget = position.target;
        _lastZoom = position.zoom;
        _lastTilt = position.tilt;
      },

      onTap: (_) {
        // CRITICAL FIX: Ignore map taps during marker handling to prevent spurious clears
        if (ref.read(handlingMarkerTapProvider)) {
          print('MapScreen: Ignoring map tap during marker handling');
          return;
        }
        // CRITICAL: Add debouncing for web and release
        Future.microtask(() {
          if (mounted) {
            ref.read(selectedEventProvider.notifier).state = null;
            print('MapScreen: Map tapped, cleared selected event');
          }
        });
      },

      onCameraMoveStarted: () {
        // Web/release can trigger excessively, so just log without state updates
        print('MapScreen: Camera move started');
      },

      onCameraIdle: () {
        print('MapScreen: Camera idle');
        // CRITICAL FIX: No longer reset to default; rely on onCameraMove for preservation
      },
    );
  }

  // Build map error widget
  Widget _buildMapError(Object err) {
    print('MapScreen: Error loading events: $err');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error loading map',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            err.toString(),
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // CRITICAL FIX: Animate initial position only once via controller, using preserved zoom/tilt
  void _animateToInitialPosition(List<EventEntity> events) {
    final target = _getDefaultTarget(events);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: _lastZoom, tilt: _lastTilt),
      ),
    );
    print(
      'MapScreen: Initial position animated to ${target.latitude}, ${target.longitude}',
    );
  }

  // Get default target (first event or fallback)
  LatLng _getDefaultTarget(List<EventEntity> events) {
    if (events.isNotEmpty &&
        events.first.latitude != null &&
        events.first.longitude != null) {
      return LatLng(events.first.latitude!, events.first.longitude!);
    }
    return const LatLng(11.8705, 75.3679); // Fallback
  }

 void _setupEventListener() {
  ref.listen(eventsMapProvider, (previous, state) {
    state.whenData((events) {
      final now = DateTime.now();

      final activeEvents = events.where((event) {
        return event.endTime.isAfter(now);
      }).toList();

      ref.read(allEventsProvider.notifier).state = activeEvents;
      ref.read(markerStateProvider.notifier).buildMarkers(activeEvents);
    });
  });
}


  Future<void> _handleLocateMe() async {
    try {
      final cameraPosition = await _locationService.getCurrentLocation();
      if (cameraPosition != null && mounted) {
        ref
            .read(mapControllerProvider.notifier)
            .state
            ?.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
        print('MapScreen: Animated to user location');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Location found!')));
        }
      }
    } on LocationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
