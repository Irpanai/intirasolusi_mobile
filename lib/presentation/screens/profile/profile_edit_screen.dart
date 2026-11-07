import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/app_input_styles.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../data/models/location_model.dart';
import '../../blocs/auth/auth_bloc.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
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

  // Location display names (from database, shown immediately)
  String? _provinceName;
  String? _cityName;
  String? _districtName;
  String? _villageName;

  // Track which location fields are in edit/dropdown mode
  bool _isEditingProvince = false;
  bool _isEditingCity = false;
  bool _isEditingDistrict = false;
  bool _isEditingVillage = false;

  bool _isProfileComplete = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Location data from API
  List<ProvinceModel> _provinces = [];
  List<CityModel> _cities = [];
  List<DistrictModel> _districts = [];
  List<VillageModel> _villages = [];

  // Loading states
  bool _isLoadingProvinces = false;
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
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    // Load profile from current state (show names immediately, no cascading dropdown load)
    _loadProfile();
    // Also fetch fresh data from API - BlocListener will re-populate if data changes
    context.read<AuthBloc>().add(AuthLoadProfile());
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

  Future<void> _loadCities(String provinceCode, {bool setSelected = false, String? selectedCode}) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      _districts = [];
      _villages = [];
      if (!setSelected) {
        _selectedCityCode = null;
        _selectedDistrictCode = null;
        _selectedVillageCode = null;
      }
    });
    try {
      final cities = await _locationRepository.getCities(provinceCode);
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
        if (setSelected && selectedCode != null) {
          _selectedCityCode = selectedCode;
        }
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

  Future<void> _loadDistricts(String cityCode, {bool setSelected = false, String? selectedCode}) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _villages = [];
      if (!setSelected) {
        _selectedDistrictCode = null;
        _selectedVillageCode = null;
      }
    });
    try {
      final districts = await _locationRepository.getDistricts(cityCode);
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
        if (setSelected && selectedCode != null) {
          _selectedDistrictCode = selectedCode;
        }
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

  Future<void> _loadVillages(String districtCode, {bool setSelected = false, String? selectedCode}) async {
    setState(() {
      _isLoadingVillages = true;
      _villages = [];
      if (!setSelected) {
        _selectedVillageCode = null;
      }
    });
    try {
      final villages = await _locationRepository.getVillages(districtCode);
      setState(() {
        _villages = villages;
        _isLoadingVillages = false;
        if (setSelected && selectedCode != null) {
          _selectedVillageCode = selectedCode;
        }
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

  Future<void> _loadProfile() async {
    final authState = context.read<AuthBloc>().state;
    
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      final customer = user.customer;

      setState(() {
        _isLoading = false;
        
        // Load customer data if exists
        if (customer != null) {
          _nikController.text = customer.nik ?? '';
          _birthPlaceController.text = customer.birthPlace ?? '';
          _phoneController.text = customer.phone ?? user.phone ?? '';
          // Map gender from API format to form format
          final g = (customer.gender ?? '').toLowerCase();
          if (g == 'male' || g == 'l' || g == 'laki-laki') {
            _gender = 'L';
          } else if (g == 'female' || g == 'p' || g == 'perempuan') {
            _gender = 'P';
          }
          _addressController.text = customer.address ?? '';
          _occupationController.text = customer.occupation ?? '';
          _selectedMonthlyIncome = _parseMonthlyIncome(customer.monthlyIncome);
          _emergencyNameController.text = customer.emergencyContactName ?? '';
          _emergencyPhoneController.text = customer.emergencyContactPhone ?? '';
          _emergencyRelationController.text = customer.emergencyContactRelation ?? '';
          _isProfileComplete = customer.isProfileComplete;
          
          // Parse birth date
          if (customer.birthDate != null && customer.birthDate!.isNotEmpty) {
            try {
              _birthDate = DateTime.parse(customer.birthDate!);
            } catch (_) {}
          }
          
          // Store location codes AND names (show names immediately, no cascade load)
          _selectedProvinceCode = customer.provinceCode;
          _selectedCityCode = customer.cityCode;
          _selectedDistrictCode = customer.districtCode;
          _selectedVillageCode = customer.villageCode;
          _provinceName = customer.provinceName;
          _cityName = customer.cityName;
          _districtName = customer.districtName;
          _villageName = customer.villageName;

          // Reset to display mode (text, not dropdown)
          _isEditingProvince = false;
          _isEditingCity = false;
          _isEditingDistrict = false;
          _isEditingVillage = false;
        } else {
          // No customer data yet, just load user phone
          _phoneController.text = user.phone ?? '';
          // No saved names, start in edit mode so dropdowns show
          _isEditingProvince = true;
          _isEditingCity = true;
          _isEditingDistrict = true;
          _isEditingVillage = true;
        }
      });

      // If no location data, load provinces for dropdown
      if (customer == null || customer.provinceCode == null) {
        await _loadProvinces();
      }
      
      // If we have names but no codes, resolve codes from names in background
      if (customer != null && customer.provinceCode == null && customer.provinceName != null) {
        await _resolveLocationCodesFromNames(
          customer.provinceName,
          customer.cityName,
          customer.districtName,
          customer.villageName,
        );
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  // Resolve location codes by matching names against API data
  Future<void> _resolveLocationCodesFromNames(
    String? provinceName,
    String? cityName,
    String? districtName,
    String? villageName,
  ) async {
    if (provinceName == null || provinceName.isEmpty) return;
    
    try {
      // Load provinces if not already loaded
      if (_provinces.isEmpty) {
        final provinces = await _locationRepository.getProvinces();
        if (!mounted) return;
        setState(() => _provinces = provinces);
      }
      
      // Match province by name (case-insensitive)
      final province = _provinces.cast<ProvinceModel?>().firstWhere(
        (p) => p!.name.toLowerCase() == provinceName.toLowerCase(),
        orElse: () => null,
      );
      if (province == null || !mounted) return;
      setState(() => _selectedProvinceCode = province.code);
      
      if (cityName == null || cityName.isEmpty) return;
      
      // Load and match city
      final cities = await _locationRepository.getCities(province.code);
      if (!mounted) return;
      setState(() => _cities = cities);
      
      final city = cities.cast<CityModel?>().firstWhere(
        (c) => c!.name.toLowerCase() == cityName.toLowerCase(),
        orElse: () => null,
      );
      if (city == null) return;
      setState(() => _selectedCityCode = city.code);
      
      if (districtName == null || districtName.isEmpty) return;
      
      // Load and match district
      final districts = await _locationRepository.getDistricts(city.code);
      if (!mounted) return;
      setState(() => _districts = districts);
      
      final district = districts.cast<DistrictModel?>().firstWhere(
        (d) => d!.name.toLowerCase() == districtName.toLowerCase(),
        orElse: () => null,
      );
      if (district == null) return;
      setState(() => _selectedDistrictCode = district.code);
      
      if (villageName == null || villageName.isEmpty) return;
      
      // Load and match village
      final villages = await _locationRepository.getVillages(district.code);
      if (!mounted) return;
      setState(() {
        _villages = villages;
        final village = villages.cast<VillageModel?>().firstWhere(
          (v) => v!.name.toLowerCase() == villageName.toLowerCase(),
          orElse: () => null,
        );
        if (village != null) {
          _selectedVillageCode = village.code;
        }
      });
    } catch (_) {
      // Silently fail - user can still manually select
    }
  }

  // --- Start editing location fields (load dropdown data on demand) ---

  Future<void> _startEditingProvince() async {
    setState(() => _isEditingProvince = true);
    if (_provinces.isEmpty) {
      await _loadProvinces();
    }
  }

  Future<void> _startEditingCity() async {
    setState(() => _isEditingCity = true);
    if (_cities.isEmpty && _selectedProvinceCode != null) {
      await _loadCities(_selectedProvinceCode!, setSelected: true, selectedCode: _selectedCityCode);
    }
  }

  Future<void> _startEditingDistrict() async {
    setState(() => _isEditingDistrict = true);
    if (_districts.isEmpty && _selectedCityCode != null) {
      await _loadDistricts(_selectedCityCode!, setSelected: true, selectedCode: _selectedDistrictCode);
    }
  }

  Future<void> _startEditingVillage() async {
    setState(() => _isEditingVillage = true);
    if (_villages.isEmpty && _selectedDistrictCode != null) {
      await _loadVillages(_selectedDistrictCode!, setSelected: true, selectedCode: _selectedVillageCode);
    }
  }

  // --- On changed handlers (cascade resets child fields) ---

  void _onProvinceChanged(String? code) {
    final name = code != null
        ? _provinces.firstWhere((p) => p.code == code).name
        : null;
    setState(() {
      _selectedProvinceCode = code;
      _provinceName = name;
      // Reset children
      _selectedCityCode = null;
      _selectedDistrictCode = null;
      _selectedVillageCode = null;
      _cityName = null;
      _districtName = null;
      _villageName = null;
      _cities = [];
      _districts = [];
      _villages = [];
      // Auto-open city dropdown
      _isEditingCity = true;
      _isEditingDistrict = false;
      _isEditingVillage = false;
    });
    if (code != null) {
      _loadCities(code);
    }
  }

  void _onCityChanged(String? code) {
    final name = code != null
        ? _cities.firstWhere((c) => c.code == code).name
        : null;
    setState(() {
      _selectedCityCode = code;
      _cityName = name;
      // Reset children
      _selectedDistrictCode = null;
      _selectedVillageCode = null;
      _districtName = null;
      _villageName = null;
      _districts = [];
      _villages = [];
      // Auto-open district dropdown
      _isEditingDistrict = true;
      _isEditingVillage = false;
    });
    if (code != null) {
      _loadDistricts(code);
    }
  }

  void _onDistrictChanged(String? code) {
    final name = code != null
        ? _districts.firstWhere((d) => d.code == code).name
        : null;
    setState(() {
      _selectedDistrictCode = code;
      _districtName = name;
      // Reset children
      _selectedVillageCode = null;
      _villageName = null;
      _villages = [];
      // Auto-open village dropdown
      _isEditingVillage = true;
    });
    if (code != null) {
      _loadVillages(code);
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990, 1, 1),
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
      // Validate location codes are present (server requires them)
      if (_selectedProvinceCode == null || _selectedCityCode == null ||
          _selectedDistrictCode == null || _selectedVillageCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih ulang lokasi (provinsi, kota, kecamatan, kelurahan)')),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      // Format birth date
      final birthDateStr = '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';

      // Submit to API via BLoC
      final profileData = <String, dynamic>{
        'nik': _nikController.text,
        'birth_place': _birthPlaceController.text,
        'birth_date': birthDateStr,
        'gender': _gender,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'province_code': _selectedProvinceCode,
        'city_code': _selectedCityCode,
        'district_code': _selectedDistrictCode,
        'village_code': _selectedVillageCode,
        'occupation': _occupationController.text,
      };

      if (_selectedMonthlyIncome != null) profileData['monthly_income'] = _selectedMonthlyIncome;
      if (_emergencyNameController.text.isNotEmpty) profileData['emergency_contact_name'] = _emergencyNameController.text;
      if (_emergencyPhoneController.text.isNotEmpty) profileData['emergency_contact_phone'] = _emergencyPhoneController.text;
      if (_emergencyRelationController.text.isNotEmpty) profileData['emergency_contact_relation'] = _emergencyRelationController.text;

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
              'Profil Diperbarui',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Data profil Anda berhasil disimpan.',
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
                Navigator.pop(context); // Go back to profile
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Kembali ke Profil'),
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
        if (state is AuthAuthenticated) {
          if (_isSubmitting) {
            setState(() => _isSubmitting = false);
            _showSuccessDialog();
          } else {
            // Profile data loaded from API, populate form
            _loadProfile();
          }
        } else if (state is AuthError) {
          if (_isSubmitting) {
            setState(() => _isSubmitting = false);
            _showErrorDialog(state.message);
          } else {
            setState(() => _isLoading = false);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const LoadingWidget(message: 'Memuat profil...')
                  : SingleChildScrollView(
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
      paddingBottom: 36,
      child: const GradientHeaderTitle(
        title: 'Edit Profil Saya',
        subtitle: 'Perbarui identitas, kontak, dan alamat domisili',
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
            // NIK
            _buildLabel('NIK (No. KTP)', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nikController,
              decoration: _inputDecoration('16 digit NIK').copyWith(
                fillColor: _isProfileComplete ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
              ),
              enabled: !_isProfileComplete,
              keyboardType: TextInputType.number,
              maxLength: 16,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) return 'NIK wajib diisi';
                if (value.length != 16) return 'NIK harus 16 digit';
                return null;
              },
            ),
            if (_isProfileComplete)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'NIK tidak dapat diubah setelah profil lengkap',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            const SizedBox(height: 16),

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
            _buildLocationSelector(
              currentName: _provinceName,
              isEditing: _isEditingProvince,
              isLoading: _isLoadingProvinces,
              loadingText: 'Memuat provinsi...',
              hint: 'Pilih Provinsi',
              selectedCode: _selectedProvinceCode,
              items: _provinces.map((p) => DropdownMenuItem(value: p.code, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
              matchesCode: (code) => _provinces.any((p) => p.code == code),
              onStartEditing: _startEditingProvince,
              onChanged: _onProvinceChanged,
            ),
            const SizedBox(height: 12),

            // City
            _buildLabel('Kota/Kabupaten', required: true),
            const SizedBox(height: 8),
            _buildLocationSelector(
              currentName: _cityName,
              isEditing: _isEditingCity,
              isLoading: _isLoadingCities,
              loadingText: 'Memuat kota/kabupaten...',
              hint: 'Pilih Kota/Kabupaten',
              selectedCode: _selectedCityCode,
              items: _cities.map((c) => DropdownMenuItem(value: c.code, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
              matchesCode: (code) => _cities.any((c) => c.code == code),
              onStartEditing: _startEditingCity,
              onChanged: _onCityChanged,
            ),
            const SizedBox(height: 12),

            // District
            _buildLabel('Kecamatan', required: true),
            const SizedBox(height: 8),
            _buildLocationSelector(
              currentName: _districtName,
              isEditing: _isEditingDistrict,
              isLoading: _isLoadingDistricts,
              loadingText: 'Memuat kecamatan...',
              hint: 'Pilih Kecamatan',
              selectedCode: _selectedDistrictCode,
              items: _districts.map((d) => DropdownMenuItem(value: d.code, child: Text(d.name, overflow: TextOverflow.ellipsis))).toList(),
              matchesCode: (code) => _districts.any((d) => d.code == code),
              onStartEditing: _startEditingDistrict,
              onChanged: _onDistrictChanged,
            ),
            const SizedBox(height: 12),

            // Village
            _buildLabel('Kelurahan/Desa', required: true),
            const SizedBox(height: 8),
            _buildLocationSelector(
              currentName: _villageName,
              isEditing: _isEditingVillage,
              isLoading: _isLoadingVillages,
              loadingText: 'Memuat kelurahan/desa...',
              hint: 'Pilih Kelurahan/Desa',
              selectedCode: _selectedVillageCode,
              items: _villages.map((v) => DropdownMenuItem(value: v.code, child: Text(v.name, overflow: TextOverflow.ellipsis))).toList(),
              matchesCode: (code) => _villages.any((v) => v.code == code),
              onStartEditing: _startEditingVillage,
              onChanged: (value) {
                final name = value != null
                    ? _villages.firstWhere((v) => v.code == value).name
                    : null;
                setState(() {
                  _selectedVillageCode = value;
                  _villageName = name;
                });
              },
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
                onPressed: _onSubmit,
                text: 'Simpan Perubahan',
                icon: Icons.save,
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

  Widget _buildLocationSelector({
    required String? currentName,
    required bool isEditing,
    required bool isLoading,
    required String loadingText,
    required String hint,
    required String? selectedCode,
    required List<DropdownMenuItem<String>> items,
    required bool Function(String?) matchesCode,
    required VoidCallback onStartEditing,
    required ValueChanged<String?> onChanged,
  }) {
    // State 1: Has saved name and not in edit mode → show text, tap to edit
    if (!isEditing && currentName != null && currentName.isNotEmpty) {
      return GestureDetector(
        onTap: onStartEditing,
        child: InputDecorator(
          decoration: _inputDecoration(hint),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  currentName,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
            ],
          ),
        ),
      );
    }

    // State 2: Loading dropdown data
    if (isLoading) {
      return _buildLoadingDropdown(loadingText);
    }

    // State 3: Edit mode with dropdown
    return DropdownButtonFormField<String>(
      value: matchesCode(selectedCode) ? selectedCode : null,
      decoration: _inputDecoration(hint),
      isExpanded: true,
      items: items,
      onChanged: items.isEmpty ? null : onChanged,
    );
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
