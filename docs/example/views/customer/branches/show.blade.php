@extends('customer.layouts.app')

@section('title', 'Detail Cabang')

@section('content')
<div class="min-h-screen pb-6" id="page-content">
    <!-- Loading State -->
    <div id="loading-state">
        <div class="skeleton h-48 w-full"></div>
        <div class="px-6 -mt-4">
            <div class="skeleton h-32 rounded-xl mb-4"></div>
            <div class="skeleton h-48 rounded-xl"></div>
        </div>
    </div>
    
    <!-- Content -->
    <div id="main-content" class="hidden">
        <!-- Header Image/Map -->
        <div class="relative h-48 bg-gray-200">
            <div id="branch-map" class="w-full h-full">
                <div class="w-full h-full flex items-center justify-center bg-gray-100">
                    <i class="fas fa-map-marked-alt text-4xl text-gray-300"></i>
                </div>
            </div>
            
            <!-- Back Button -->
            <a href="{{ route('customer.branches.index') }}" class="absolute top-4 left-4 w-10 h-10 bg-white/90 rounded-full flex items-center justify-center shadow-lg hover:bg-white transition">
                <i class="fas fa-arrow-left text-gray-700"></i>
            </a>
        </div>
        
        <!-- Branch Info Card -->
        <div class="px-6 -mt-6 relative z-10">
            <div class="bg-white rounded-2xl shadow-lg p-6 mb-4">
                <div class="flex items-start justify-between mb-4">
                    <div>
                        <p id="branch-code" class="text-xs text-gray-400">-</p>
                        <h1 id="branch-name" class="text-xl font-bold text-gray-800">-</h1>
                    </div>
                    <span id="branch-status" class="px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-700">Buka</span>
                </div>
                
                <div class="space-y-3">
                    <div class="flex items-start">
                        <div class="w-8 text-gray-400">
                            <i class="fas fa-map-marker-alt"></i>
                        </div>
                        <p id="branch-address" class="flex-1 text-gray-700">-</p>
                    </div>
                    
                    <div class="flex items-center">
                        <div class="w-8 text-gray-400">
                            <i class="fas fa-phone-alt"></i>
                        </div>
                        <a id="branch-phone" href="#" class="text-primary-600 font-medium">-</a>
                    </div>
                    
                    <div class="flex items-center">
                        <div class="w-8 text-gray-400">
                            <i class="fas fa-envelope"></i>
                        </div>
                        <a id="branch-email" href="#" class="text-gray-700">-</a>
                    </div>
                </div>
            </div>
            
            <!-- Operating Hours -->
            <div class="bg-white rounded-xl shadow-lg p-6 mb-4">
                <h3 class="font-semibold text-gray-800 mb-4">
                    <i class="fas fa-clock text-primary-600 mr-2"></i>
                    Jam Operasional
                </h3>
                <div id="operating-hours" class="space-y-2">
                    <div class="flex justify-between">
                        <span class="text-gray-600">Senin - Jumat</span>
                        <span class="font-medium">08:00 - 17:00</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-600">Sabtu</span>
                        <span class="font-medium">08:00 - 14:00</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-600">Minggu</span>
                        <span class="font-medium text-red-500">Tutup</span>
                    </div>
                </div>
            </div>
            
            <!-- Services -->
            <div class="bg-white rounded-xl shadow-lg p-6 mb-4">
                <h3 class="font-semibold text-gray-800 mb-4">
                    <i class="fas fa-concierge-bell text-green-600 mr-2"></i>
                    Layanan Tersedia
                </h3>
                <div id="services-list" class="flex flex-wrap gap-2">
                    <span class="px-3 py-1 bg-primary-100 text-primary-700 rounded-full text-sm">Gadai Emas</span>
                    <span class="px-3 py-1 bg-primary-100 text-primary-700 rounded-full text-sm">Gadai Elektronik</span>
                    <span class="px-3 py-1 bg-primary-100 text-primary-700 rounded-full text-sm">Gadai Motor</span>
                    <span class="px-3 py-1 bg-green-100 text-green-700 rounded-full text-sm">Gadai Syariah</span>
                </div>
            </div>
            
            <!-- Action Buttons -->
            <div class="space-y-3">
                <a id="call-button" href="tel:" class="block w-full bg-primary-600 hover:bg-primary-700 text-white text-center font-medium py-3 rounded-lg transition">
                    <i class="fas fa-phone mr-2"></i> Hubungi Cabang
                </a>
                <a id="direction-button" href="#" target="_blank" class="block w-full bg-white border border-gray-300 hover:bg-gray-50 text-gray-700 text-center font-medium py-3 rounded-lg transition">
                    <i class="fas fa-directions mr-2"></i> Petunjuk Arah
                </a>
            </div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
    const branchCode = '{{ $code ?? "" }}' || window.location.pathname.split('/').pop();
    
    async function loadBranch() {
        const response = await api.get(`/branches/${branchCode}`);
        
        if (response.ok && response.data.success) {
            renderBranch(response.data.data);
        } else {
            UI.toast('Gagal memuat data', 'error');
            setTimeout(() => {
                window.location.href = '{{ route('customer.branches.index') }}';
            }, 1500);
        }
    }
    
    function renderBranch(branch) {
        document.getElementById('loading-state').classList.add('hidden');
        document.getElementById('main-content').classList.remove('hidden');
        
        // Basic info
        document.getElementById('branch-code').textContent = branch.code || '';
        document.getElementById('branch-name').textContent = branch.name || '-';
        document.getElementById('branch-address').textContent = branch.address || '-';
        
        // Status
        const isOpen = branch.is_open !== undefined ? branch.is_open : true;
        const statusEl = document.getElementById('branch-status');
        if (isOpen) {
            statusEl.className = 'px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-700';
            statusEl.textContent = 'Buka';
        } else {
            statusEl.className = 'px-3 py-1 rounded-full text-sm font-medium bg-red-100 text-red-700';
            statusEl.textContent = 'Tutup';
        }
        
        // Contact
        const phone = branch.phone || '';
        document.getElementById('branch-phone').textContent = phone || '-';
        document.getElementById('branch-phone').href = phone ? `tel:${phone}` : '#';
        
        const email = branch.email || '';
        document.getElementById('branch-email').textContent = email || '-';
        document.getElementById('branch-email').href = email ? `mailto:${email}` : '#';
        
        // Operating hours
        if (branch.operating_hours) {
            const hoursContainer = document.getElementById('operating-hours');
            hoursContainer.innerHTML = Object.entries(branch.operating_hours).map(([day, hours]) => `
                <div class="flex justify-between">
                    <span class="text-gray-600">${day}</span>
                    <span class="font-medium ${hours === 'Tutup' ? 'text-red-500' : ''}">${hours}</span>
                </div>
            `).join('');
        }
        
        // Services
        if (branch.services && branch.services.length > 0) {
            const servicesContainer = document.getElementById('services-list');
            servicesContainer.innerHTML = branch.services.map(service => `
                <span class="px-3 py-1 ${service.is_sharia ? 'bg-green-100 text-green-700' : 'bg-primary-100 text-primary-700'} rounded-full text-sm">${service.name || service}</span>
            `).join('');
        }
        
        // Action buttons
        document.getElementById('call-button').href = phone ? `tel:${phone}` : '#';
        
        // Google Maps direction
        if (branch.latitude && branch.longitude) {
            document.getElementById('direction-button').href = `https://www.google.com/maps/dir/?api=1&destination=${branch.latitude},${branch.longitude}`;
            
            // Update map preview
            const mapContainer = document.getElementById('branch-map');
            mapContainer.innerHTML = `
                <img src="https://maps.googleapis.com/maps/api/staticmap?center=${branch.latitude},${branch.longitude}&zoom=15&size=600x200&markers=color:red%7C${branch.latitude},${branch.longitude}&key=" 
                     class="w-full h-full object-cover" 
                     onerror="this.onerror=null; this.parentElement.innerHTML='<div class=\'w-full h-full flex items-center justify-center bg-gray-100\'><i class=\'fas fa-map-marked-alt text-4xl text-gray-300\'></i></div>';">
            `;
        } else if (branch.address) {
            document.getElementById('direction-button').href = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(branch.address)}`;
        }
    }
    
    // Init
    document.addEventListener('DOMContentLoaded', loadBranch);
</script>
@endpush
