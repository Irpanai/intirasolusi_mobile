import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../data/models/user_model.dart';

class ProfileBody extends StatefulWidget {
  const ProfileBody({super.key});

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthLoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) => current is! AuthLoading,
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final user = state.user;
          final customer = user.customer;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthLoadProfile());
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Signature Curved Green Header with Centered Avatar
                  _buildHeader(context, user, customer),

                  // Content Body
                  _buildContent(context, user, customer),
                ],
              ),
            ),
          );
        }

        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user, CustomerModel? customer) {
    final String initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'N';
    final bool isProfileComplete = customer?.isProfileComplete ?? false;
    final String customerCode = (customer?.code != null && customer!.code!.isNotEmpty)
        ? customer.code!
        : (customer?.nik != null && customer!.nik!.isNotEmpty ? customer.nik! : '1210260001');

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF14532D), // Deep green 900
            Color(0xFF15803D), // Emerald 700
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            children: [
              // Top Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profil Saya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile/edit'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit_outlined, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Centered Avatar (Reference Screen 1 Style)
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // User Name
              Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),

              // User Email
              Text(
                user.email,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              // Member Status Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isProfileComplete ? const Color(0xFF4ADE80) : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Anggota ${isProfileComplete ? 'AKTIF' : 'TERDAFTAR'} • $customerCode',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Branch Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'KANTOR CABANG UTAMA (BANJARMASIN)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserModel user, CustomerModel? customer) {
    final bool isProfileComplete = customer?.isProfileComplete ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2x2 Quick Actions Grid (Screen 1 Reference Style)
          _buildQuickActionGrid(context),
          const SizedBox(height: 22),

          // Profile Incomplete Notice (if any)
          if (!isProfileComplete) ...[
            _buildCompleteProfileAlert(context),
            const SizedBox(height: 18),
          ],

          // Section 1: Data Pribadi & Keuangan
          const Text(
            'Data Pribadi & Keuangan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _buildSectionCard([
            _buildListTile(
              icon: Icons.badge_outlined,
              title: 'Data Pribadi (KYC)',
              subtitle: 'NIK: ${customer?.nik ?? '-'}',
              trailing: isProfileComplete
                  ? _buildBadge('Terverifikasi', AppColors.success)
                  : _buildBadge('Belum Lengkap', AppColors.warning),
              onTap: () => Navigator.pushNamed(context, '/profile/edit'),
            ),
            const Divider(height: 1, indent: 56),
            _buildListTile(
              icon: Icons.location_on_outlined,
              title: 'Alamat Domisili',
              subtitle: customer?.address ?? 'Belum diatur',
              onTap: () => Navigator.pushNamed(context, '/profile/edit'),
            ),
            const Divider(height: 1, indent: 56),
            _buildListTile(
              icon: Icons.work_outline_rounded,
              title: 'Pekerjaan & Pendapatan',
              subtitle: customer?.occupation ?? 'Wiraswasta / Karyawan',
              onTap: () => Navigator.pushNamed(context, '/profile/edit'),
            ),
            const Divider(height: 1, indent: 56),
            _buildListTile(
              icon: Icons.contacts_outlined,
              title: 'Kontak Darurat',
              subtitle: customer?.emergencyContactName != null
                  ? '${customer!.emergencyContactName} (${customer.emergencyContactRelation ?? 'Keluarga'})'
                  : 'Belum diisi',
              onTap: () => Navigator.pushNamed(context, '/profile/edit'),
            ),
          ]),
          const SizedBox(height: 22),

          // Section 2: Bantuan & Pengaturan
          const Text(
            'Bantuan & Pengaturan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _buildSectionCard([
            _buildListTile(
              icon: Icons.help_outline_rounded,
              title: 'Pusat Bantuan & FAQ',
              subtitle: 'Pertanyaan seputar gadai & simpanan',
              onTap: () => Navigator.pushNamed(context, '/help'),
            ),
            const Divider(height: 1, indent: 56),
            _buildListTile(
              icon: Icons.storefront_outlined,
              title: 'Lokasi Kantor Cabang',
              subtitle: 'Cari kantor Intira terdekat di kota Anda',
              onTap: () => Navigator.pushNamed(context, '/branches'),
            ),
            const Divider(height: 1, indent: 56),
            _buildListTile(
              icon: Icons.lock_outline_rounded,
              title: 'Ubah Kata Sandi',
              subtitle: 'Amankan akun dengan kata sandi baru',
              onTap: () => Navigator.pushNamed(context, '/profile/change-password'),
            ),
          ]),
          const SizedBox(height: 24),

          // Logout Button
          _buildLogoutButton(context),
          const SizedBox(height: 16),

          // App Version
          Center(
            child: Text(
              'Intira Solusi Mobile v1.0.0 • OJK Compliance',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGridItem(
                context,
                icon: Icons.person_outline_rounded,
                title: 'Edit Profil',
                subtitle: 'Kelola data diri & KYC',
                onTap: () => Navigator.pushNamed(context, '/profile/edit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGridItem(
                context,
                icon: Icons.receipt_long_outlined,
                title: 'Mutasi Rekening',
                subtitle: 'Riwayat transaksi gadai',
                onTap: () => Navigator.pushNamed(context, '/transactions'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGridItem(
                context,
                icon: Icons.account_balance_wallet_outlined,
                title: 'Portofolio Gadai',
                subtitle: 'Pinjaman & status agunan',
                onTap: () => Navigator.pushNamed(context, '/transactions'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGridItem(
                context,
                icon: Icons.lock_outline_rounded,
                title: 'Keamanan Akun',
                subtitle: 'Ubah password & PIN',
                onTap: () => Navigator.pushNamed(context, '/profile/change-password'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11.5,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: trailing ?? const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
        size: 20,
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCompleteProfileAlert(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Profil Belum Lengkap',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                SizedBox(height: 2),
                Text(
                  'Lengkapi NIK & kontak darurat Anda',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/complete-profile'),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Lengkapi', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
        label: const Text(
          'Keluar dari Akun',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFCA5A5)),
          backgroundColor: const Color(0xFFFEF2F2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun GASPOL by INTIRA?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthLogout());
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
