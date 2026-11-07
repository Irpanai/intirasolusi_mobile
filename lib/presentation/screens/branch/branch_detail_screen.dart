import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/repositories/branch_repository.dart';

class BranchDetailScreen extends StatefulWidget {
  final String branchCode;

  const BranchDetailScreen({super.key, required this.branchCode});

  @override
  State<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends State<BranchDetailScreen> {
  final BranchRepository _branchRepository = BranchRepository();

  BranchModel? _branch;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBranchDetail();
  }

  Future<void> _loadBranchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final branch = await _branchRepository.getBranchDetail(widget.branchCode);
      setState(() {
        _isLoading = false;
        _branch = branch;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ignore: unused_element
  void _openMaps() async {
    if (_branch?.latitude == null || _branch?.longitude == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_branch!.latitude},${_branch!.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ignore: unused_element
  void _callPhone() async {
    if (_branch?.phone == null) return;

    final url = Uri.parse('tel:${_branch!.phone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _sendEmail() async {
    if (_branch?.email == null) return;

    final url = Uri.parse('mailto:${_branch!.email}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat detail cabang...')
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBranchDetail,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          Transform.translate(
            offset: const Offset(0, -24),
            child: _buildDetailCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, bottom: 48, left: 20, right: 20),
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
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
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
            const SizedBox(height: 24),

            // Branch name and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _branch?.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _branch?.code ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (_branch?.isActive ?? false)
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (_branch?.isActive ?? false) ? 'Buka' : 'Tutup',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Info Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Kontak',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Address
                _buildInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat',
                  value: _branch?.address ?? '-',
                ),
                const SizedBox(height: 12),

                // City & Province
                if (_branch?.city != null || _branch?.province != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildInfoRow(
                      icon: Icons.map_outlined,
                      label: 'Kota/Provinsi',
                      value: [_branch?.city, _branch?.province]
                          .whereType<String>()
                          .join(', '),
                    ),
                  ),

                // Phone - temporarily disabled
                _buildInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Telepon',
                  value: _branch?.phone ?? '-',
                  // onTap: _branch?.phone != null ? _callPhone : null, // TODO: Enable when phone feature is ready
                ),
                const SizedBox(height: 12),

                // Email
                if (_branch?.email != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _branch!.email!,
                      onTap: _sendEmail,
                    ),
                  ),

                // Operating Hours
                if (_branch?.operatingHours != null)
                  _buildInfoRow(
                    icon: Icons.access_time_outlined,
                    label: 'Jam Operasional',
                    value: _branch!.operatingHours!,
                  ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Call Button - temporarily disabled
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.phone,
                    label: 'Telepon',
                    // onTap: _branch?.phone != null ? _callPhone : null, // TODO: Enable when phone feature is ready
                  ),
                ),
                const SizedBox(width: 12),
                // Maps Button - temporarily disabled
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.map,
                    label: 'Peta',
                    // onTap: (_branch?.latitude != null && _branch?.longitude != null)
                    //     ? _openMaps
                    //     : null, // TODO: Enable when maps feature is ready
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: onTap != null ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    final isEnabled = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary
              ? (isEnabled ? AppColors.primary : AppColors.textMuted)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(
                  color: isEnabled ? AppColors.primary : AppColors.textMuted,
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary
                  ? Colors.white
                  : (isEnabled ? AppColors.primary : AppColors.textMuted),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? Colors.white
                    : (isEnabled ? AppColors.primary : AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
