@extends('customer.layouts.app')

@section('title', 'Pengajuan Saya')

@section('content')
<div class="min-h-screen pb-24">
    <!-- Header -->
    <div class="bg-gradient-to-br from-primary-600 to-primary-800 text-white pt-6 pb-12 px-6">
        <div class="flex items-center justify-between mb-4">
            <h1 class="text-xl font-bold">Pengajuan Saya</h1>
            <a href="{{ route('customer.pawn-requests.create') }}" class="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center hover:bg-white/30 transition">
                <i class="fas fa-plus"></i>
            </a>
        </div>
        
        <!-- Filter Tabs -->
        <div class="flex space-x-2 overflow-x-auto no-scrollbar">
            <button onclick="filterByStatus('')" class="filter-tab px-4 py-2 rounded-full text-sm font-medium bg-white text-primary-600 whitespace-nowrap" data-status="">
                Semua
            </button>
            <button onclick="filterByStatus('PENDING')" class="filter-tab px-4 py-2 rounded-full text-sm font-medium bg-white/20 text-white whitespace-nowrap" data-status="PENDING">
                Menunggu
            </button>
            <button onclick="filterByStatus('REVIEWING')" class="filter-tab px-4 py-2 rounded-full text-sm font-medium bg-white/20 text-white whitespace-nowrap" data-status="REVIEWING">
                Direview
            </button>
            <button onclick="filterByStatus('APPROVED')" class="filter-tab px-4 py-2 rounded-full text-sm font-medium bg-white/20 text-white whitespace-nowrap" data-status="APPROVED">
                Disetujui
            </button>
            <button onclick="filterByStatus('REJECTED')" class="filter-tab px-4 py-2 rounded-full text-sm font-medium bg-white/20 text-white whitespace-nowrap" data-status="REJECTED">
                Ditolak
            </button>
        </div>
    </div>
    
    <!-- Content -->
    <div class="px-6 -mt-4">
        <div id="requests-container" class="space-y-3">
            <!-- Loading skeleton -->
            <div class="skeleton h-28 rounded-xl"></div>
            <div class="skeleton h-28 rounded-xl"></div>
        </div>
        
        <!-- Empty State -->
        <div id="empty-state" class="hidden bg-white rounded-xl p-8 text-center shadow-lg">
            <div class="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <i class="fas fa-inbox text-3xl text-gray-300"></i>
            </div>
            <h3 class="font-semibold text-gray-800 mb-2">Belum Ada Pengajuan</h3>
            <p class="text-gray-500 text-sm mb-4">Mulai ajukan gadai untuk mendapatkan pinjaman.</p>
            <a href="{{ route('customer.pawn-requests.create') }}" class="inline-flex items-center px-4 py-2 bg-primary-600 text-white rounded-lg font-medium hover:bg-primary-700 transition">
                <i class="fas fa-plus mr-2"></i>
                Ajukan Gadai
            </a>
        </div>
    </div>
</div>

<!-- Bottom Navigation -->
@include('customer.partials.bottom-nav', ['active' => 'requests'])
@endsection

@push('scripts')
<script>
    let currentStatus = '';
    
    function filterByStatus(status) {
        currentStatus = status;
        
        // Update tab UI
        document.querySelectorAll('.filter-tab').forEach(tab => {
            if (tab.dataset.status === status) {
                tab.classList.remove('bg-white/20', 'text-white');
                tab.classList.add('bg-white', 'text-primary-600');
            } else {
                tab.classList.remove('bg-white', 'text-primary-600');
                tab.classList.add('bg-white/20', 'text-white');
            }
        });
        
        loadRequests();
    }
    
    async function loadRequests() {
        const container = document.getElementById('requests-container');
        const emptyState = document.getElementById('empty-state');
        
        container.innerHTML = `
            <div class="skeleton h-28 rounded-xl"></div>
            <div class="skeleton h-28 rounded-xl"></div>
        `;
        emptyState.classList.add('hidden');
        
        let endpoint = '/pawn-requests';
        if (currentStatus) {
            endpoint += `?status=${currentStatus}`;
        }
        
        const response = await api.get(endpoint);
        
        if (response.ok && response.data.success) {
            const requests = response.data.data.data || response.data.data;
            
            if (requests.length === 0) {
                container.innerHTML = '';
                emptyState.classList.remove('hidden');
            } else {
                container.innerHTML = requests.map(req => renderRequestCard(req)).join('');
            }
        } else {
            UI.toast('Gagal memuat data', 'error');
        }
    }
    
    function renderRequestCard(req) {
        const statusClasses = {
            'PENDING': 'bg-yellow-100 text-yellow-700',
            'REVIEWING': 'bg-blue-100 text-blue-700',
            'DOCUMENT_REQUIRED': 'bg-orange-100 text-orange-700',
            'APPROVED': 'bg-green-100 text-green-700',
            'REJECTED': 'bg-red-100 text-red-700',
            'CANCELLED': 'bg-gray-100 text-gray-700',
            'CONVERTED': 'bg-primary-100 text-primary-700'
        };
        
        return `
            <a href="/customer/pawn-requests/${req.request_code}" class="block bg-white rounded-xl shadow-lg p-4 hover:shadow-xl transition">
                <div class="flex items-start justify-between mb-3">
                    <div>
                        <p class="text-xs text-gray-400">${req.request_code}</p>
                        <h3 class="font-medium text-gray-800">${req.collateral_name}</h3>
                    </div>
                    <span class="px-2 py-1 rounded-full text-xs font-medium ${statusClasses[req.status] || 'bg-gray-100 text-gray-700'}">
                        ${req.status_label}
                    </span>
                </div>
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm text-gray-500">${req.loan_product?.name || '-'}</p>
                        <p class="text-primary-600 font-semibold">${req.requested_loan_amount_formatted}</p>
                    </div>
                    <div class="text-right">
                        <p class="text-xs text-gray-400">${req.created_at_formatted || UI.formatDate(req.created_at)}</p>
                        <i class="fas fa-chevron-right text-gray-400"></i>
                    </div>
                </div>
            </a>
        `;
    }
    
    // Load on page load
    document.addEventListener('DOMContentLoaded', loadRequests);
</script>
@endpush
