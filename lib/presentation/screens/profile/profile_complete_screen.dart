import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/app_input_styles.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../data/models/location_model.dart';
import '../../blocs/auth/auth_bloc.dart';

class ProfileCompleteScreen extends StatefulWidget {
  final String? initialPhone;
  
  const ProfileCompleteScreen({super.key, this.initialPhone});

  @override
  State<ProfileCompleteScreen> createState() => _ProfileCompleteScreenState();
}

class _ProfileCompleteScreenState extends State<ProfileCompleteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _locationRepository = LocationRepository();

  // Form controllers
  final _nikController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _occupationController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  // Form values
  DateTime? _birthDate;
  String? _gender;
  String? _selectedProvinceCode;
  String? _selectedCityCode;
  String? _selectedDistrictCode;
  String? _selectedVillageCode;
  String? _selectedMonthlyIncome;

  bool _isSubmitting = false;

  // Location data from API
  List<ProvinceModel> _provinces = [];
  List<CityModel> _cities = [];
  List<DistrictModel> _districts = [];
  List<VillageModel> _villages = [];

  // Loading states
  bool _isLoadingProvinces = true;
  bool _isLoadingCities = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingVillages = false;

  final List<String> _incomeOptions = [
    '< Rp 3.000.000',
    'Rp 3.000.000 - 5.000.000',
    'Rp 5.000.000 - 10.000.000',
    'Rp 10.000.000 - 20.000.000',
    '> Rp 20.000.000',
  ];

  String? _parseMonthlyIncome(dynamic income) {
    if (income == null) return null;
    final str = income.toString().trim();
    if (_incomeOptions.contains(str)) return str;

    final numVal = double.tryParse(str.replaceAll(RegExp(r'[^\d]'), ''));
    if (numVal != null) {
      if (numVal < 3000000) return '< Rp 3.000.000';
      if (numVal <= 5000000) return 'Rp 3.000.000 - 5.000.000';
      if (numVal <= 10000000) return 'Rp 5.000.000 - 10.000.000';
      if (numVal <= 20000000) return 'Rp 10.000.000 - 20.000.000';
      return '> Rp 20.000.000';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _loadUserData();
  }

  void _loadUserData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      final customer = user.customer;
      
      // Pre-fill phone from user data or initial phone from registration
      if (user.phone != null && user.phone!.isNotEmpty) {
        _phoneController.text = user.phone!;
      } else if (customer?.phone != null && customer!.phone!.isNotEmpty) {
        _phoneController.text = customer.phone!;
      } else if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
        // Fallback to phone passed from registration screen
        _phoneController.text = widget.initialPhone!;
      }
      
      // Pre-fill NIK from customer data
      if (customer?.nik != null && customer!.nik!.isNotEmpty) {
        _nikController.text = customer.nik!;
      }

      // Pre-fill birth place
      if (customer?.birthPlace != null && customer!.birthPlace!.isNotEmpty) {
        _birthPlaceController.text = customer.birthPlace!;
      }

      // Pre-fill birth date
      if (customer?.birthDate != null && customer!.birthDate!.isNotEmpty) {
        try {
          _birthDate = DateTime.parse(customer.birthDate!);
        } catch (_) {}
      }

      // Pre-fill gender
      if (customer?.gender != null && customer!.gender!.isNotEmpty) {
        final g = customer.gender!.toLowerCase();
        if (g == 'male' || g == 'l' || g == 'laki-laki') {
          _gender = 'L';
        } else if (g == 'female' || g == 'p' || g == 'perempuan') {
          _gender = 'P';
        }
      }

      // Pre-fill address
      if (customer?.address != null && customer!.address!.isNotEmpty) {
        _addressController.text = customer.address!;
      }

      // Pre-fill occupation
      if (customer?.occupation != null && customer!.occupation!.isNotEmpty) {
        _occupationController.text = customer.occupation!;
      }

      // Pre-fill monthly income
      _selectedMonthlyIncome = _parseMonthlyIncome(customer?.monthlyIncome);

      // Pre-fill emergency contact
      if (customer?.emergencyContactName != null && customer!.emergencyContactName!.isNotEmpty) {
        _emergencyNameController.text = customer.emergencyContactName!;
      }
      if (customer?.emergencyContactPhone != null && customer!.emergencyContactPhone!.isNotEmpty) {
        _emergencyPhoneController.text = customer.emergencyContactPhone!;
      }
      if (customer?.emergencyContactRelation != null && customer!.emergencyContactRelation!.isNotEmpty) {
        _emergencyRelationController.text = customer.emergencyContactRelation!;
      }

      // Pre-fill location codes (and load dependent dropdowns)
      if (customer?.provinceCode != null) {
        _selectedProvinceCode = customer!.provinceCode;
        _loadCities(customer.provinceCode!).then((_) {
          if (customer.cityCode != null) {
            setState(() => _selectedCityCode = customer.cityCode);
            _loadDistricts(customer.cityCode!).then((_) {
              if (customer.districtCode != null) {
                setState(() => _selectedDistrictCode = customer.districtCode);
                _loadVillages(customer.districtCode!).then((_) {
                  if (customer.villageCode != null) {
                    setState(() => _selectedVillageCode = customer.villageCode);
                  }
                });
              }
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nikController.dispose();
    _birthPlaceController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    setState(() => _isLoadingProvinces = true);
    try {
      final provinces = await _locationRepository.getProvinces();
      setState(() {
        _provinces = provinces;
        _isLoadingProvinces = false;
      });
    } catch (e) {
      setState(() => _isLoadingProvinces = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat provinsi: $e')),
        );
      }
    }
  }

  Future<void> _loadCities(String provinceCode) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      _districts = [];
      _villages = [];
      _selectedCityCode = null;
      _selectedDistrictCode = null;
      _selectedVillageCode = null;
    });
    try {
      final cities = await _locationRepository.getCities(provinceCode);
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });
    } catch (e) {
      setState(() => _isLoadingCities = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat kota: $e')),
        );
      }
    }
  }

  Future<void> _loadDistricts(String cityCode) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _villages = [];
      _selectedDistrictCode = null;
      _selectedVillageCode = null;
    });
    try {
      final districts = await _locationRepository.getDistricts(cityCode);
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
    } catch (e) {
      setState(() => _isLoadingDistricts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat kecamatan: $e')),
        );
      }
    }
  }

  Future<void> _loadVillages(String districtCode) async {
    setState(() {
      _isLoadingVillages = true;
      _villages = [];
      _selectedVillageCode = null;
    });
    try {
      final villages = await _locationRepository.getVillages(districtCode);
      setState(() {
        _villages = villages;
        _isLoadingVillages = false;
      });
    } catch (e) {
      setState(() => _isLoadingVillages = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat kelurahan: $e')),
        );
      }
    }
  }

  void _onProvinceChanged(String? code) {
    setState(() => _selectedProvinceCode = code);
    if (code != null) {
      _loadCities(code);
    }
  }

  void _onCityChanged(String? code) {
    setState(() => _selectedCityCode = code);
    if (code != null) {
      _loadDistricts(code);
    }
  }

  void _onDistrictChanged(String? code) {
    setState(() => _selectedDistrictCode = code);
    if (code != null) {
      _loadVillages(code);
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 17)),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_gender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih jenis kelamin')),
        );
        return;
      }
      if (_birthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih tanggal lahir')),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      // Format birth date
      final birthDateStr = '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';

      // Submit to API via BLoC
      final profileData = {
        // NIK is hidden temporarily, only include if not empty
        if (_nikController.text.isNotEmpty) 'nik': _nikController.text,
        'birth_place': _birthPlaceController.text,
        'birth_date': birthDateStr,
        'gender': _gender,
        // Always send phone since it's required
        'phone': _phoneController.text,
        'address': _addressController.text,
        'province_code': _selectedProvinceCode,
        'city_code': _selectedCityCode,
        'district_code': _selectedDistrictCode,
        'village_code': _selectedVillageCode,
        'occupation': _occupationController.text,
        'monthly_income': _selectedMonthlyIncome,
        'emergency_contact_name': _emergencyNameController.text,
        'emergency_contact_phone': _emergencyPhoneController.text,
        'emergency_contact_relation': _emergencyRelationController.text,
      };

      context.read<AuthBloc>().add(AuthUpdateProfile(data: profileData));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Profil Lengkap!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selamat! Profil Anda sudah lengkap. Anda dapat mulai menggunakan layanan gadai.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Mulai Sekarang'),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated && _isSubmitting) {
          setState(() => _isSubmitting = false);
          _showSuccessDialog();
        } else if (state is AuthError && _isSubmitting) {
          setState(() => _isSubmitting = false);
          _showErrorDialog(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: _buildFormCard(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GradientHeader(
      showBackButton: true,
      onBackPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
      paddingBottom: 36,
      child: const GradientHeaderTitle(
        title: 'Lengkapi Data Diri',
        subtitle: 'Data ini diperlukan untuk proses gadai & verifikasi akun',
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppInputStyles.cardDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // NIK - Hidden temporarily
            // _buildLabel('NIK (No. KTP)', required: true),
            // const SizedBox(height: 8),
            // TextFormField(
            //   controller: _nikController,
            //   decoration: _inputDecoration('16 digit NIK'),
            //   keyboardType: TextInputType.number,
            //   maxLength: 16,
            //   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            //   validator: (value) {
            //     if (value == null || value.isEmpty) return 'NIK wajib diisi';
            //     if (value.length != 16) return 'NIK harus 16 digit';
            //     return null;
            //   },
            // ),
            // const SizedBox(height: 16),

            // Birth Place & Date
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Tempat Lahir', required: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _birthPlaceController,
                        decoration: _inputDecoration('Kota'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Tanggal Lahir', required: true),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _selectBirthDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _birthDate != null
                                    ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                                    : 'Pilih',
                                style: TextStyle(
                                  color: _birthDate != null
                                      ? AppColors.textPrimary
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Gender
            _buildLabel('Jenis Kelamin', required: true),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildGenderOption('L', 'Laki-laki', Icons.male),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGenderOption('P', 'Perempuan', Icons.female),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Phone
            _buildLabel('No. Handphone', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              decoration: _inputDecoration('08123456789'),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) return 'No. HP wajib diisi';
                if (value.length < 10) return 'No. HP tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Address Section
            _buildSectionHeader('Alamat', Icons.location_on_outlined),
            const SizedBox(height: 16),

            // Province
            _buildLabel('Provinsi', required: true),
            const SizedBox(height: 8),
            _isLoadingProvinces
                ? _buildLoadingDropdown('Memuat provinsi...')
                : DropdownButtonFormField<String>(
                    value: _provinces.any((p) => p.code == _selectedProvinceCode) ? _selectedProvinceCode : null,
                    decoration: _inputDecoration('Pilih Provinsi'),
                    isExpanded: true,
                    items: _provinces.map((p) {
                      return DropdownMenuItem(
                        value: p.code,
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _onProvinceChanged,
                    validator: (value) => value == null ? 'Pilih provinsi' : null,
                  ),
            const SizedBox(height: 12),

            // City
            _buildLabel('Kota/Kabupaten', required: true),
            const SizedBox(height: 8),
            _isLoadingCities
                ? _buildLoadingDropdown('Memuat kota/kabupaten...')
                : DropdownButtonFormField<String>(
                    value: _cities.any((c) => c.code == _selectedCityCode) ? _selectedCityCode : null,
                    decoration: _inputDecoration('Pilih Kota/Kabupaten'),
                    isExpanded: true,
                    items: _cities.map((c) {
                      return DropdownMenuItem(
                        value: c.code,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _cities.isEmpty ? null : _onCityChanged,
                    validator: (value) => value == null ? 'Pilih kota' : null,
                  ),
            const SizedBox(height: 12),

            // District
            _buildLabel('Kecamatan', required: true),
            const SizedBox(height: 8),
            _isLoadingDistricts
                ? _buildLoadingDropdown('Memuat kecamatan...')
                : DropdownButtonFormField<String>(
                    value: _districts.any((d) => d.code == _selectedDistrictCode) ? _selectedDistrictCode : null,
                    decoration: _inputDecoration('Pilih Kecamatan'),
                    isExpanded: true,
                    items: _districts.map((d) {
                      return DropdownMenuItem(
                        value: d.code,
                        child: Text(d.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _districts.isEmpty ? null : _onDistrictChanged,
                    validator: (value) => value == null ? 'Pilih kecamatan' : null,
                  ),
            const SizedBox(height: 12),

            // Village
            _buildLabel('Kelurahan/Desa', required: true),
            const SizedBox(height: 8),
            _isLoadingVillages
                ? _buildLoadingDropdown('Memuat kelurahan/desa...')
                : DropdownButtonFormField<String>(
                    value: _villages.any((v) => v.code == _selectedVillageCode) ? _selectedVillageCode : null,
                    decoration: _inputDecoration('Pilih Kelurahan/Desa'),
                    isExpanded: true,
                    items: _villages.map((v) {
                      return DropdownMenuItem(
                        value: v.code,
                        child: Text(v.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _villages.isEmpty
                        ? null
                        : (value) => setState(() => _selectedVillageCode = value),
                    validator: (value) => value == null ? 'Pilih kelurahan' : null,
                  ),
            const SizedBox(height: 12),

            // Full Address
            _buildLabel('Alamat Lengkap', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              decoration: _inputDecoration('Jl. Nama Jalan No. XX, RT/RW ...'),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Alamat lengkap wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Additional Info Section
            _buildSectionHeader('Informasi Tambahan', Icons.work_outline),
            const SizedBox(height: 16),

            // Occupation
            _buildLabel('Pekerjaan'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _occupationController,
              decoration: _inputDecoration('Karyawan Swasta, Wiraswasta, dll'),
            ),
            const SizedBox(height: 12),

            // Monthly Income
            _buildLabel('Penghasilan Bulanan'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _incomeOptions.contains(_selectedMonthlyIncome) ? _selectedMonthlyIncome : null,
              decoration: _inputDecoration('Pilih Kisaran Penghasilan'),
              isExpanded: true,
              items: _incomeOptions.map((income) {
                return DropdownMenuItem(
                  value: income,
                  child: Text(income, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedMonthlyIncome = value),
            ),
            const SizedBox(height: 24),

            // Emergency Contact Section
            _buildSectionHeader('Kontak Darurat', Icons.phone_outlined),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Nama'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emergencyNameController,
                        decoration: _inputDecoration('Nama lengkap'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Hubungan'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emergencyRelationController,
                        decoration: _inputDecoration('Suami, Istri, dll'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildLabel('No. Telepon'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emergencyPhoneController,
              decoration: _inputDecoration('08123456789'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                onPressed: _isSubmitting ? null : _onSubmit,
                isLoading: _isSubmitting,
                text: 'Simpan & Lanjutkan',
                icon: Icons.check,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _gender == value;
    final color = value == 'L' ? Colors.blue : Colors.pink;

    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF15803D) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF15803D) : color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF15803D) : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return AppInputStyles.formLabel(text, required: required);
  }

  InputDecoration _inputDecoration(String hint) {
    return AppInputStyles.inputDecoration(hintText: hint);
  }

  Widget _buildLoadingDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF8FAFC),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
