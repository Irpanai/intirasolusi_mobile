@extends('customer.layouts.app')

@section('title', 'Dashboard')

@section('content')
<div class="min-h-screen pb-24">
    <!-- Header -->
    <div class="bg-gradient-to-br from-primary-600 to-primary-800 text-white pt-6 pb-16 px-6 rounded-b-3xl">
        <!-- Top Bar -->
        <div class="flex items-center justify-between mb-6">
            <div>
                <p class="text-primary-100 text-sm">Selamat datang,</p>
                <h1 class="text-xl font-bold" id="user-name">-</h1>
            </div>
            <div class="flex items-center space-x-3">
                <button onclick="loadDashboard()" class="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center hover:bg-white/30 transition">
                    <i class="fas fa-sync-alt"></i>
                </button>
                <a href="{{ route('customer.profile') }}" class="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center hover:bg-white/30 transition">
                    <i class="fas fa-user"></i>
                </a>
            </div>
        </div>
        
        <!-- Stats Cards -->
        <div class="grid grid-cols-5 gap-3">
            <div class="bg-white/20 backdrop-blur-sm rounded-xl p-4 col-span-3">
                <p class="text-primary-100 text-xs mb-1">Total Pinjaman Aktif</p>
                <p class="text-xl font-bold" id="active-loan">-</p>
            </div>
            <div class="bg-white/20 backdrop-blur-sm rounded-xl p-4 col-span-2">
                <p class="text-primary-100 text-xs mb-1">Transaksi Aktif</p>
                <p class="text-xl font-bold" id="active-count">-</p>
            </div>
        </div>
    </div>
    
    <!-- Main Content -->
    <div class="px-6 -mt-8">
        <!-- Quick Actions -->
        <div class="bg-white rounded-2xl shadow-lg p-4 mb-6">
            <div class="grid grid-cols-4 gap-2">
                <a href="{{ route('customer.pawn-requests.create') }}" class="flex flex-col items-center p-3 hover:bg-gray-50 rounded-xl transition">
                    <div class="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center mb-2">
                        <i class="fas fa-plus text-primary-600"></i>
                    </div>
                    <span class="text-xs text-gray-600 text-center">Pengajuan</span>
                </a>
                <a href="{{ route('customer.calculator') }}" class="flex flex-col items-center p-3 hover:bg-gray-50 rounded-xl transition">
                    <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mb-2">
                        <i class="fas fa-calculator text-green-600"></i>
                    </div>
                    <span class="text-xs text-gray-600 text-center">Kalkulator</span>
                </a>
                <a href="{{ route('customer.transactions.index') }}" class="flex flex-col items-center p-3 hover:bg-gray-50 rounded-xl transition">
                    <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mb-2">
                        <i class="fas fa-receipt text-blue-600"></i>
                    </div>
                    <span class="text-xs text-gray-600 text-center">Transaksi</span>
                </a>
                <a href="{{ route('customer.branches.index') }}" class="flex flex-col items-center p-3 hover:bg-gray-50 rounded-xl transition">
                    <div class="w-12 h-12 bg-orange-100 rounded-full flex items-center justify-center mb-2">
                        <i class="fas fa-map-marker-alt text-orange-600"></i>
                    </div>
                    <span class="text-xs text-gray-600 text-center">Cabang</span>
                </a>
            </div>
        </div>
        
        <!-- Alerts -->
        <div id="alerts-container" class="space-y-3 mb-6"></div>
        
        <!-- Recent Requests -->
        <div class="mb-6">
            <div class="flex items-center justify-between mb-3">
                <h2 class="text-lg font-semibold text-gray-800">Pengajuan Terbaru</h2>
                <a href="{{ route('customer.pawn-requests.index') }}" class="text-primary-600 text-sm hover:text-primary-700">
                    Lihat Semua <i class="fas fa-chevron-right text-xs ml-1"></i>
                </a>
            </div>
            <div id="recent-requests" class="space-y-3">
                <!-- Loading skeleton -->
                <div class="skeleton h-24 rounded-xl"></div>
            </div>
        </div>
        
        <!-- Active Transactions -->
        <div class="mb-6">
            <div class="flex items-center justify-between mb-3">
                <h2 class="text-lg font-semibold text-gray-800">Transaksi Aktif</h2>
                <a href="{{ route('customer.transactions.index') }}" class="text-primary-600 text-sm hover:text-primary-700">
                    Lihat Semua <i class="fas fa-chevron-right text-xs ml-1"></i>
                </a>
            </div>
            <div id="active-transactions" class="space-y-3">
                <!-- Loading skeleton -->
                <div class="skeleton h-24 rounded-xl"></div>
            </div>
        </div>
    </div>
</div>

<!-- Bottom Navigation -->
@include('customer.partials.bottom-nav', ['active' => 'home'])
@endsection

@push('scripts')
<script>
    async function loadDashboard() {
        const response = await api.get('/dashboard');
        
        if (response.ok && response.data.success) {
            const data = response.data.data;
            
            // Update header
            document.getElementById('user-name').textContent = data.customer.name;
            document.getElementById('active-loan').textContent = data.stats.transactions.total_active_loan_formatted || 'Rp 0';
            document.getElementById('active-count').textContent = data.stats.transactions.active || 0;
            
            // Render alerts
            renderAlerts(data.alerts || []);
            
            // Render recent requests
            renderRecentRequests(data.recent_requests || []);
            
            // Render active transactions
            renderActiveTransactions(data.active_transactions || []);
            
            // Check profile completion
            if (!data.customer.is_profile_complete) {
                renderProfileAlert();
            }
        } else {
            UI.toast('Gagal memuat data', 'error');
        }
    }
    
    function renderProfileAlert() {
        const container = document.getElementById('alerts-container');
        container.innerHTML = `
            <div class="bg-yellow-50 border border-yellow-200 rounded-xl p-4 flex items-start space-x-3">
                <div class="flex-shrink-0 w-10 h-10 bg-yellow-100 rounded-full flex items-center justify-center">
                    <i class="fas fa-exclamation-triangle text-yellow-600"></i>
                </div>
                <div class="flex-1">
                    <h3 class="font-semibold text-yellow-800">Profil Belum Lengkap</h3>
                    <p class="text-sm text-yellow-600 mb-2">Lengkapi profil untuk mulai mengajukan gadai online.</p>
                    <a href="{{ route('customer.profile.edit') }}" class="inline-flex items-center text-sm font-semibold text-yellow-700 hover:text-yellow-800">
                        Lengkapi Sekarang <i class="fas fa-arrow-right ml-1"></i>
                    </a>
                </div>
            </div>
        ` + container.innerHTML;
    }
    
    function renderAlerts(alerts) {
        const container = document.getElementById('alerts-container');
        
        if (alerts.length === 0) {
            return;
        }
        
        const alertColors = {
            warning: { bg: 'bg-yellow-50', border: 'border-yellow-200', icon: 'bg-yellow-100', iconText: 'text-yellow-600', title: 'text-yellow-800', text: 'text-yellow-600' },
            danger: { bg: 'bg-red-50', border: 'border-red-200', icon: 'bg-red-100', iconText: 'text-red-600', title: 'text-red-800', text: 'text-red-600' },
            info: { bg: 'bg-blue-50', border: 'border-blue-200', icon: 'bg-blue-100', iconText: 'text-blue-600', title: 'text-blue-800', text: 'text-blue-600' },
            success: { bg: 'bg-green-50', border: 'border-green-200', icon: 'bg-green-100', iconText: 'text-green-600', title: 'text-green-800', text: 'text-green-600' }
        };
        
        const alertIcons = {
            warning: 'fa-exclamation-triangle',
            danger: 'fa-times-circle',
            info: 'fa-info-circle',
            success: 'fa-check-circle'
        };
        
        container.innerHTML += alerts.map(alert => {
            const colors = alertColors[alert.type] || alertColors.info;
            const icon = alertIcons[alert.type] || alertIcons.info;
            
            return `
                <div class="${colors.bg} border ${colors.border} rounded-xl p-4 flex items-start space-x-3">
                    <div class="flex-shrink-0 w-10 h-10 ${colors.icon} rounded-full flex items-center justify-center">
                        <i class="fas ${icon} ${colors.iconText}"></i>
                    </div>
                    <div class="flex-1">
                        <h3 class="font-semibold ${colors.title}">${alert.title}</h3>
                        <p class="text-sm ${colors.text}">${alert.message}</p>
                    </div>
                </div>
            `;
        }).join('');
    }
    
    function renderRecentRequests(requests) {
        const container = document.getElementById('recent-requests');
        
        if (requests.length === 0) {
            container.innerHTML = `
                <div class="bg-gray-50 rounded-xl p-6 text-center">
                    <i class="fas fa-inbox text-3xl text-gray-300 mb-2"></i>
                    <p class="text-gray-500 text-sm">Belum ada pengajuan</p>
                    <a href="{{ route('customer.pawn-requests.create') }}" class="inline-block mt-3 text-primary-600 text-sm font-semibold">
                        Ajukan Gadai Sekarang
                    </a>
                </div>
            `;
            return;
        }
        
        container.innerHTML = requests.map(req => `
            <a href="/customer/pawn-requests/${req.request_code}" class="block bg-white border border-gray-200 rounded-xl p-4 hover:shadow-md transition">
                <div class="flex items-start justify-between">
                    <div class="flex-1">
                        <p class="text-xs text-gray-400 mb-1">${req.request_code}</p>
                        <h3 class="font-medium text-gray-800">${req.collateral_name}</h3>
                        <p class="text-primary-600 font-semibold">${req.requested_amount_formatted}</p>
                    </div>
                    <span class="px-2 py-1 rounded-full text-xs font-medium ${getStatusClass(req.status)}">
                        ${req.status_label}
                    </span>
                </div>
                <p class="text-xs text-gray-400 mt-2">
                    <i class="fas fa-calendar mr-1"></i> ${req.created_at_formatted}
                </p>
            </a>
        `).join('');
    }
    
    function renderActiveTransactions(transactions) {
        const container = document.getElementById('active-transactions');
        
        if (transactions.length === 0) {
            container.innerHTML = `
                <div class="bg-gray-50 rounded-xl p-6 text-center">
                    <i class="fas fa-receipt text-3xl text-gray-300 mb-2"></i>
                    <p class="text-gray-500 text-sm">Belum ada transaksi aktif</p>
                </div>
            `;
            return;
        }
        
        container.innerHTML = transactions.map(trx => `
            <a href="/customer/transactions/${trx.transaction_code}" class="block bg-white border border-gray-200 rounded-xl p-4 hover:shadow-md transition">
                <div class="flex items-start justify-between">
                    <div class="flex-1">
                        <p class="text-xs text-gray-400 mb-1">${trx.transaction_code}</p>
                        <h3 class="font-medium text-gray-800">${trx.collateral_name}</h3>
                        <p class="text-primary-600 font-semibold">${trx.loan_amount_formatted}</p>
                    </div>
                    <div class="text-right">
                        <span class="px-2 py-1 rounded-full text-xs font-medium ${trx.is_overdue ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}">
                            ${trx.is_overdue ? 'Jatuh Tempo' : 'Aktif'}
                        </span>
                    </div>
                </div>
                <div class="flex items-center justify-between mt-3 pt-3 border-t border-gray-100">
                    <p class="text-xs text-gray-500">
                        <i class="fas fa-calendar-alt mr-1"></i> Jatuh tempo: ${trx.due_date_formatted}
                    </p>
                    <span class="text-xs ${trx.days_until_due < 0 ? 'text-red-600' : trx.days_until_due <= 7 ? 'text-yellow-600' : 'text-gray-500'}">
                        ${trx.days_until_due < 0 ? Math.abs(trx.days_until_due) + ' hari lewat' : trx.days_until_due + ' hari lagi'}
                    </span>
                </div>
            </a>
        `).join('');
    }
    
    function getStatusClass(status) {
        const classes = {
            'PENDING': 'bg-yellow-100 text-yellow-700',
            'REVIEWING': 'bg-blue-100 text-blue-700',
            'DOCUMENT_REQUIRED': 'bg-orange-100 text-orange-700',
            'APPROVED': 'bg-green-100 text-green-700',
            'REJECTED': 'bg-red-100 text-red-700',
            'CANCELLED': 'bg-gray-100 text-gray-700',
            'CONVERTED': 'bg-primary-100 text-primary-700'
        };
        return classes[status] || 'bg-gray-100 text-gray-700';
    }
    
    // Load dashboard on page load
    document.addEventListener('DOMContentLoaded', loadDashboard);
</script>
@endpush
