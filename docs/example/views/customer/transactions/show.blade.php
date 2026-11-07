@extends('customer.layouts.app')

@section('title', 'Detail Transaksi')

@section('content')
<div class="min-h-screen pb-6" id="page-content">
    <!-- Loading State -->
    <div id="loading-state">
        <div class="bg-gradient-to-br from-primary-600 to-primary-800 pt-6 pb-12 px-6">
            <div class="skeleton h-6 w-32 rounded bg-white/20 mb-4"></div>
            <div class="skeleton h-8 w-48 rounded bg-white/20"></div>
        </div>
        <div class="px-6 -mt-4">
            <div class="skeleton h-40 rounded-xl mb-4"></div>
            <div class="skeleton h-48 rounded-xl mb-4"></div>
            <div class="skeleton h-32 rounded-xl"></div>
        </div>
    </div>
    
    <!-- Content -->
    <div id="main-content" class="hidden">
        <!-- Header -->
        <div class="bg-gradient-to-br from-primary-600 to-primary-800 text-white pt-6 pb-12 px-6">
            <a href="{{ route('customer.transactions.index') }}" class="inline-flex items-center text-white/80 hover:text-white mb-4">
                <i class="fas fa-arrow-left mr-2"></i>
                <span>Kembali</span>
            </a>
            <p class="text-primary-100 text-sm" id="transaction-code">-</p>
            <h1 class="text-xl font-bold" id="transaction-title">-</h1>
        </div>
        
        <!-- Status Card -->
        <div class="px-6 -mt-4">
            <div id="status-card" class="bg-white rounded-2xl shadow-lg p-6 mb-4">
                <div class="flex items-center justify-between mb-4">
                    <span class="text-sm text-gray-500">Status</span>
                    <span id="status-badge" class="px-3 py-1 rounded-full text-sm font-medium">-</span>
                </div>
                
                <!-- Due Date Alert -->
                <div id="due-alert" class="hidden p-4 rounded-lg mb-4">
                </div>
                
                <!-- Key Info -->
                <div class="grid grid-cols-2 gap-4">
                    <div class="bg-gray-50 rounded-lg p-3 text-center">
                        <p class="text-xs text-gray-500 mb-1">Pinjaman</p>
                        <p id="loan-amount" class="text-lg font-bold text-primary-600">-</p>
                    </div>
                    <div class="bg-gray-50 rounded-lg p-3 text-center">
                        <p class="text-xs text-gray-500 mb-1">Jatuh Tempo</p>
                        <p id="due-date" class="text-lg font-bold text-gray-800">-</p>
                    </div>
                </div>
            </div>
            
            <!-- Collateral Info -->
            <div class="bg-white rounded-xl shadow-lg p-6 mb-4">
                <h3 class="font-semibold text-gray-800 mb-4">
                    <i class="fas fa-gem text-primary-600 mr-2"></i>
                    Barang Jaminan
                </h3>
                <div class="space-y-3">
                    <div class="flex justify-between">
                        <span class="text-gray-500">Nama Barang</span>
                        <span id="collateral-name" class="font-medium text-right">-</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-500">Deskripsi</span>
                        <span id="collateral-desc" class="text-right text-gray-700 max-w-[60%]">-</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-500">Nilai Taksir</span>
                        <span id="appraisal-value" class="font-medium text-right">-</span>
                    </div>
                </div>
            </div>
            
            <!-- Loan Details -->
            <div class="bg-white rounded-xl shadow-lg p-6 mb-4">
                <h3 class="font-semibold text-gray-800 mb-4">
                    <i class="fas fa-file-invoice-dollar text-green-600 mr-2"></i>
                    Detail Pinjaman
                </h3>
                <div class="space-y-3">
                    <div class="flex justify-between">
                        <span class="text-gray-500">Produk</span>
                        <span id="product-name" class="font-medium text-right">-</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-500">Cabang</span>
                        <span id="branch-name" class="font-medium text-right">-</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-500">Tanggal Gadai</span>
                        <span id="start-date" class="text-right">-</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-500">Jatuh Tempo</span>
                        <span id="due-date-detail" class="text-right">-</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-500">Jumlah Perpanjangan</span>
                        <span id="extension-count" class="text-right">-</span>
                    </div>
                    <hr class="my-2">
                    <div class="flex justify-between">
                        <span class="text-gray-500">Pokok Pinjaman</span>
                        <span id="principal-amount" class="font-medium">-</span>
                    </div>
                    <div id="interest-row" class="flex justify-between">
                        <span class="text-gray-500">Jasa/Bunga</span>
                        <span id="interest-amount" class="font-medium">-</span>
                    </div>
                    <div id="fine-row" class="flex justify-between hidden">
                        <span class="text-gray-500">Denda Keterlambatan</span>
                        <span id="fine-amount" class="font-medium text-red-500">-</span>
                    </div>
                    <hr class="my-2">
                    <div class="flex justify-between">
                        <span class="font-semibold text-gray-800">Total Pelunasan</span>
                        <span id="total-amount" class="font-bold text-lg text-primary-600">-</span>
                    </div>
                </div>
            </div>
            
            <!-- Payment Info for Sharia -->
            <div id="sharia-payment-info" class="bg-blue-50 rounded-xl p-4 mb-4 hidden">
                <div class="flex items-start">
                    <i class="fas fa-mosque text-blue-600 mt-1 mr-3"></i>
                    <div>
                        <p class="font-medium text-blue-800">Transaksi Syariah</p>
                        <p class="text-sm text-blue-700 mt-1">Transaksi ini menggunakan akad gadai syariah dengan sistem bagi hasil.</p>
                    </div>
                </div>
            </div>
            
            <!-- Payment History -->
            <div class="bg-white rounded-xl shadow-lg p-6 mb-4">
                <h3 class="font-semibold text-gray-800 mb-4">
                    <i class="fas fa-history text-gray-600 mr-2"></i>
                    Riwayat Pembayaran
                </h3>
                <div id="payment-history" class="space-y-3">
                    <p class="text-gray-400 text-sm text-center">Belum ada pembayaran</p>
                </div>
            </div>
            
            <!-- Action Buttons -->
            <div id="action-buttons" class="space-y-3">
            </div>
        </div>
    </div>
</div>

<!-- Bottom Navigation -->
@include('customer.partials.bottom-nav', ['active' => 'transactions'])
@endsection

@push('scripts')
<script>
    const transactionCode = '{{ $code ?? "" }}' || window.location.pathname.split('/').pop();
    
    async function loadTransaction() {
        const response = await api.get(`/transactions/${transactionCode}`);
        
        if (response.ok && response.data.success) {
            renderTransaction(response.data.data);
        } else {
            UI.toast('Gagal memuat data', 'error');
            setTimeout(() => {
                window.location.href = '{{ route('customer.transactions.index') }}';
            }, 1500);
        }
    }
    
    function renderTransaction(trx) {
        document.getElementById('loading-state').classList.add('hidden');
        document.getElementById('main-content').classList.remove('hidden');
        
        // Header
        document.getElementById('transaction-code').textContent = trx.transaction_code;
        document.getElementById('transaction-title').textContent = trx.collateral_name || trx.collateral?.name || '-';
        
        // Status
        const statusBadge = document.getElementById('status-badge');
        const statusClasses = {
            'ACTIVE': 'bg-green-100 text-green-700',
            'EXTENDED': 'bg-blue-100 text-blue-700',
            'OVERDUE': 'bg-red-100 text-red-700',
            'AUCTION_PENDING': 'bg-orange-100 text-orange-700',
            'AUCTIONED': 'bg-gray-100 text-gray-700',
            'COMPLETED': 'bg-primary-100 text-primary-700'
        };
        statusBadge.className = `px-3 py-1 rounded-full text-sm font-medium ${statusClasses[trx.status] || 'bg-gray-100 text-gray-700'}`;
        statusBadge.textContent = trx.status_label || trx.status;
        
        // Due date alert
        const dueAlert = document.getElementById('due-alert');
        const isOverdue = trx.is_overdue || trx.status === 'OVERDUE';
        const daysLeft = trx.days_until_due;
        
        if (trx.status === 'ACTIVE' || trx.status === 'EXTENDED') {
            if (isOverdue) {
                dueAlert.classList.remove('hidden');
                dueAlert.className = 'p-4 rounded-lg mb-4 bg-red-50';
                dueAlert.innerHTML = `
                    <p class="font-medium text-red-800"><i class="fas fa-exclamation-circle mr-2"></i>Terlambat ${Math.abs(daysLeft)} hari</p>
                    <p class="text-sm text-red-700 mt-1">Segera lakukan perpanjangan atau pelunasan untuk menghindari pelelangan.</p>
                `;
            } else if (daysLeft !== null && daysLeft <= 7) {
                dueAlert.classList.remove('hidden');
                dueAlert.className = 'p-4 rounded-lg mb-4 bg-yellow-50';
                dueAlert.innerHTML = `
                    <p class="font-medium text-yellow-800"><i class="fas fa-clock mr-2"></i>Jatuh tempo ${daysLeft} hari lagi</p>
                    <p class="text-sm text-yellow-700 mt-1">Pastikan melakukan perpanjangan atau pelunasan sebelum jatuh tempo.</p>
                `;
            }
        } else if (trx.status === 'COMPLETED') {
            dueAlert.classList.remove('hidden');
            dueAlert.className = 'p-4 rounded-lg mb-4 bg-green-50';
            dueAlert.innerHTML = `
                <p class="font-medium text-green-800"><i class="fas fa-check-circle mr-2"></i>Transaksi Selesai</p>
                <p class="text-sm text-green-700 mt-1">Barang jaminan sudah dapat diambil di cabang.</p>
            `;
        }
        
        // Key info
        document.getElementById('loan-amount').textContent = trx.loan_amount_formatted || UI.formatCurrency(trx.loan_amount);
        document.getElementById('due-date').textContent = trx.due_date_formatted || UI.formatDate(trx.due_date, 'short');
        
        // Collateral
        document.getElementById('collateral-name').textContent = trx.collateral_name || trx.collateral?.name || '-';
        document.getElementById('collateral-desc').textContent = trx.collateral_description || trx.collateral?.description || '-';
        document.getElementById('appraisal-value').textContent = trx.appraisal_value_formatted || UI.formatCurrency(trx.appraisal_value);
        
        // Loan details
        document.getElementById('product-name').textContent = trx.loan_product?.name || trx.product_name || '-';
        document.getElementById('branch-name').textContent = trx.branch?.name || trx.branch_name || '-';
        document.getElementById('start-date').textContent = trx.start_date_formatted || UI.formatDate(trx.start_date);
        document.getElementById('due-date-detail').textContent = trx.due_date_formatted || UI.formatDate(trx.due_date);
        document.getElementById('extension-count').textContent = (trx.extension_count || 0) + ' kali';
        document.getElementById('principal-amount').textContent = trx.loan_amount_formatted || UI.formatCurrency(trx.loan_amount);
        document.getElementById('interest-amount').textContent = trx.interest_formatted || UI.formatCurrency(trx.interest_amount || 0);
        
        if (trx.fine_amount && trx.fine_amount > 0) {
            document.getElementById('fine-row').classList.remove('hidden');
            document.getElementById('fine-amount').textContent = trx.fine_formatted || UI.formatCurrency(trx.fine_amount);
        }
        
        document.getElementById('total-amount').textContent = trx.total_repayment_formatted || UI.formatCurrency(trx.total_repayment || (trx.loan_amount + (trx.interest_amount || 0) + (trx.fine_amount || 0)));
        
        // Sharia info
        if (trx.is_sharia || trx.loan_product?.is_sharia) {
            document.getElementById('sharia-payment-info').classList.remove('hidden');
        }
        
        // Payment history
        const historyContainer = document.getElementById('payment-history');
        if (trx.payments && trx.payments.length > 0) {
            historyContainer.innerHTML = trx.payments.map(payment => `
                <div class="flex items-start justify-between p-3 bg-gray-50 rounded-lg">
                    <div>
                        <p class="font-medium text-gray-800">${payment.type_label || payment.payment_type}</p>
                        <p class="text-xs text-gray-500">${payment.created_at_formatted || UI.formatDate(payment.created_at)}</p>
                    </div>
                    <div class="text-right">
                        <p class="font-semibold text-green-600">${payment.amount_formatted || UI.formatCurrency(payment.amount)}</p>
                        <span class="text-xs ${payment.status === 'VERIFIED' ? 'text-green-500' : 'text-yellow-500'}">${payment.status_label || payment.status}</span>
                    </div>
                </div>
            `).join('');
        } else {
            historyContainer.innerHTML = '<p class="text-gray-400 text-sm text-center py-4">Belum ada pembayaran</p>';
        }
        
        // Action buttons
        const actionButtons = document.getElementById('action-buttons');
        if (trx.status === 'ACTIVE' || trx.status === 'EXTENDED' || trx.status === 'OVERDUE') {
            const branchPhone = trx.branch?.phone || '';
            actionButtons.innerHTML = `
                <a href="tel:${branchPhone}" class="block w-full bg-primary-600 hover:bg-primary-700 text-white text-center font-medium py-3 rounded-lg transition">
                    <i class="fas fa-phone mr-2"></i> Hubungi Cabang untuk Pelunasan
                </a>
                <a href="/customer/branches/${trx.branch?.code || trx.branch?.id || ''}" class="block w-full bg-gray-100 hover:bg-gray-200 text-gray-700 text-center font-medium py-3 rounded-lg transition">
                    <i class="fas fa-map-marker-alt mr-2"></i> Lihat Lokasi Cabang
                </a>
            `;
        } else if (trx.status === 'COMPLETED') {
            actionButtons.innerHTML = `
                <a href="#" onclick="downloadReceipt()" class="block w-full bg-primary-600 hover:bg-primary-700 text-white text-center font-medium py-3 rounded-lg transition">
                    <i class="fas fa-download mr-2"></i> Download Bukti Pelunasan
                </a>
            `;
        }
    }
    
    async function downloadReceipt() {
        UI.toast('Fitur download dalam pengembangan', 'info');
    }
    
    // Init
    document.addEventListener('DOMContentLoaded', loadTransaction);
</script>
@endpush
