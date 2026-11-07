import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Illustration
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 120,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 48),
              
              // Title
              Text(
                'Selamat Datang di Intira',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Solusi gadai online yang aman, cepat, dan terpercaya. Dapatkan pinjaman dengan jaminan barang berharga Anda.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              
              // Buttons
              AppButton(
                text: 'Masuk',
                onPressed: () => Navigator.pushNamed(context, '/login'),
                width: double.infinity,
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Daftar',
                onPressed: () => Navigator.pushNamed(context, '/register-flow'),
                width: double.infinity,
                isOutlined: true,
              ),
              const SizedBox(height: 16),
              
            ],
          ),
        ),
      ),
    );
  }
}
