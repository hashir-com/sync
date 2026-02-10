import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/di/injection_container.dart';
import 'package:sync_event/core/error/failures.dart';
import 'package:sync_event/core/util/responsive_util.dart';
import 'package:sync_event/features/profile/domain/entities/profile_entity.dart';
import 'package:sync_event/features/profile/domain/repositories/profile_repository.dart';
import 'package:sync_event/features/profile/presentation/providers/profile_providers.dart';
import 'package:sync_event/features/profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:sync_event/features/profile/domain/usecases/update_user_profile_usecase.dart';
import 'package:go_router/go_router.dart';

final pickedImageProvider = StateProvider<File?>((ref) => null);
final isUploadingProvider = StateProvider<bool>((ref) => false);

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  ProfileEntity? _currentProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No user logged in')));
        if (mounted) context.pop();
      }
      return;
    }
    final useCase = ref.read(getUserProfileUseCaseProvider);
    final result = await useCase(GetProfileParams(uid: user.uid));
    if (!mounted) return;
    result.fold((failure) => _handleFailure(failure), (profile) {
      if (!mounted) return;
      setState(() {
        _currentProfile = profile;
        _nameController.text = profile.name;
        _isLoadingProfile = false;
      });
      // Clear any previously picked image to show current profile image
      if (mounted) {
        ref.read(pickedImageProvider.notifier).state = null;
      }
    });
  }

  void _handleFailure(Failure failure) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
      setState(() => _isLoadingProfile = false);
      // Clear any previously picked image on failure as well
      if (mounted) {
        ref.read(pickedImageProvider.notifier).state = null;
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (pickedFile != null && mounted) {
        ref.read(pickedImageProvider.notifier).state = File(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _updateProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name must be at least 2 characters long'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      ref.read(isUploadingProvider.notifier).state = true;
    }
    final updateUseCase = ref.read(updateUserProfileUseCaseProvider);
    Map<String, dynamic> updateData = {'name': name};

    try {
      final pickedImage = ref.read(pickedImageProvider);
      String? newImageUrl;
      if (pickedImage != null) {
        // Use repo directly for upload
        final repo = sl<ProfileRepository>();
        final uploadResult = await repo.uploadProfileImage(
          user.uid,
          pickedImage.path,
        );
        uploadResult.fold(
          (failure) => throw Exception(failure.message),
          (url) => newImageUrl = url,
        );
        if (newImageUrl != null) updateData['image'] = newImageUrl;
      }

      // Update Firestore via usecase
      final result = await updateUseCase(
        UpdateProfileParams(uid: user.uid, data: updateData),
      );
      if (!mounted) return;

      final updatedProfile = result.fold<ProfileEntity?>((failure) {
        _handleFailure(failure);
        return null;
      }, (profile) => profile);

      if (updatedProfile == null) return;

      // Sync Firebase Auth - now awaited in the try block
      await user.updateDisplayName(name);
      if (newImageUrl != null) await user.updatePhotoURL(newImageUrl);
      await user.reload();

      // Invalidate providers
      if (mounted) {
        ref.invalidate(authStateProvider);
        ref.invalidate(userByIdProvider(user.uid));
      }

      // Clear picked image after successful update
      if (mounted) {
        ref.read(pickedImageProvider.notifier).state = null;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        ref.read(isUploadingProvider.notifier).state = false;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pickedImage = ref.watch(pickedImageProvider);
    final isUploading = ref.watch(isUploadingProvider);

    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: AppColors.getBackground(isDark),
        appBar: AppBar(
          title: Text(
            'Edit Profile',
            style: AppTextStyles.headingSmall(isDark: isDark),
          ),
          backgroundColor: AppColors.getCard(isDark),
          foregroundColor: AppColors.getTextPrimary(isDark),
          elevation: 0,
        ),
        body: _buildShimmerEffect(isDark),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: AppTextStyles.headingSmall(isDark: isDark),
        ),
        backgroundColor: AppColors.getCard(isDark),
        foregroundColor: AppColors.getTextPrimary(isDark),
        elevation: 0,
      ),
      body: isUploading
          ? _buildShimmerEffect(isDark)
          : SingleChildScrollView(
              padding: ResponsiveUtil.getResponsivePadding(context).copyWith(
                bottom:
                    ResponsiveUtil.getResponsivePadding(context).bottom + 16,
              ),
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Material(
                      elevation: ResponsiveUtil.getElevation(
                        context,
                        baseElevation: 8,
                      ),
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtil.getBorderRadius(context, baseRadius: 24),
                      ),
                      color: Colors.transparent,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtil.getBorderRadius(
                              context,
                              baseRadius: 24,
                            ),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.getCard(isDark),
                              AppColors.getCard(isDark).withOpacity(0.95),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.getShadow(
                                isDark,
                              ).withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(
                            ResponsiveUtil.getSpacing(context, baseSpacing: 20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Profile Picture
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: ResponsiveUtil.getAvatarSize(
                                      context,
                                      baseSize: 60,
                                    ),
                                    backgroundColor: isDark
                                        ? AppColors.surfaceDark
                                        : AppColors.grey300,
                                    backgroundImage: pickedImage != null
                                        ? FileImage(pickedImage)
                                        : _currentProfile?.image != null
                                        ? NetworkImage(_currentProfile!.image!)
                                        : null,
                                    child:
                                        pickedImage == null &&
                                            _currentProfile?.image == null
                                        ? Icon(
                                            Icons.person,
                                            size: ResponsiveUtil.getIconSize(
                                              context,
                                              baseSize: 60,
                                            ),
                                            color: AppColors.getTextSecondary(
                                              isDark,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        padding: EdgeInsets.all(
                                          ResponsiveUtil.getSpacing(
                                            context,
                                            baseSpacing: 8,
                                          ),
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.getPrimary(isDark),
                                              AppColors.getPrimary(
                                                isDark,
                                              ).withOpacity(0.8),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: ResponsiveUtil.getIconSize(
                                            context,
                                            baseSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: ResponsiveUtil.getSpacing(
                                  context,
                                  baseSpacing: 16,
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: Icon(
                                    Icons.photo_camera_outlined,
                                    size: ResponsiveUtil.getIconSize(
                                      context,
                                      baseSize: 20,
                                    ),
                                  ),
                                  label: Text(
                                    'Change Profile Picture',
                                    style: AppTextStyles.bodyMedium(
                                      isDark: isDark,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.getPrimary(
                                      isDark,
                                    ),
                                    side: BorderSide(
                                      color: AppColors.getPrimary(
                                        isDark,
                                      ).withOpacity(0.5),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: ResponsiveUtil.getSpacing(
                                        context,
                                        baseSpacing: 12,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveUtil.getBorderRadius(
                                          context,
                                          baseRadius: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: ResponsiveUtil.getSpacing(
                                  context,
                                  baseSpacing: 20,
                                ),
                              ),
                              // Name Field
                              TextField(
                                controller: _nameController,
                                style: AppTextStyles.bodyLarge(isDark: isDark),
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  labelStyle: AppTextStyles.labelLarge(
                                    isDark: isDark,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: AppColors.getTextSecondary(isDark),
                                    size: ResponsiveUtil.getIconSize(
                                      context,
                                      baseSize: 24,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.getSurface(isDark),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveUtil.getBorderRadius(
                                        context,
                                        baseRadius: 16,
                                      ),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveUtil.getBorderRadius(
                                        context,
                                        baseRadius: 16,
                                      ),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.getBorder(isDark),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveUtil.getBorderRadius(
                                        context,
                                        baseRadius: 16,
                                      ),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.getPrimary(isDark),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal:
                                        AppSizes.getInputPaddingHorizontal(
                                          context,
                                        ),
                                    vertical: AppSizes.getInputPaddingVertical(
                                      context,
                                    ),
                                  ),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z\s]'),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: ResponsiveUtil.getSpacing(
                                  context,
                                  baseSpacing: 24,
                                ),
                              ),
                              // Save Button
                              SizedBox(
                                width: double.infinity,
                                height: AppSizes.getButtonHeight(context),
                                child: ElevatedButton(
                                  onPressed: _updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.getPrimary(
                                      isDark,
                                    ),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveUtil.getBorderRadius(
                                          context,
                                          baseRadius: 16,
                                        ),
                                      ),
                                    ),
                                    elevation: ResponsiveUtil.getElevation(
                                      context,
                                      baseElevation: 5,
                                    ),
                                    shadowColor: AppColors.getPrimary(
                                      isDark,
                                    ).withOpacity(0.3),
                                  ),
                                  child: Text(
                                    'Save Changes',
                                    style: AppTextStyles.button(
                                      isDark: isDark,
                                    ).copyWith(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildShimmerEffect(bool isDark) {
    return SingleChildScrollView(
      padding: ResponsiveUtil.getResponsivePadding(context).copyWith(
        bottom: ResponsiveUtil.getResponsivePadding(context).bottom + 16,
      ),
      child: Material(
        elevation: ResponsiveUtil.getElevation(context, baseElevation: 8),
        borderRadius: BorderRadius.circular(
          ResponsiveUtil.getBorderRadius(context, baseRadius: 24),
        ),
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveUtil.getBorderRadius(context, baseRadius: 24),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.getCard(isDark),
                AppColors.getCard(isDark).withOpacity(0.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.getShadow(isDark).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(
              ResponsiveUtil.getSpacing(context, baseSpacing: 20),
            ),
            child: Shimmer.fromColors(
              baseColor: AppColors.getShimmerBase(isDark),
              highlightColor: AppColors.getShimmerHighlight(isDark),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: ResponsiveUtil.getAvatarSize(context, baseSize: 120),
                    height: ResponsiveUtil.getAvatarSize(
                      context,
                      baseSize: 120,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveUtil.getSpacing(context, baseSpacing: 16),
                  ),
                  Container(width: 200, height: 20, color: AppColors.grey300),
                  SizedBox(
                    height: ResponsiveUtil.getSpacing(context, baseSpacing: 20),
                  ),
                  Container(
                    width: double.infinity,
                    height: AppSizes.getInputHeight(context),
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtil.getBorderRadius(context, baseRadius: 16),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveUtil.getSpacing(context, baseSpacing: 24),
                  ),
                  Container(
                    width: double.infinity,
                    height: AppSizes.getButtonHeight(context),
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtil.getBorderRadius(context, baseRadius: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
