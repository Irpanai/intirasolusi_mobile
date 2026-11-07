@extends('customer.layouts.app')

@section('title', 'Transaksi Saya')

@section('content')
<div class="min-h-screen pb-24">
    <!-- Header -->
    <div class="bg-gradient-to-br from-primary-600 to-primary-800 text-white pt-6 pb-12 px-6">
        <h1 class="text-xl font-bold mb-4">Transaksi Saya</h1>
        
        <!-- Filter Tabs -->
        <div class="flex space-x-2 overflow-x-auto no-scrollbar">
            <button onclick="filterByStatus('')" class="filter-tab px-4 py-2 rounded-full text-sm font-medium bg-white text-primary-600 whitespace-nowrap" data-status="">
                Semua
            </button>
            <button onclick="filterByStatus('ACTIVE')" class="filter-tab px-4 py-2 rounded-full text-sm font-medium bg-white/20 text-white whitespace-nowrap" data-status="ACTIVE">
                Aktif
            </button>
            <button onclick="filterByStatus('COMPLETED')" class="filter-tab px-4 py-2 rounded-full text-sm font-medium bg-white/20 text-white whitespace-nowrap" data-status="COMPLETED">
                Lunas
            </button>
            <button onclick="filterByStatus('OVERDUE')" class="filter-tab px-4 py-2 rounded-full text-sm font-medium bg-white/20 text-white whitespace-nowrap" data-status="OVERDUE">
                Terlambat
            </button>
        </div>
    </div>
    
    <!-- Content -->
    <div class="px-6 -mt-4">
        <!-- Summary Cards -->
        <div class="grid grid-cols-2 gap-3 mb-4">
            <div class="bg-white rounded-xl shadow-lg p-4">
                <p class="text-xs text-gray-500 mb-1">Total Aktif</p>
                <p id="active-count" class="text-2xl font-bold text-primary-600">-</p>
            </div>
            <div class="bg-white rounded-xl shadow-lg p-4">
                <p class="text-xs text-gray-500 mb-1">Total Pinjaman Aktif</p>
                <p id="active-amount" class="text-lg font-bold text-gray-800">-</p>
            </div>
        </div>
        
        <div id="transactions-container" class="space-y-3">
            <!-- Loading skeleton -->
            <div class="skeleton h-32 rounded-xl"></div>
            <div class="skeleton h-32 rounded-xl"></div>
        </div>
        
        <!-- Empty State -->
        <div id="empty-state" class="hidden bg-white rounded-xl p-8 text-center shadow-lg">
            <div class="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <i class="fas fa-receipt text-3xl text-gray-300"></i>
            </div>
            <h3 class="font-semibold text-gray-800 mb-2">Belum Ada Transaksi</h3>
            <p class="text-gray-500 text-sm mb-4">Transaksi gadai Anda akan muncul di sini.</p>
            <a href="{{ route('customer.pawn-requests.create') }}" class="inline-flex items-center px-4 py-2 bg-primary-600 text-white rounded-lg font-medium hover:bg-primary-700 transition">
                <i class="fas fa-plus mr-2"></i>
                Ajukan Gadai
            </a>
        </div>
    </div>
</div>

<!-- Bottom Navigation -->
@include('customer.partials.bottom-nav', ['active' => 'transactions'])
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
        
        loadTransactions();
    }
    
    async function loadTransactions() {
        const container = document.getElementById('transactions-container');
        const emptyState = document.getElementById('empty-state');
        
        container.innerHTML = `
            <div class="skeleton h-32 rounded-xl"></div>
            <div class="skeleton h-32 rounded-xl"></div>
        `;
        emptyState.classList.add('hidden');
        
        let endpoint = '/transactions';
        if (currentStatus) {
            endpoint += `?status=${currentStatus}`;
        }
        
        const response = await api.get(endpoint);
        
        if (response.ok && response.data.success) {
            const data = response.data.data;
            const transactions = data.data || data;
            
            // Update summary
            if (data.summary) {
                document.getElementById('active-count').textContent = data.summary.active_count || 0;
                document.getElementById('active-amount').textContent = UI.formatCurrency(data.summary.active_amount || 0);
            }
            
            if (transactions.length === 0) {
                container.innerHTML = '';
                emptyState.classList.remove('hidden');
            } else {
                container.innerHTML = transactions.map(trx => renderTransactionCard(trx)).join('');
            }
        } else {
            UI.toast('Gagal memuat data', 'error');
        }
    }
    
    function renderTransactionCard(trx) {
        const statusClasses = {
            'ACTIVE': 'bg-green-100 text-green-700',
            'EXTENDED': 'bg-blue-100 text-blue-700',
            'OVERDUE': 'bg-red-100 text-red-700',
            'AUCTION_PENDING': 'bg-orange-100 text-orange-700',
            'AUCTIONED': 'bg-gray-100 text-gray-700',
            'COMPLETED': 'bg-primary-100 text-primary-700'
        };
        
        const isOverdue = trx.is_overdue || trx.status === 'OVERDUE';
        const daysLeft = trx.days_until_due;
        
        let dueBadge = '';
        if (trx.status === 'ACTIVE' || trx.status === 'EXTENDED') {
            if (isOverdue) {
                dueBadge = `<span class="text-xs text-red-500 font-medium"><i class="fas fa-exclamation-circle mr-1"></i>Terlambat ${Math.abs(daysLeft)} hari</span>`;
            } else if (daysLeft !== null && daysLeft <= 7) {
                dueBadge = `<span class="text-xs text-orange-500 font-medium"><i class="fas fa-clock mr-1"></i>Sisa ${daysLeft} hari</span>`;
            }
        }
        
        return `
            <a href="/customer/transactions/${trx.transaction_code}" class="block bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition">
                <div class="p-4">
                    <div class="flex items-start justify-between mb-3">
                        <div>
                            <p class="text-xs text-gray-400">${trx.transaction_code}</p>
                            <h3 class="font-medium text-gray-800">${trx.collateral_name || trx.collateral?.name || '-'}</h3>
                        </div>
                        <span class="px-2 py-1 rounded-full text-xs font-medium ${statusClasses[trx.status] || 'bg-gray-100 text-gray-700'}">
                            ${trx.status_label || trx.status}
                        </span>
                    </div>
                    
                    <div class="grid grid-cols-2 gap-3 mb-3">
                        <div>
                            <p class="text-xs text-gray-400">Pinjaman</p>
                            <p class="font-semibold text-primary-600">${trx.loan_amount_formatted || UI.formatCurrency(trx.loan_amount)}</p>
                        </div>
                        <div class="text-right">
                            <p class="text-xs text-gray-400">Jatuh Tempo</p>
                            <p class="font-medium">${trx.due_date_formatted || UI.formatDate(trx.due_date, 'short')}</p>
                        </div>
                    </div>
                    
                    <div class="flex items-center justify-between">
                        ${dueBadge}
                        <span class="text-gray-400 text-sm">
                            Detail <i class="fas fa-chevron-right ml-1"></i>
                        </span>
                    </div>
                </div>
                
                ${isOverdue ? '<div class="bg-red-500 text-white text-center text-xs py-1">Segera lakukan perpanjangan atau pelunasan</div>' : ''}
            </a>
        `;
    }
    
    // Load on page load
    document.addEventListener('DOMContentLoaded', loadTransactions);
</script>
@endpush
