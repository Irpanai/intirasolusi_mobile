import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class GradientHeader extends StatelessWidget {
  final Widget child;
  final double paddingBottom;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const GradientHeader({
    super.key,
    required this.child,
    this.paddingBottom = 48,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: paddingBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showBackButton || actions != null)
                Row(
                  children: [
                    if (showBackButton)
                      GestureDetector(
                        onTap: onBackPressed ?? () => Navigator.pop(context),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_back,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kembali',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (actions != null) ...actions!,
                  ],
                ),
              if (showBackButton || actions != null) const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class GradientHeaderTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const GradientHeaderTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}
