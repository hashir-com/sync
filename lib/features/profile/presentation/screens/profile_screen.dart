import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/util/responsive_util.dart';
import 'package:sync_event/core/util/theme_util.dart';
import 'package:sync_event/features/events/presentation/providers/event_providers.dart'; // For deleteEventUseCaseProvider
import 'package:sync_event/features/profile/presentation/providers/profile_providers.dart';
import 'package:sync_event/features/profile/domain/usecases/create_user_usecase.dart'; // For CreateProfileParams and provider

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _profileCreated = false;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeUtils.isDark(context);
    final currentUser = ref.watch(currentUserProvider);
    final currentUid = currentUser?.uid;
    final isSelf = widget.userId == null || widget.userId == currentUid;
    final effectiveUid = widget.userId ?? currentUid;

    if (effectiveUid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profileAsync = ref.watch(userByIdProvider(effectiveUid));
    final eventsAsync = ref.watch(userHostedEventsProvider(effectiveUid));

    // Listen for profile load errors and auto-create profile if needed
    ref.listen<AsyncValue<UserModel?>>(userByIdProvider(effectiveUid), (
      previous,
      next,
    ) {
      if (next.hasError && !_profileCreated && isSelf && currentUser != null) {
        _profileCreated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            // Create basic user profile using auth user data
            final params = CreateProfileParams(
              uid: currentUser.uid,
              email: currentUser.email ?? '',
              displayName:
                  currentUser.displayName ??
                  currentUser.email?.split('@')[0] ??
                  'User',
              bio: '', // Default
              interests: <String>[], // Default
            );
            await ref.read(createUserProfileUseCaseProvider).call(params);
            // Invalidate to refetch
            ref.invalidate(userByIdProvider(effectiveUid));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            debugPrint('Failed to create profile: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create profile: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        });
      }
    });

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.getBackground(isDark),
        body: CustomScrollView(
          slivers: profileAsync.when(
            data: (user) {
              if (user == null) {
                return [
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'User not found',
                        style: AppTextStyles.bodyMedium(isDark: isDark),
                      ),
                    ),
                  ),
                ];
              }
              return [
                _buildProfileHeader(context, user, isSelf, isDark),
                _buildStatsRow(context, eventsAsync, isDark),
                if (user.bio != null && user.bio!.isNotEmpty)
                  _buildBioSection(context, user.bio!, isDark),
                if (user.interests.isNotEmpty)
                  _buildInterestsSection(context, user.interests, isDark),
                _buildSectionTitle(context, 'Hosted Events', isDark),
                _buildEventsSection(
                  context,
                  eventsAsync,
                  isSelf,
                  effectiveUid,
                  isDark,
                  ref,
                ),
              ];
            },
            loading: () => [_buildShimmerHeader(context, isDark)],
            error: (_, __) => [
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Failed to load profile',
                    style: AppTextStyles.bodyMedium(isDark: isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (rest of the methods remain unchanged)
  SliverToBoxAdapter _buildProfileHeader(
    BuildContext context,
    UserModel user,
    bool isSelf,
    bool isDark,
  ) {
    final double avatarSize = ResponsiveUtil.getAvatarSize(context) + 40;
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: ResponsiveUtil.getSpacing(context, baseSpacing: 32),
          bottom: ResponsiveUtil.getSpacing(context, baseSpacing: 28),
          left: ResponsiveUtil.getPadding(context),
          right: ResponsiveUtil.getPadding(context),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.getPrimary(isDark),
              AppColors.getPrimary(isDark).withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.getPrimary(isDark).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Hero(
              tag: 'user-${user.id}',
              child: _buildAvatar(avatarSize, user.image, isDark),
            ),
            SizedBox(
              height: ResponsiveUtil.getSpacing(context, baseSpacing: 16),
            ),
            Text(
              user.name,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMedium(isDark: false).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28 * ResponsiveUtil.getFontSizeMultiplier(context),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(
              height: ResponsiveUtil.getSpacing(context, baseSpacing: 20),
            ),
            if (isSelf)
              _buildEditButton(context, isDark)
            else
              _buildChatButton(context, user.id, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(double size, String? imageUrl, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.white,
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
        child: imageUrl == null
            ? Icon(
                Icons.person,
                size: size / 2,
                color: AppColors.getPrimary(isDark),
              )
            : null,
      ),
    );
  }

  Widget _buildEditButton(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => context.push('/edit-profile'),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(
          'Edit Profile',
          style: AppTextStyles.bodyMedium(
            isDark: false,
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.getPrimary(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildChatButton(BuildContext context, String userId, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => context.push('/chat', extra: {'userId': userId}),
        icon: const Icon(Icons.message_rounded, size: 18),
        label: const Text(
          'Message',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.getPrimary(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          elevation: 0,
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildStatsRow(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> eventsAsync,
    bool isDark,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtil.getPadding(context),
          vertical: ResponsiveUtil.getSpacing(context, baseSpacing: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatItem('Hosted Events', eventsAsync, () {}, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    AsyncValue<List<Map<String, dynamic>>> valueAsync,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          valueAsync.when(
            data: (events) => Text(
              events.length.toString(),
              style: AppTextStyles.headingSmall(
                isDark: isDark,
              ).copyWith(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const Text('0', style: TextStyle(fontSize: 20)),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall(
              isDark: isDark,
            ).copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildBioSection(
    BuildContext context,
    String bio,
    bool isDark,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtil.getPadding(context),
          vertical: ResponsiveUtil.getSpacing(context, baseSpacing: 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: AppTextStyles.titleMedium(
                isDark: isDark,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              bio,
              style: AppTextStyles.bodyMedium(
                isDark: isDark,
              ).copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildInterestsSection(
    BuildContext context,
    List<String> interests,
    bool isDark,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtil.getPadding(context),
          vertical: ResponsiveUtil.getSpacing(context, baseSpacing: 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interests',
              style: AppTextStyles.titleMedium(
                isDark: isDark,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests
                  .map(
                    (interest) => Chip(
                      label: Text(
                        interest,
                        style: AppTextStyles.bodySmall(isDark: isDark),
                      ),
                      backgroundColor: AppColors.getPrimary(
                        isDark,
                      ).withOpacity(0.1),
                      side: BorderSide(
                        color: AppColors.getPrimary(isDark),
                        width: 1,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _buildSectionTitle(
    BuildContext context,
    String title,
    bool isDark,
  ) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtil.getPadding(context),
        ResponsiveUtil.getSpacing(context, baseSpacing: 24),
        ResponsiveUtil.getPadding(context),
        ResponsiveUtil.getSpacing(context, baseSpacing: 16),
      ),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.getPrimary(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTextStyles.headingMedium(isDark: isDark).copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22 * ResponsiveUtil.getFontSizeMultiplier(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> eventsAsync,
    bool isSelf,
    String effectiveUid,
    bool isDark,
    WidgetRef ref,
  ) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtil.getPadding(context),
      ),
      sliver: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      size: 64,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No events hosted yet',
                      style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/create-event'),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getPrimary(isDark),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final eventData = events[index];
              return _EventCard(
                event: eventData,
                isSelf: isSelf,
                onEdit: isSelf
                    ? () => _navigateToEdit(context, eventData)
                    : null,
                onDelete: isSelf
                    ? () => _showDeleteDialog(context, ref, eventData)
                    : null,
                onTap: () => context.push('/event-detail', extra: eventData),
                isDark: isDark,
              );
            }, childCount: events.length),
          );
        },
        loading: () => _buildEventsShimmer(context, isDark),
        error: (e, __) {
          debugPrint('Error loading events: $e');
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load events',
                    style: AppTextStyles.bodyMedium(isDark: isDark),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.invalidate(userHostedEventsProvider(effectiveUid)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getPrimary(isDark),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToEdit(BuildContext context, Map<String, dynamic> event) {
    context.push('/edit-event', extra: event);
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> event,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete "${event['title']}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteEvent(context, ref, event['id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(
    BuildContext context,
    WidgetRef ref,
    String eventId,
  ) async {
    try {
      await ref.read(deleteEventUseCaseProvider).call(eventId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete event: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEventsShimmer(BuildContext context, bool isDark) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.getCard(isDark),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        childCount: 4,
      ),
    );
  }

  SliverToBoxAdapter _buildShimmerHeader(BuildContext context, bool isDark) {
    return SliverToBoxAdapter(
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isSelf;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onTap;
  final bool isDark;

  const _EventCard({
    required this.event,
    required this.isSelf,
    this.onEdit,
    this.onDelete,
    required this.onTap,
    required this.isDark,
  });

  void _showReasonDialog(BuildContext context) {
    final status = (event['status'] ?? '').toLowerCase();
    final isApproved = status == 'approved';
    final reason = isApproved
        ? (event['approvalReason'] ?? 'No reason provided')
        : (event['rejectionReason'] ?? 'No reason provided');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isApproved ? 'Approval Reason' : 'Rejection Reason'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reason,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'For any further details, contact admin: admin@gmail.com',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.getPrimary(isDark),
            ),
            child: const Text('Close'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.getCard(isDark),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (event['status'] ?? '').toLowerCase();
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final bookings = event['attendees']?.length ?? 0;
    final isApproved = status == 'approved';

    // Debug print to verify reason fields
    if (kDebugMode) {
      print('Event ID: ${event['id']}');
      print('Status: ${event['status']}');
      print('Approval Reason: ${event['approvalReason']}');
      print('Rejection Reason: ${event['rejectionReason']}');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Status Badge
            if (event['imageUrl'] != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      event['imageUrl'],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: AppColors.getSurface(isDark),
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.getSurface(isDark),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  size: 48,
                  color: Colors.grey,
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] ?? 'Untitled Event',
                    style: AppTextStyles.bodyLarge(
                      isDark: isDark,
                    ).copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        event['category'] ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event['location'] ?? '',
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium(isDark: isDark),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.people, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        event['maxAttendees'] == 0
                            ? 'Open'
                            : '${event['attendees']?.length ?? 0}/${event['maxAttendees'] ?? 0}',
                        style: AppTextStyles.bodySmall(
                          isDark: isDark,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                      if (isApproved) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.bookmark,
                          size: 18,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bookings: $bookings',
                          style: AppTextStyles.bodySmall(isDark: isDark)
                              .copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                  // Reason Section
                  if (status == 'approved' || status == 'rejected') ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showReasonDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              status == 'approved'
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 20,
                              color: statusColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                status == 'approved'
                                    ? 'Approval Reason: ${event['approvalReason'] ?? "No reason provided"}'
                                    : 'Rejection Reason: ${event['rejectionReason'] ?? "No reason provided"}',
                                style: AppTextStyles.bodySmall(isDark: isDark)
                                    .copyWith(
                                      color: statusColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ),
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action Buttons (only for self)
            if (isSelf) ...[
              const Divider(height: 0.5, thickness: 0.5, color: Colors.grey),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.getPrimary(isDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    return status.isNotEmpty
        ? status[0].toUpperCase() + status.substring(1).toLowerCase()
        : 'Unknown';
  }
}
