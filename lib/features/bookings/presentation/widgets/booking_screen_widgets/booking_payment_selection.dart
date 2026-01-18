// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sync_event/core/constants/app_colors.dart';
import 'package:sync_event/core/constants/app_sizes.dart';
import 'package:sync_event/core/constants/app_text_styles.dart';
import 'package:sync_event/core/error/failures.dart';
import 'package:sync_event/features/auth/presentation/providers/auth_notifier.dart';
import 'package:sync_event/features/bookings/domain/entities/booking_entity.dart';
import 'package:sync_event/features/bookings/presentation/providers/booking_form_provider.dart';
import 'package:sync_event/features/bookings/presentation/providers/booking_provider.dart';
import 'package:sync_event/features/bookings/presentation/widgets/razorpay_payment_widget.dart';
import 'package:sync_event/features/events/domain/entities/event_entity.dart';
import 'package:sync_event/features/wallet/data/models/wallet_model.dart';
import 'package:sync_event/features/wallet/presentation/provider/wallet_provider.dart';
import 'package:uuid/uuid.dart';

class BookingPaymentSection extends ConsumerWidget {
  final EventEntity event;
  final bool isDark;
  final AsyncValue<BookingEntity?> bookingState;

  const BookingPaymentSection({
    super.key,
    required this.event,
    required this.isDark,
    required this.bookingState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(bookingFormProvider);
    final walletAsync = ref.watch(walletNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.user?.uid ?? '';
    final userEmail = authState.user?.email ?? '';

    // CRITICAL DEBUG LOGGING
    print('═══════════════════════════════════════');
    print('🔍 PAYMENT SECTION DEBUG:');
    print('User ID: ${userId.isEmpty ? "❌ EMPTY" : "✓ $userId"}');
    print('User Email: ${userEmail.isEmpty ? "❌ EMPTY" : "✓ $userEmail"}');
    print('Auth User Object: ${authState.user != null ? "✓ EXISTS" : "❌ NULL"}');
    print('Is Loading: ${authState.isLoading}');
    print('Auth Error: ${authState.error ?? "none"}');
    if (authState.user != null) {
      print('User Details:');
      print('  - Name: ${authState.user!.name ?? "none"}');
      print('  - Phone: ${authState.user!.phoneNumber ?? "none"}');
    }
    print('═══════════════════════════════════════');

    final validCategories = event.categoryPrices.entries
        .where(
          (entry) =>
              entry.value > 0 && event.categoryCapacities[entry.key]! > 0,
        )
        .map((entry) => entry.key)
        .toList();

    final selectedCategory =
        validCategories.contains(formState.selectedCategory)
        ? formState.selectedCategory
        : (validCategories.isNotEmpty ? validCategories.first : '');

    final price = event.categoryPrices[selectedCategory];
    final totalAmount = (price != null) ? price * formState.quantity : 0.0;

    final canUseWallet = walletAsync.maybeWhen(
      data: (wallet) => wallet.balance >= totalAmount,
      orElse: () => false,
    );

    return Column(
      children: [
        if (totalAmount > 0) ...[
          _buildWalletToggle(
            context,
            ref,
            formState.useWallet,
            canUseWallet,
            totalAmount,
          ),
          SizedBox(height: AppSizes.spacingLarge),
        ],
        _buildPaymentButton(
          context,
          ref,
          userId,
          userEmail,
          totalAmount,
          selectedCategory,
          formState,
          walletAsync,
          canUseWallet,
        ),
        SizedBox(height: AppSizes.spacingLarge),
        _buildPaymentStatus(),
      ],
    );
  }

  Widget _buildWalletToggle(
    BuildContext context,
    WidgetRef ref,
    bool useWallet,
    bool canUseWallet,
    double totalAmount,
  ) {
    return Row(
      children: [
        const Icon(Icons.account_balance_wallet, size: 20),
        SizedBox(width: AppSizes.spacingSmall),
        const Text('Pay with Wallet Balance'),
        const Spacer(),
        if (!canUseWallet)
          Text(
            'Insufficient Balance',
            style: TextStyle(color: AppColors.getError(isDark), fontSize: 12),
          )
        else
          Switch(
            value: useWallet,
            onChanged: (value) {
              if (value && !canUseWallet) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Insufficient wallet balance. Please top up.',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              ref.read(bookingFormProvider.notifier).toggleUseWallet(value);
            },
            activeColor: AppColors.getPrimary(isDark),
          ),
      ],
    );
  }

  Widget _buildPaymentButton(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String userEmail,
    double totalAmount,
    String selectedCategory,
    BookingFormState formState,
    AsyncValue<WalletModel> walletAsync,
    bool canUseWallet,
  ) {
    if (totalAmount <= 0) {
      return const SizedBox.shrink();
    }

    if (formState.useWallet) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppColors.getPrimary(isDark).withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: AppSizes.buttonHeightLarge,
          child: ElevatedButton(
            onPressed: () => _handleWalletPayment(
              context,
              ref,
              userId,
              userEmail,
              selectedCategory,
              formState,
              totalAmount,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getPrimary(isDark),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              ),
            ),
            child: Text(
              'Pay with Wallet - ₹${totalAmount.toStringAsFixed(0)}',
              style: AppTextStyles.button(
                isDark: false,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.getPrimary(isDark).withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppSizes.buttonHeightLarge,
        child: RazorpayPaymentWidget(
          amount: totalAmount,
          onSuccess: (paymentId) => _handlePaymentSuccess(
            context,
            ref,
            userId,
            userEmail,
            selectedCategory,
            formState,
            totalAmount,
            paymentId,
          ),
        ),
      ),
    );
  }

  Future<void> _handleWalletPayment(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String userEmail,
    String selectedCategory,
    BookingFormState formState,
    double totalAmount,
  ) async {
    print('\n💳 === WALLET PAYMENT INITIATED ===');
    print('User ID: ${userId.isEmpty ? "❌ EMPTY" : userId}');
    print('User Email: ${userEmail.isEmpty ? "❌ EMPTY" : userEmail}');
    print('Amount: ₹$totalAmount');
    
    if (userId.isEmpty) {
      print('❌ WALLET PAYMENT BLOCKED: User ID is empty');
      _showErrorSnackBar(context, 'Please log in to book tickets');
      return;
    }

    // If email is empty, ask user to provide it and save to Firestore
    String? effectiveEmail = userEmail;
    if (userEmail.isEmpty) {
      print('⚠️ Email is empty, prompting user...');
      effectiveEmail = await _showEmailInputDialog(context);
      if (effectiveEmail == null || effectiveEmail.isEmpty) {
        print('❌ WALLET PAYMENT CANCELLED: User did not provide email');
        _showErrorSnackBar(context, 'Email is required for booking confirmation');
        return;
      }
      
      // Save email to Firestore for future use
      try {
        print('💾 Saving email to Firestore...');
        // You'll need to import your UserProfileService
        // For now, save directly to Firestore
        await _saveEmailToFirestore(userId, effectiveEmail);
        print('✓ Email saved to Firestore');
      } catch (e) {
        print('⚠️ Failed to save email to Firestore: $e');
        // Continue anyway, we have the email for this booking
      }
    }
    
    print('Effective email: $effectiveEmail');
    print('✓ Starting wallet payment for ₹$totalAmount');

    // Immediately navigate to confirmation loading screen
    if (context.mounted) {
      context.go('/booking-confirmation', extra: {'event': event});
    }

    const uuid = Uuid();
    final walletPaymentId = 'wallet_${uuid.v4()}';

    try {
      print('📤 Sending booking request with:');
      print('  - Event ID: ${event.id}');
      print('  - User ID: $userId');
      print('  - Email: $effectiveEmail');
      print('  - Amount: ₹$totalAmount');
      
      await ref
          .read(bookingNotifierProvider.notifier)
          .bookTicket(
            eventId: event.id,
            userId: userId,
            ticketType: selectedCategory,
            ticketQuantity: formState.quantity,
            totalAmount: totalAmount,
            paymentId: walletPaymentId,
            startTime: event.startTime,
            endTime: event.endTime,
            seatNumbers: const [],
            userEmail: effectiveEmail,
            paymentMethod: 'wallet',
          );

      print('✓ Wallet booking request sent successfully');
    } catch (e, stackTrace) {
      print('❌ Exception during wallet payment:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      // Show error to user
      if (context.mounted) {
        _showErrorSnackBar(context, 'Booking failed: ${e.toString()}');
      }
    }
  }

  Future<void> _handlePaymentSuccess(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String userEmail,
    String selectedCategory,
    BookingFormState formState,
    double totalAmount,
    String paymentId,
  ) async {
    print('\n💰 === RAZORPAY PAYMENT SUCCESS ===');
    print('Payment ID: $paymentId');
    print('User ID: ${userId.isEmpty ? "❌ EMPTY" : userId}');
    print('User Email: ${userEmail.isEmpty ? "❌ EMPTY" : userEmail}');
    print('Amount: ₹$totalAmount');
    
    if (userId.isEmpty) {
      print('❌ RAZORPAY PAYMENT BLOCKED: User ID is empty');
      print('This means authState.user is NULL when payment callback happened');
      
      // Try to refresh auth state
      print('🔄 Attempting to refresh auth state...');
      ref.read(authNotifierProvider.notifier).refreshAuthState();
      
      // Wait a bit for state to update
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check again
      final authState = ref.read(authNotifierProvider);
      final refreshedUserId = authState.user?.uid ?? '';
      print('After refresh - User ID: ${refreshedUserId.isEmpty ? "❌ STILL EMPTY" : refreshedUserId}');
      
      if (refreshedUserId.isEmpty) {
        _showErrorSnackBar(context, 'Please log in to book tickets');
        return;
      }
      
      // Use refreshed user ID
      userId = refreshedUserId;
      userEmail = authState.user?.email ?? '';
      print('✓ Using refreshed user credentials');
    }

    // If email is still empty after refresh, ask user to provide it and save to Firestore
    String? effectiveEmail = userEmail;
    if (userEmail.isEmpty) {
      print('⚠️ Email is empty, prompting user...');
      effectiveEmail = await _showEmailInputDialog(context);
      if (effectiveEmail == null || effectiveEmail.isEmpty) {
        print('❌ RAZORPAY PAYMENT CANCELLED: User did not provide email');
        _showErrorSnackBar(context, 'Email is required for booking confirmation');
        return;
      }
      
      // Save email to Firestore for future use
      try {
        print('💾 Saving email to Firestore...');
        await _saveEmailToFirestore(userId, effectiveEmail);
        print('✓ Email saved to Firestore');
      } catch (e) {
        print('⚠️ Failed to save email to Firestore: $e');
        // Continue anyway, we have the email for this booking
      }
    }

    print('✓ Razorpay payment successful, processing booking...');

    // Immediately navigate to confirmation loading screen
    if (context.mounted) {
      context.go('/booking-confirmation', extra: {'event': event});
    }

    try {
      print('📤 Sending booking request with:');
      print('  - Event ID: ${event.id}');
      print('  - User ID: $userId');
      print('  - Email: $effectiveEmail');
      print('  - Amount: ₹$totalAmount');
      
      await ref
          .read(bookingNotifierProvider.notifier)
          .bookTicket(
            eventId: event.id,
            userId: userId,
            ticketType: selectedCategory,
            ticketQuantity: formState.quantity,
            totalAmount: totalAmount,
            paymentId: paymentId,
            startTime: event.startTime,
            endTime: event.endTime,
            seatNumbers: const [],
            userEmail: effectiveEmail,
            paymentMethod: 'razorpay',
          );

      print('✓ Razorpay booking request sent successfully');
    } catch (e, stackTrace) {
      print('❌ Exception during Razorpay payment processing:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      // Show error to user
      if (context.mounted) {
        _showErrorSnackBar(context, 'Booking failed: ${e.toString()}');
      }
    }
  }

  Widget _buildPaymentStatus() {
    return bookingState.when(
      data: (booking) =>
          booking != null ? _buildSuccessStatus() : const SizedBox.shrink(),
      loading: () => _buildLoadingStatus(),
      error: (error, stack) => _buildErrorStatus(error),
    );
  }

  Widget _buildSuccessStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: AppColors.getSuccess(isDark),
          size: AppSizes.iconMedium,
        ),
        SizedBox(width: AppSizes.spacingSmall),
        Text(
          'Processing booking...',
          style: AppTextStyles.bodyMedium(
            isDark: isDark,
          ).copyWith(color: AppColors.getSuccess(isDark)),
        ),
      ],
    );
  }

  Widget _buildLoadingStatus() {
    return Shimmer.fromColors(
      baseColor: AppColors.getSurface(isDark),
      highlightColor: AppColors.getBorder(isDark).withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppSizes.spacingMedium),
          Container(
            width: 150,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.getSurface(isDark),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStatus(dynamic error) {
    return Container(
      padding: EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.getError(isDark).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.getError(isDark).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_rounded, color: AppColors.getError(isDark)),
          SizedBox(width: AppSizes.spacingMedium),
          Expanded(
            child: Text(
              'Error: ${error is Failure ? error.message : error.toString()}',
              style: AppTextStyles.bodySmall(
                isDark: isDark,
              ).copyWith(color: AppColors.getError(isDark)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium(
            isDark: true,
          ).copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.getError(isDark),
      ),
    );
  }

  // NEW: Dialog to collect email from phone users
  Future<String?> _showEmailInputDialog(BuildContext context) async {
    final emailController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Email Required',
          style: AppTextStyles.headingSmall(isDark: isDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide your email to receive booking confirmation and updates.',
              style: AppTextStyles.bodyMedium(isDark: isDark),
            ),
            SizedBox(height: AppSizes.spacingLarge),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'your@email.com',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.getTextSecondary(isDark)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please enter an email address'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              // Basic email validation
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please enter a valid email address'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.of(context).pop(email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getPrimary(isDark),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Helper method to save email to Firestore
  Future<void> _saveEmailToFirestore(String userId, String email) async {
    try {
      // You need to import cloud_firestore package
      // Add this to your imports: import 'package:cloud_firestore/cloud_firestore.dart';
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving email: $e');
      rethrow;
    }
  }
}