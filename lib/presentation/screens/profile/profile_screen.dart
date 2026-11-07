import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/custom_bottom_nav.dart';
import '../../../core/widgets/info_card.dart';
import '../../../data/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch profile data from API when screen is mounted
    context.read<AuthBloc>().add(AuthLoadProfile());
  }

  void _handleNavTap(BuildContext context, NavItem item) {
    switch (item) {
      case NavItem.home:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case NavItem.transactions:
        Navigator.pushNamed(context, '/transactions');
        break;
      case NavItem.pawnRequest:
        Navigator.pushNamed(context, '/pawn-requests');
        break;
      case NavItem.profile:
        // Already on profile
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            final customer = user.customer;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Gradient Header
                  _buildHeader(context, user, customer),

                  // Content
                  Transform.translate(
                    offset: const Offset(0, -32),
                    child: _buildContent(context, user, customer),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: CustomBottomNav.buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNav(
        currentItem: NavItem.profile,
        onItemTapped: (item) => _handleNavTap(context, item),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user, CustomerModel? customer) {
    final String initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    final bool isProfileComplete = customer?.isProfileComplete ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, bottom: 56, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profil Saya',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Profile Info
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isProfileComplete
                              ? Colors.green
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isProfileComplete ? 'Profil Lengkap' : 'Profil Belum Lengkap',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserModel user, CustomerModel? customer) {
    final bool isProfileComplete = customer?.isProfileComplete ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Profile Completion Alert
          if (!isProfileComplete) ...[
            _buildCompleteProfileAlert(context),
            const SizedBox(height: 16),
          ],

          // Personal Info Card
          InfoCard(
            title: 'Informasi Pribadi',
            trailing: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile/edit'),
              child: Row(
                children: [
                  Icon(Icons.edit, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            items: [
              InfoItem(
                icon: Icons.badge_outlined,
                label: 'NIK',
                value: customer?.nik ?? '-',
              ),
              InfoItem(
                icon: Icons.phone_outlined,
                label: 'Telepon',
                value: customer?.phone ?? user.phone ?? '-',
              ),
              InfoItem(
                icon: Icons.place_outlined,
                label: 'Tempat Lahir',
                value: customer?.birthPlace ?? '-',
              ),
              InfoItem(
                icon: Icons.cake_outlined,
                label: 'Tanggal Lahir',
                value: _formatBirthDate(customer?.birthDate),
              ),
              InfoItem(
                icon: Icons.wc_outlined,
                label: 'Jenis Kelamin',
                value: _formatGender(customer?.gender),
              ),
            ],
          ),

          // Address Card
          InfoCard(
            title: 'Alamat',
            items: [
              InfoItem(
                icon: Icons.location_on_outlined,
                label: 'Alamat',
                value: customer?.address ?? '-',
              ),
              InfoItem(
                icon: Icons.location_city_outlined,
                label: 'Kelurahan/Desa',
                value: customer?.villageName ?? '-',
              ),
              InfoItem(
                icon: Icons.map_outlined,
                label: 'Kecamatan',
                value: customer?.districtName ?? '-',
              ),
              InfoItem(
                icon: Icons.apartment_outlined,
                label: 'Kota/Kabupaten',
                value: customer?.cityName ?? '-',
              ),
              InfoItem(
                icon: Icons.flag_outlined,
                label: 'Provinsi',
                value: customer?.provinceName ?? '-',
              ),
            ],
          ),

          // Work Info Card
          InfoCard(
            title: 'Pekerjaan',
            items: [
              InfoItem(
                icon: Icons.work_outline,
                label: 'Pekerjaan',
                value: customer?.occupation ?? '-',
              ),
              InfoItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Pendapatan Bulanan',
                value: customer?.monthlyIncome ?? '-',
              ),
            ],
          ),

          // Emergency Contact Card
          InfoCard(
            title: 'Kontak Darurat',
            items: [
              InfoItem(
                icon: Icons.people_outline,
                label: 'Nama',
                value: customer?.emergencyContactName ?? '-',
              ),
              InfoItem(
                icon: Icons.phone_outlined,
                label: 'Telepon',
                value: customer?.emergencyContactPhone ?? '-',
              ),
              InfoItem(
                icon: Icons.family_restroom_outlined,
                label: 'Hubungan',
                value: customer?.emergencyContactRelation ?? '-',
              ),
            ],
          ),

          // Menu Items
          _buildMenuCard(context),
          const SizedBox(height: 16),

          // Logout Button
          _buildLogoutButton(context),
          const SizedBox(height: 12),

          // App Version
          Text(
            'Intira Customer App v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCompleteProfileAlert(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lengkapi Profil Anda',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lengkapi data profil untuk dapat mengajukan gadai online.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/complete-profile'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Lengkapi Sekarang',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.store,
            iconColor: AppColors.primary,
            iconBackground: AppColors.primary.withValues(alpha: 0.1),
            label: 'Lokasi Cabang',
            onTap: () => Navigator.pushNamed(context, '/branches'),
          ),
         Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
          _buildMenuItem(
            icon: Icons.lock_outline,
            iconColor: Colors.blue,
            iconBackground: Colors.blue.withValues(alpha: 0.1),
            label: 'Ubah Password',
            onTap: () => Navigator.pushNamed(context, '/profile/change-password'),
          ),
         Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
          _buildMenuItem(
            icon: Icons.help_outline,
            iconColor: Colors.green,
            iconBackground: Colors.green.withValues(alpha: 0.1),
            label: 'Bantuan',
            onTap: () => Navigator.pushNamed(context, '/help'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              'Keluar',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatGender(String? gender) {
    if (gender == 'L' || gender == 'male') return 'Laki-laki';
    if (gender == 'P' || gender == 'female') return 'Perempuan';
    return '-';
  }

  String _formatBirthDate(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return '-';
    try {
      final date = DateTime.parse(birthDate);
      final months = [
        '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${date.day} ${months[date.month]} ${date.year}';
    } catch (e) {
      return birthDate;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogout());
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/welcome',
                (route) => false,
              );
            },
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
