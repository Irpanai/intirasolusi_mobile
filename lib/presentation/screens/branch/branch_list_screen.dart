import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/repositories/branch_repository.dart';

class BranchListScreen extends StatefulWidget {
  const BranchListScreen({super.key});

  @override
  State<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final BranchRepository _branchRepository = BranchRepository();
  
  late TabController _tabController;
  
  List<BranchModel> _allBranches = [];
  List<BranchModel> _nearbyBranches = [];
  List<BranchModel> _filteredBranches = [];
  
  bool _isLoading = true;
  bool _isLoadingNearby = false;
  String? _error;
  String? _nearbyError;
  
  Position? _currentPosition;
  bool _locationPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadBranches();
    _checkLocationAndLoadNearby();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && _nearbyBranches.isEmpty && !_isLoadingNearby) {
      _checkLocationAndLoadNearby();
    }
    setState(() {
      _applySearch(_searchController.text);
    });
  }

  Future<void> _loadBranches() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final branches = await _branchRepository.getBranches();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _allBranches = branches;
        _applySearch(_searchController.text);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _checkLocationAndLoadNearby() async {
    if (!mounted) return;
    setState(() {
      _isLoadingNearby = true;
      _nearbyError = null;
      _locationPermissionDenied = false;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _isLoadingNearby = false;
          _nearbyError = 'Layanan lokasi tidak aktif. Aktifkan GPS untuk melihat cabang terdekat.';
        });
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _isLoadingNearby = false;
            _locationPermissionDenied = true;
            _nearbyError = 'Izin lokasi ditolak. Izinkan akses lokasi untuk melihat cabang terdekat.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _isLoadingNearby = false;
          _locationPermissionDenied = true;
          _nearbyError = 'Izin lokasi ditolak permanen. Buka pengaturan untuk mengizinkan akses lokasi.';
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _currentPosition = position;
      await _loadNearbyBranches();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingNearby = false;
        _nearbyError = 'Gagal mendapatkan lokasi: $e';
      });
    }
  }

  Future<void> _loadNearbyBranches() async {
    if (_currentPosition == null) return;

    if (!mounted) return;
    setState(() {
      _isLoadingNearby = true;
      _nearbyError = null;
    });

    try {
      final branches = await _branchRepository.getNearbyBranches(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 50, // 50 km radius
      );
      if (!mounted) return;
      setState(() {
        _isLoadingNearby = false;
        _nearbyBranches = branches;
        _applySearch(_searchController.text);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingNearby = false;
        _nearbyError = e.toString();
      });
    }
  }

  void _onSearch(String query) {
    _applySearch(query);
  }

  void _applySearch(String query) {
    final sourceList = _tabController.index == 0 ? _allBranches : _nearbyBranches;
    
    setState(() {
      if (query.isEmpty) {
        _filteredBranches = List.from(sourceList);
      } else {
        _filteredBranches = sourceList.where((branch) {
          final searchStr = '${branch.name} ${branch.address ?? ''} ${branch.code} ${branch.city ?? ''}'.toLowerCase();
          return searchStr.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with Search and Tabs
          _buildHeader(),

          // Content with TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Branches Tab
                _buildAllBranchesTab(),
                // Nearby Branches Tab
                _buildNearbyBranchesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllBranchesTab() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Memuat cabang...');
    }
    if (_error != null) {
      return _buildErrorState(_error!, _loadBranches);
    }
    if (_filteredBranches.isEmpty) {
      return const EmptyState(
        icon: Icons.location_off,
        title: 'Tidak Ada Cabang',
        subtitle: 'Cabang tidak ditemukan.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBranches,
      child: _buildBranchList(),
    );
  }

  Widget _buildNearbyBranchesTab() {
    if (_isLoadingNearby) {
      return const LoadingWidget(message: 'Mencari cabang terdekat...');
    }
    if (_nearbyError != null) {
      return _buildLocationErrorState();
    }
    if (_filteredBranches.isEmpty) {
      return const EmptyState(
        icon: Icons.location_off,
        title: 'Tidak Ada Cabang Terdekat',
        subtitle: 'Tidak ditemukan cabang dalam radius 50 km.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadNearbyBranches,
      child: _buildBranchList(showDistance: true),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _locationPermissionDenied ? Icons.location_disabled : Icons.location_off,
              size: 48,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              _nearbyError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (_locationPermissionDenied)
              ElevatedButton(
                onPressed: () => Geolocator.openAppSettings(),
                child: const Text('Buka Pengaturan'),
              )
            else
              ElevatedButton(
                onPressed: _checkLocationAndLoadNearby,
                child: const Text('Coba Lagi'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Lokasi Cabang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearch,
                      cursorColor: AppColors.primary,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari cabang...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab Bar
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.list, size: 20),
                  text: 'Semua Cabang',
                ),
                Tab(
                  icon: Icon(Icons.near_me, size: 20),
                  text: 'Terdekat',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchList({bool showDistance = false}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBranches.length,
      itemBuilder: (context, index) {
        final branch = _filteredBranches[index];
        return _buildBranchCard(branch, showDistance: showDistance);
      },
    );
  }

  Widget _buildBranchCard(BranchModel branch, {bool showDistance = false}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/branches/${branch.code}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          branch.code,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: branch.isActive
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      branch.isActive ? 'Buka' : 'Tutup',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: branch.isActive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      branch.address ?? '-',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Phone and Detail button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        branch.phone ?? '-',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Show distance if available
                      if (showDistance && branch.distance != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.near_me,
                                size: 12,
                                color: AppColors.info,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                branch.distanceText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        'Detail',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
