import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';

class NavigationHelper {
  /// Navigate to pawn request create screen only if profile is complete.
  /// Shows a dialog prompting to complete profile if not.
  static void goToPawnRequestCreate(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      final isComplete = authState.user.customer?.isProfileComplete ?? false;
      if (!isComplete) {
        _showIncompleteProfileDialog(context);
        return;
      }
    }

    Navigator.pushNamed(context, '/pawn-requests/create');
  }

  static void _showIncompleteProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: AppColors.warning,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Profil Belum Lengkap',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lengkapi data profil Anda terlebih dahulu sebelum mengajukan gadai.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/complete-profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Lengkapi Profil'),
          ),
        ],
      ),
    );
  }
}
