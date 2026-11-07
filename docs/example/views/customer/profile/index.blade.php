@extends('customer.layouts.app')

@section('title', 'Profil Saya')

@section('content')
<div class="min-h-screen pb-24">
    <!-- Header -->
    <div class="bg-gradient-to-br from-primary-600 to-primary-800 text-white pt-6 pb-16 px-6">
        <h1 class="text-xl font-bold mb-6">Profil Saya</h1>
        
        <!-- Profile Card -->
        <div class="flex items-center">
            <div id="avatar" class="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center text-2xl font-bold">
                <span id="avatar-initial">-</span>
            </div>
            <div class="ml-4 flex-1">
                <h2 id="user-name" class="text-lg font-semibold">-</h2>
                <p id="user-email" class="text-primary-100 text-sm">-</p>
                <div id="profile-status" class="mt-1">
                    <span class="skeleton h-5 w-24 rounded-full inline-block bg-white/20"></span>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Content -->
    <div class="px-6 -mt-8">
        <!-- Profile Completion Alert -->
        <div id="complete-profile-alert" class="bg-yellow-50 border border-yellow-200 rounded-xl p-4 mb-4 hidden">
            <div class="flex items-start">
                <i class="fas fa-exclamation-triangle text-yellow-500 mt-1 mr-3"></i>
                <div class="flex-1">
                    <p class="font-medium text-yellow-800">Lengkapi Profil Anda</p>
                    <p class="text-sm text-yellow-700 mt-1">Lengkapi data profil untuk dapat mengajukan gadai online.</p>
                    <a href="{{ route('customer.profile.edit') }}" class="inline-block mt-2 px-4 py-2 bg-yellow-500 text-white rounded-lg text-sm font-medium hover:bg-yellow-600 transition">
                        Lengkapi Sekarang
                    </a>
                </div>
            </div>
        </div>
        
        <!-- Info Card -->
        <div class="bg-white rounded-xl shadow-lg overflow-hidden mb-4">
            <div class="p-4 border-b border-gray-100 flex items-center justify-between">
                <h3 class="font-semibold text-gray-800">Informasi Pribadi</h3>
                <a href="{{ route('customer.profile.edit') }}" class="text-primary-600 text-sm font-medium hover:text-primary-700">
                    <i class="fas fa-edit mr-1"></i> Edit
                </a>
            </div>
            <div class="p-4 space-y-4">
                <div class="flex items-start">
                    <div class="w-8 text-gray-400">
                        <i class="fas fa-id-card"></i>
                    </div>
                    <div class="flex-1">
                        <p class="text-xs text-gray-400">NIK</p>
                        <p id="profile-nik" class="text-gray-800 font-medium">-</p>
                    </div>
                </div>
                <div class="flex items-start">
                    <div class="w-8 text-gray-400">
                        <i class="fas fa-phone"></i>
                    </div>
                    <div class="flex-1">
                        <p class="text-xs text-gray-400">Telepon</p>
                        <p id="profile-phone" class="text-gray-800 font-medium">-</p>
                    </div>
                </div>
                <div class="flex items-start">
                    <div class="w-8 text-gray-400">
                        <i class="fas fa-birthday-cake"></i>
                    </div>
                    <div class="flex-1">
                        <p class="text-xs text-gray-400">Tanggal Lahir</p>
                        <p id="profile-dob" class="text-gray-800 font-medium">-</p>
                    </div>
                </div>
                <div class="flex items-start">
                    <div class="w-8 text-gray-400">
                        <i class="fas fa-venus-mars"></i>
                    </div>
                    <div class="flex-1">
                        <p class="text-xs text-gray-400">Jenis Kelamin</p>
                        <p id="profile-gender" class="text-gray-800 font-medium">-</p>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Address Card -->
        <div class="bg-white rounded-xl shadow-lg overflow-hidden mb-4">
            <div class="p-4 border-b border-gray-100">
                <h3 class="font-semibold text-gray-800">Alamat</h3>
            </div>
            <div class="p-4 space-y-4">
                <div class="flex items-start">
                    <div class="w-8 text-gray-400">
                        <i class="fas fa-map-marker-alt"></i>
                    </div>
                    <div class="flex-1">
                        <p id="profile-address" class="text-gray-800">-</p>
                        <p id="profile-region" class="text-gray-500 text-sm mt-1">-</p>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Work Info Card -->
        <div class="bg-white rounded-xl shadow-lg overflow-hidden mb-4">
            <div class="p-4 border-b border-gray-100">
                <h3 class="font-semibold text-gray-800">Pekerjaan</h3>
            </div>
            <div class="p-4 space-y-4">
                <div class="flex items-start">
                    <div class="w-8 text-gray-400">
                        <i class="fas fa-briefcase"></i>
                    </div>
                    <div class="flex-1">
                        <p class="text-xs text-gray-400">Pekerjaan</p>
                        <p id="profile-occupation" class="text-gray-800 font-medium">-</p>
                    </div>
                </div>
                <div class="flex items-start">
                    <div class="w-8 text-gray-400">
                        <i class="fas fa-wallet"></i>
                    </div>
                    <div class="flex-1">
                        <p class="text-xs text-gray-400">Pendapatan Bulanan</p>
                        <p id="profile-income" class="text-gray-800 font-medium">-</p>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Emergency Contact Card -->
        <div class="bg-white rounded-xl shadow-lg overflow-hidden mb-4">
            <div class="p-4 border-b border-gray-100">
                <h3 class="font-semibold text-gray-800">Kontak Darurat</h3>
            </div>
            <div class="p-4 space-y-4">
                <div class="flex items-start">
                    <div class="w-8 text-gray-400">
                        <i class="fas fa-user-friends"></i>
                    </div>
                    <div class="flex-1">
                        <p class="text-xs text-gray-400">Nama</p>
                        <p id="emergency-name" class="text-gray-800 font-medium">-</p>
                    </div>
                </div>
                <div class="flex items-start">
                    <div class="w-8 text-gray-400">
                        <i class="fas fa-phone-alt"></i>
                    </div>
                    <div class="flex-1">
                        <p class="text-xs text-gray-400">Telepon</p>
                        <p id="emergency-phone" class="text-gray-800 font-medium">-</p>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Menu Items -->
        <div class="bg-white rounded-xl shadow-lg overflow-hidden mb-4">
            <a href="{{ route('customer.branches.index') }}" class="flex items-center justify-between p-4 hover:bg-gray-50 transition border-b border-gray-100">
                <div class="flex items-center">
                    <div class="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center mr-3">
                        <i class="fas fa-store text-primary-600"></i>
                    </div>
                    <span class="font-medium text-gray-800">Lokasi Cabang</span>
                </div>
                <i class="fas fa-chevron-right text-gray-400"></i>
            </a>
            <a href="#" onclick="showChangePassword()" class="flex items-center justify-between p-4 hover:bg-gray-50 transition border-b border-gray-100">
                <div class="flex items-center">
                    <div class="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center mr-3">
                        <i class="fas fa-lock text-blue-600"></i>
                    </div>
                    <span class="font-medium text-gray-800">Ubah Password</span>
                </div>
                <i class="fas fa-chevron-right text-gray-400"></i>
            </a>
            <a href="#" onclick="showHelp()" class="flex items-center justify-between p-4 hover:bg-gray-50 transition">
                <div class="flex items-center">
                    <div class="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center mr-3">
                        <i class="fas fa-question-circle text-green-600"></i>
                    </div>
                    <span class="font-medium text-gray-800">Bantuan</span>
                </div>
                <i class="fas fa-chevron-right text-gray-400"></i>
            </a>
        </div>
        
        <!-- Logout Button -->
        <button onclick="handleLogout()" class="w-full bg-red-50 hover:bg-red-100 text-red-600 font-medium py-4 rounded-xl transition flex items-center justify-center">
            <i class="fas fa-sign-out-alt mr-2"></i>
            Keluar
        </button>
        
        <!-- App Version -->
        <p class="text-center text-gray-400 text-xs mt-4">Intira Customer App v1.0.0</p>
    </div>
</div>

<!-- Change Password Modal -->
<div id="password-modal" class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center hidden">
    <div class="bg-white rounded-2xl p-6 m-4 w-full max-w-sm" onclick="event.stopPropagation()">
        <h3 class="font-semibold text-lg mb-4">Ubah Password</h3>
        <form id="password-form">
            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-1">Password Lama</label>
                <input type="password" id="current_password" class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none" required>
            </div>
            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-1">Password Baru</label>
                <input type="password" id="new_password" class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none" required minlength="8">
            </div>
            <div class="mb-6">
                <label class="block text-sm font-medium text-gray-700 mb-1">Konfirmasi Password Baru</label>
                <input type="password" id="new_password_confirmation" class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none" required>
            </div>
            <div class="flex space-x-3">
                <button type="button" onclick="hidePasswordModal()" class="flex-1 bg-gray-100 hover:bg-gray-200 text-gray-700 font-medium py-3 rounded-lg transition">
                    Batal
                </button>
                <button type="submit" class="flex-1 bg-primary-600 hover:bg-primary-700 text-white font-medium py-3 rounded-lg transition">
                    Simpan
                </button>
            </div>
        </form>
    </div>
</div>

<!-- Bottom Navigation -->
@include('customer.partials.bottom-nav', ['active' => 'profile'])
@endsection

@push('scripts')
<script>
    async function loadProfile() {
        const response = await api.get('/profile');
        
        if (response.ok && response.data.success) {
            renderProfile(response.data.data);
        } else {
            UI.toast('Gagal memuat profil', 'error');
        }
    }
    
    function renderProfile(data) {
        const user = data.user || data;
        const customer = data.customer || user.customer || {};
        
        // Header
        document.getElementById('user-name').textContent = user.name || '-';
        document.getElementById('user-email').textContent = user.email || '-';
        document.getElementById('avatar-initial').textContent = (user.name || '-').charAt(0).toUpperCase();
        
        // Profile status
        const statusContainer = document.getElementById('profile-status');
        if (customer.is_profile_complete) {
            statusContainer.innerHTML = '<span class="px-2 py-1 bg-green-500/20 text-green-100 rounded-full text-xs"><i class="fas fa-check-circle mr-1"></i>Profil Lengkap</span>';
            document.getElementById('complete-profile-alert').classList.add('hidden');
        } else {
            statusContainer.innerHTML = '<span class="px-2 py-1 bg-yellow-500/20 text-yellow-100 rounded-full text-xs"><i class="fas fa-exclamation-circle mr-1"></i>Profil Belum Lengkap</span>';
            document.getElementById('complete-profile-alert').classList.remove('hidden');
        }
        
        // Personal info
        document.getElementById('profile-nik').textContent = customer.nik || '-';
        document.getElementById('profile-phone').textContent = customer.phone || user.phone || '-';
        document.getElementById('profile-dob').textContent = customer.birth_date_formatted || UI.formatDate(customer.birth_date) || '-';
        document.getElementById('profile-gender').textContent = customer.gender === 'L' ? 'Laki-laki' : customer.gender === 'P' ? 'Perempuan' : '-';
        
        // Address
        const addressParts = [customer.address].filter(Boolean);
        document.getElementById('profile-address').textContent = addressParts.length > 0 ? addressParts.join(' ') : '-';
        
        const regionParts = [
            customer.village?.name,
            customer.district?.name,
            customer.city?.name,
            customer.province?.name
        ].filter(Boolean);
        document.getElementById('profile-region').textContent = regionParts.length > 0 ? regionParts.join(', ') : '-';
        
        // Work info
        document.getElementById('profile-occupation').textContent = customer.occupation || '-';
        document.getElementById('profile-income').textContent = customer.monthly_income || '-';
        
        // Emergency contact
        document.getElementById('emergency-name').textContent = customer.emergency_contact_name || '-';
        document.getElementById('emergency-phone').textContent = customer.emergency_contact_phone || '-';
    }
    
    function showChangePassword() {
        document.getElementById('password-modal').classList.remove('hidden');
    }
    
    function hidePasswordModal() {
        document.getElementById('password-modal').classList.add('hidden');
        document.getElementById('password-form').reset();
    }
    
    document.getElementById('password-form').addEventListener('submit', async function(e) {
        e.preventDefault();
        
        const newPass = document.getElementById('new_password').value;
        const confirmPass = document.getElementById('new_password_confirmation').value;
        
        if (newPass !== confirmPass) {
            UI.toast('Konfirmasi password tidak cocok', 'warning');
            return;
        }
        
        UI.showLoading();
        
        const response = await api.put('/profile/password', {
            current_password: document.getElementById('current_password').value,
            password: newPass,
            password_confirmation: confirmPass
        });
        
        UI.hideLoading();
        
        if (response.ok && response.data.success) {
            UI.toast('Password berhasil diubah', 'success');
            hidePasswordModal();
        } else {
            UI.toast(response.data.message || 'Gagal mengubah password', 'error');
        }
    });
    
    function showHelp() {
        UI.toast('Hubungi CS: 0800-1234-5678', 'info');
    }
    
    async function handleLogout() {
        if (!confirm('Yakin ingin keluar?')) return;
        
        UI.showLoading();
        await api.post('/logout');
        UI.hideLoading();
        
        TokenManager.remove();
        window.location.href = '{{ route('customer.login') }}';
    }
    
    // Close modal on outside click
    document.getElementById('password-modal').addEventListener('click', function(e) {
        if (e.target === this) {
            hidePasswordModal();
        }
    });
    
    // Init
    document.addEventListener('DOMContentLoaded', loadProfile);
</script>
@endpush
