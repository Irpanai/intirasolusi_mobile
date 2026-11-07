@extends('customer.layouts.app')

@section('title', 'Detail Pengajuan')

@section('content')
<div class="min-h-screen pb-24" id="page-content">
    <!-- Loading State -->
    <div id="loading-state">
        <div class="bg-gradient-to-br from-primary-600 to-primary-800 pt-6 pb-12 px-6">
            <div class="skeleton h-6 w-32 rounded bg-white/20 mb-4"></div>
            <div class="skeleton h-8 w-48 rounded bg-white/20"></div>
        </div>
        <div class="px-6 -mt-4">
            <div class="skeleton h-64 rounded-xl mb-4"></div>
            <div class="skeleton h-40 rounded-xl"></div>
        </div>
    </div>
    
    <!-- Content (hidden by default) -->
    <div id="main-content" class="hidden">
        <!-- Header -->
        <div class="bg-gradient-to-br from-primary-600 to-primary-800 text-white pt-6 pb-12 px-6">
            <a href="{{ route('customer.pawn-requests.index') }}" class="inline-flex items-center text-white/80 hover:text-white mb-4">
                <i class="fas fa-arrow-left mr-2"></i>
                <span>Kembali</span>
            </a>
            <p class="text-primary-100 text-sm" id="request-code">-</p>
            <h1 class="text-xl font-bold" id="request-title">-</h1>
        </div>
        
        <!-- Status Card -->
        <div class="px-6 -mt-4">
            <div class="bg-white rounded-2xl shadow-lg p-6 mb-4">
                <div class="flex items-center justify-between mb-4">
                    <span class="text-sm text-gray-500">Status</span>
                    <span id="status-badge" class="px-3 py-1 rounded-full text-sm font-medium">-</span>
                </div>
                
                <!-- Progress Tracker -->
                <div id="progress-tracker" class="hidden">
                    <div class="flex items-center justify-between relative">
                        <div class="absolute top-3 left-0 right-0 h-0.5 bg-gray-200"></div>
                        <div id="progress-bar" class="absolute top-3 left-0 h-0.5 bg-primary-500 transition-all"></div>
                        
                        <div class="progress-step relative z-10 flex flex-col items-center" data-step="1">
                            <div class="w-6 h-6 rounded-full bg-primary-500 text-white flex items-center justify-center text-xs">
                                <i class="fas fa-check"></i>
                            </div>
                            <span class="text-xs text-gray-500 mt-1">Dikirim</span>
                        </div>
                        <div class="progress-step relative z-10 flex flex-col items-center" data-step="2">
                            <div class="w-6 h-6 rounded-full bg-gray-200 text-gray-400 flex items-center justify-center text-xs">2</div>
                            <span class="text-xs text-gray-500 mt-1">Review</span>
                        </div>
                        <div class="progress-step relative z-10 flex flex-col items-center" data-step="3">
                            <div class="w-6 h-6 rounded-full bg-gray-200 text-gray-400 flex items-center justify-center text-xs">3</div>
                            <span class="text-xs text-gray-500 mt-1">Keputusan</span>
                        </div>
                        <div class="progress-step relative z-10 flex flex-col items-center" data-step="4">
                            <div class="w-6 h-6 rounded-full bg-gray-200 text-gray-400 flex items-center justify-center text-xs">4</div>
                            <span class="text-xs text-gray-500 mt-1">Selesai</span>
                        </div>
                    </div>
                </div>
                
                <!-- Message for rejected/cancelled -->
                <div id="status-message" class="hidden mt-4 p-4 rounded-lg">
                    <p class="text-sm"></p>
                </div>
            </div>
            
            <!-- Admin Notes (if any) -->
            <div id="admin-notes-card" class="bg-yellow-50 border border-yellow-200 rounded-xl p-4 mb-4 hidden">
                <div class="flex items-start">
                    <i class="fas fa-info-circle text-yellow-500 mt-1 mr-3"></i>
                    <div>
                        <p class="font-medium text-yellow-800">Catatan dari Admin</p>
                        <p id="admin-notes" class="text-sm text-yellow-700 mt-1"></p>
                    </div>
                </div>
            </div>
            
            <!-- Collateral Info -->
            <div class="bg-white rounded-xl shadow-lg p-6 mb-4">
                <h3 class="font-semibold text-gray-800 mb-4">
                    <i class="fas fa-gem text-primary-600 mr-2"></i>
                    Informasi Barang
                </h3>
                
                <!-- Photos -->
                <div id="photos-container" class="grid grid-cols-3 gap-2 mb-4">
                </div>
                
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
                        <span class="text-gray-500">Estimasi Nilai</span>
                        <span id="estimated-value" class="font-medium text-right">-</span>
                    </div>
                </div>
            </div>
            
            <!-- Loan Info -->
            <div class="bg-white rounded-xl shadow-lg p-6 mb-4">
                <h3 class="font-semibold text-gray-800 mb-4">
                    <i class="fas fa-money-bill-wave text-green-600 mr-2"></i>
                    Informasi Pinjaman
                </h3>
                <div class="space-y-3">
                    <div class="flex justify-between">
                        <span class="text-gray-500">Produk</span>
                        <span id="product-name" class="font-medium text-right">-</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-500">Pinjaman Diajukan</span>
                        <span id="requested-amount" class="font-semibold text-primary-600">-</span>
                    </div>
                    <div id="approved-amount-row" class="flex justify-between hidden">
                        <span class="text-gray-500">Pinjaman Disetujui</span>
                        <span id="approved-amount" class="font-semibold text-green-600">-</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-500">Cabang Preferensi</span>
                        <span id="branch-name" class="text-right">-</span>
                    </div>
                </div>
            </div>
            
            <!-- Timeline -->
            <div class="bg-white rounded-xl shadow-lg p-6 mb-4">
                <h3 class="font-semibold text-gray-800 mb-4">
                    <i class="fas fa-history text-gray-600 mr-2"></i>
                    Riwayat
                </h3>
                <div id="timeline" class="space-y-4">
                </div>
            </div>
            
            <!-- Action Buttons -->
            <div id="action-buttons" class="hidden space-y-2">
            </div>
        </div>
    </div>
</div>

<!-- Photo Modal -->
<div id="photo-modal" class="fixed inset-0 bg-black/90 z-50 flex items-center justify-center hidden" onclick="closePhotoModal()">
    <button class="absolute top-4 right-4 text-white text-2xl" onclick="closePhotoModal()">
        <i class="fas fa-times"></i>
    </button>
    <img id="photo-modal-img" src="" class="max-w-full max-h-full object-contain">
</div>

<!-- Bottom Navigation -->
@include('customer.partials.bottom-nav', ['active' => 'requests'])
@endsection

@push('scripts')
<script>
    const requestCode = '{{ $code ?? "" }}' || window.location.pathname.split('/').pop();
    
    async function loadRequest() {
        const response = await api.get(`/pawn-requests/${requestCode}`);
        
        if (response.ok && response.data.success) {
            renderRequest(response.data.data);
        } else {
            UI.toast('Gagal memuat data', 'error');
            setTimeout(() => {
                window.location.href = '{{ route('customer.pawn-requests.index') }}';
            }, 1500);
        }
    }
    
    function renderRequest(req) {
        document.getElementById('loading-state').classList.add('hidden');
        document.getElementById('main-content').classList.remove('hidden');
        
        // Header
        document.getElementById('request-code').textContent = req.request_code;
        document.getElementById('request-title').textContent = req.collateral_name;
        
        // Status badge
        const statusBadge = document.getElementById('status-badge');
        const statusClasses = {
            'PENDING': 'bg-yellow-100 text-yellow-700',
            'REVIEWING': 'bg-blue-100 text-blue-700',
            'DOCUMENT_REQUIRED': 'bg-orange-100 text-orange-700',
            'APPROVED': 'bg-green-100 text-green-700',
            'REJECTED': 'bg-red-100 text-red-700',
            'CANCELLED': 'bg-gray-100 text-gray-700',
            'CONVERTED': 'bg-primary-100 text-primary-700'
        };
        statusBadge.className = `px-3 py-1 rounded-full text-sm font-medium ${statusClasses[req.status] || 'bg-gray-100 text-gray-700'}`;
        statusBadge.textContent = req.status_label;
        
        // Progress tracker
        const progressTracker = document.getElementById('progress-tracker');
        const statusMessage = document.getElementById('status-message');
        
        if (['PENDING', 'REVIEWING', 'DOCUMENT_REQUIRED', 'APPROVED', 'CONVERTED'].includes(req.status)) {
            progressTracker.classList.remove('hidden');
            updateProgress(req.status);
        }
        
        if (req.status === 'REJECTED') {
            statusMessage.classList.remove('hidden');
            statusMessage.className = 'mt-4 p-4 rounded-lg bg-red-50';
            statusMessage.querySelector('p').className = 'text-sm text-red-700';
            statusMessage.querySelector('p').textContent = req.rejection_reason || 'Pengajuan ditolak oleh admin.';
        } else if (req.status === 'CANCELLED') {
            statusMessage.classList.remove('hidden');
            statusMessage.className = 'mt-4 p-4 rounded-lg bg-gray-50';
            statusMessage.querySelector('p').className = 'text-sm text-gray-700';
            statusMessage.querySelector('p').textContent = 'Pengajuan dibatalkan.';
        }
        
        // Admin notes
        if (req.admin_notes) {
            document.getElementById('admin-notes-card').classList.remove('hidden');
            document.getElementById('admin-notes').textContent = req.admin_notes;
        }
        
        // Photos
        const photosContainer = document.getElementById('photos-container');
        if (req.photos && req.photos.length > 0) {
            photosContainer.innerHTML = req.photos.map(photo => `
                <img src="${photo.url || photo}" class="w-full aspect-square object-cover rounded-lg cursor-pointer hover:opacity-80 transition" onclick="showPhoto('${photo.url || photo}')">
            `).join('');
        } else {
            photosContainer.innerHTML = '<p class="text-gray-400 text-sm col-span-3">Tidak ada foto</p>';
        }
        
        // Collateral info
        document.getElementById('collateral-name').textContent = req.collateral_name;
        document.getElementById('collateral-desc').textContent = req.collateral_description || '-';
        document.getElementById('estimated-value').textContent = req.estimated_value_formatted || UI.formatCurrency(req.estimated_value) || '-';
        
        // Loan info
        document.getElementById('product-name').textContent = req.loan_product?.name || '-';
        document.getElementById('requested-amount').textContent = req.requested_loan_amount_formatted || UI.formatCurrency(req.requested_loan_amount);
        
        if (req.approved_loan_amount) {
            document.getElementById('approved-amount-row').classList.remove('hidden');
            document.getElementById('approved-amount').textContent = req.approved_loan_amount_formatted || UI.formatCurrency(req.approved_loan_amount);
        }
        
        document.getElementById('branch-name').textContent = req.preferred_branch?.name || 'Tidak dipilih';
        
        // Timeline
        const timeline = document.getElementById('timeline');
        timeline.innerHTML = renderTimeline(req);
        
        // Action buttons
        const actionButtons = document.getElementById('action-buttons');
        if (req.status === 'PENDING') {
            actionButtons.classList.remove('hidden');
            actionButtons.innerHTML = `
                <button onclick="cancelRequest()" class="w-full bg-red-100 hover:bg-red-200 text-red-700 font-medium py-3 rounded-lg transition">
                    <i class="fas fa-times mr-2"></i> Batalkan Pengajuan
                </button>
            `;
        } else if (req.status === 'APPROVED') {
            actionButtons.classList.remove('hidden');
            actionButtons.innerHTML = `
                <a href="tel:${req.preferred_branch?.phone || ''}" class="block w-full bg-green-600 hover:bg-green-700 text-white text-center font-medium py-3 rounded-lg transition">
                    <i class="fas fa-phone mr-2"></i> Hubungi Cabang
                </a>
                <a href="/customer/branches/${req.preferred_branch?.code || req.preferred_branch?.id}" class="block w-full bg-gray-100 hover:bg-gray-200 text-gray-700 text-center font-medium py-3 rounded-lg transition">
                    <i class="fas fa-map-marker-alt mr-2"></i> Lihat Lokasi Cabang
                </a>
            `;
        }
    }
    
    function updateProgress(status) {
        const steps = {
            'PENDING': 1,
            'REVIEWING': 2,
            'DOCUMENT_REQUIRED': 2,
            'APPROVED': 3,
            'CONVERTED': 4
        };
        
        const currentStep = steps[status] || 1;
        const progress = ((currentStep - 1) / 3) * 100;
        
        document.getElementById('progress-bar').style.width = `${progress}%`;
        
        document.querySelectorAll('.progress-step').forEach(step => {
            const stepNum = parseInt(step.dataset.step);
            const circle = step.querySelector('div');
            
            if (stepNum < currentStep) {
                circle.className = 'w-6 h-6 rounded-full bg-primary-500 text-white flex items-center justify-center text-xs';
                circle.innerHTML = '<i class="fas fa-check"></i>';
            } else if (stepNum === currentStep) {
                circle.className = 'w-6 h-6 rounded-full bg-primary-500 text-white flex items-center justify-center text-xs ring-4 ring-primary-100';
                circle.textContent = stepNum;
            } else {
                circle.className = 'w-6 h-6 rounded-full bg-gray-200 text-gray-400 flex items-center justify-center text-xs';
                circle.textContent = stepNum;
            }
        });
    }
    
    function renderTimeline(req) {
        const events = [
            {
                icon: 'fa-paper-plane',
                color: 'bg-primary-500',
                title: 'Pengajuan Dikirim',
                date: req.created_at_formatted || UI.formatDate(req.created_at)
            }
        ];
        
        if (req.reviewed_at) {
            events.push({
                icon: 'fa-search',
                color: 'bg-blue-500',
                title: 'Mulai Direview',
                date: req.reviewed_at_formatted || UI.formatDate(req.reviewed_at)
            });
        }
        
        if (req.status === 'APPROVED') {
            events.push({
                icon: 'fa-check-circle',
                color: 'bg-green-500',
                title: 'Pengajuan Disetujui',
                date: req.approved_at_formatted || UI.formatDate(req.approved_at)
            });
        } else if (req.status === 'REJECTED') {
            events.push({
                icon: 'fa-times-circle',
                color: 'bg-red-500',
                title: 'Pengajuan Ditolak',
                date: req.rejected_at_formatted || UI.formatDate(req.rejected_at)
            });
        } else if (req.status === 'CANCELLED') {
            events.push({
                icon: 'fa-ban',
                color: 'bg-gray-500',
                title: 'Pengajuan Dibatalkan',
                date: req.cancelled_at_formatted || UI.formatDate(req.cancelled_at)
            });
        }
        
        if (req.status === 'CONVERTED') {
            events.push({
                icon: 'fa-exchange-alt',
                color: 'bg-primary-600',
                title: 'Dikonversi ke Transaksi',
                date: req.converted_at_formatted || UI.formatDate(req.converted_at),
                extra: req.transaction_code ? `No. Transaksi: ${req.transaction_code}` : null
            });
        }
        
        return events.reverse().map((event, index) => `
            <div class="flex items-start">
                <div class="w-8 h-8 rounded-full ${event.color} text-white flex items-center justify-center flex-shrink-0">
                    <i class="fas ${event.icon} text-xs"></i>
                </div>
                <div class="ml-3 flex-1">
                    <p class="font-medium text-gray-800">${event.title}</p>
                    ${event.extra ? `<p class="text-sm text-primary-600">${event.extra}</p>` : ''}
                    <p class="text-xs text-gray-400">${event.date}</p>
                </div>
            </div>
        `).join('');
    }
    
    function showPhoto(url) {
        document.getElementById('photo-modal-img').src = url;
        document.getElementById('photo-modal').classList.remove('hidden');
    }
    
    function closePhotoModal() {
        document.getElementById('photo-modal').classList.add('hidden');
    }
    
    async function cancelRequest() {
        if (!confirm('Yakin ingin membatalkan pengajuan ini?')) return;
        
        UI.showLoading();
        const response = await api.post(`/pawn-requests/${requestCode}/cancel`);
        UI.hideLoading();
        
        if (response.ok && response.data.success) {
            UI.toast('Pengajuan dibatalkan', 'success');
            loadRequest();
        } else {
            UI.toast(response.data.message || 'Gagal membatalkan', 'error');
        }
    }
    
    // Keyboard shortcut for modal
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closePhotoModal();
        }
    });
    
    // Init
    document.addEventListener('DOMContentLoaded', loadRequest);
</script>
@endpush
