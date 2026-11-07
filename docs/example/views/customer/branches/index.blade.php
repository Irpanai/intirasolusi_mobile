@extends('customer.layouts.app')

@section('title', 'Lokasi Cabang')

@section('content')
<div class="min-h-screen pb-24">
    <!-- Header -->
    <div class="bg-gradient-to-br from-primary-600 to-primary-800 text-white pt-6 pb-12 px-6">
        <h1 class="text-xl font-bold mb-4">Lokasi Cabang</h1>
        
        <!-- Search -->
        <div class="relative">
            <input type="text" id="search-input" placeholder="Cari cabang..." class="w-full pl-10 pr-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-white/60 focus:bg-white/20 focus:border-white/40 outline-none transition" oninput="handleSearch(this.value)">
            <i class="fas fa-search absolute left-4 top-1/2 -translate-y-1/2 text-white/60"></i>
        </div>
    </div>
    
    <!-- Content -->
    <div class="px-6 -mt-4">
        <div id="branches-container" class="space-y-3">
            <!-- Loading skeleton -->
            <div class="skeleton h-32 rounded-xl"></div>
            <div class="skeleton h-32 rounded-xl"></div>
            <div class="skeleton h-32 rounded-xl"></div>
        </div>
        
        <!-- Pagination -->
        <div id="pagination-container" class="hidden mt-4 flex items-center justify-between bg-white rounded-xl shadow-lg p-4">
            <button id="prev-btn" onclick="goToPage(currentPage - 1)" class="px-4 py-2 bg-gray-100 text-gray-600 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-200 transition">
                <i class="fas fa-chevron-left mr-1"></i> Prev
            </button>
            <span id="page-info" class="text-sm text-gray-600"></span>
            <button id="next-btn" onclick="goToPage(currentPage + 1)" class="px-4 py-2 bg-gray-100 text-gray-600 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-200 transition">
                Next <i class="fas fa-chevron-right ml-1"></i>
            </button>
        </div>
        
        <!-- Empty State -->
        <div id="empty-state" class="hidden bg-white rounded-xl p-8 text-center shadow-lg">
            <div class="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <i class="fas fa-map-marker-alt text-3xl text-gray-300"></i>
            </div>
            <h3 class="font-semibold text-gray-800 mb-2">Tidak Ada Cabang</h3>
            <p class="text-gray-500 text-sm">Cabang tidak ditemukan.</p>
        </div>
    </div>
</div>

<!-- Bottom Navigation -->
@include('customer.partials.bottom-nav', ['active' => 'profile'])
@endsection

@push('scripts')
<script>
    let allBranches = [];
    let filteredBranches = [];
    let searchTimeout = null;
    let currentPage = 1;
    const perPage = 10;
    
    async function loadBranches() {
        const container = document.getElementById('branches-container');
        const emptyState = document.getElementById('empty-state');
        const paginationContainer = document.getElementById('pagination-container');
        
        container.innerHTML = `
            <div class="skeleton h-32 rounded-xl"></div>
            <div class="skeleton h-32 rounded-xl"></div>
            <div class="skeleton h-32 rounded-xl"></div>
        `;
        emptyState.classList.add('hidden');
        paginationContainer.classList.add('hidden');
        
        const response = await api.get('/branches');
        
        if (response.ok && response.data.success) {
            allBranches = response.data.data.data || response.data.data;
            filteredBranches = [...allBranches];
            currentPage = 1;
            renderBranches();
        } else {
            UI.toast('Gagal memuat data', 'error');
        }
    }
    
    function renderBranches() {
        const container = document.getElementById('branches-container');
        const emptyState = document.getElementById('empty-state');
        const paginationContainer = document.getElementById('pagination-container');
        
        if (filteredBranches.length === 0) {
            container.innerHTML = '';
            emptyState.classList.remove('hidden');
            paginationContainer.classList.add('hidden');
        } else {
            emptyState.classList.add('hidden');
            
            // Calculate pagination
            const totalPages = Math.ceil(filteredBranches.length / perPage);
            const start = (currentPage - 1) * perPage;
            const end = start + perPage;
            const paginatedBranches = filteredBranches.slice(start, end);
            
            container.innerHTML = paginatedBranches.map(branch => renderBranchCard(branch)).join('');
            
            // Update pagination UI
            if (filteredBranches.length > perPage) {
                paginationContainer.classList.remove('hidden');
                document.getElementById('page-info').textContent = `Halaman ${currentPage} dari ${totalPages}`;
                document.getElementById('prev-btn').disabled = currentPage === 1;
                document.getElementById('next-btn').disabled = currentPage === totalPages;
            } else {
                paginationContainer.classList.add('hidden');
            }
        }
    }
    
    function goToPage(page) {
        const totalPages = Math.ceil(filteredBranches.length / perPage);
        if (page >= 1 && page <= totalPages) {
            currentPage = page;
            renderBranches();
            // Scroll to top of list
            document.getElementById('branches-container').scrollIntoView({ behavior: 'smooth' });
        }
    }
    
    function renderBranchCard(branch) {
        const isOpen = branch.is_open !== undefined ? branch.is_open : true;
        
        return `
            <a href="/customer/branches/${branch.code || branch.id}" class="block bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition">
                <div class="p-4">
                    <div class="flex items-start justify-between mb-2">
                        <div class="flex-1">
                            <h3 class="font-semibold text-gray-800">${branch.name}</h3>
                            <p class="text-xs text-gray-400">${branch.code || ''}</p>
                        </div>
                        <span class="px-2 py-1 rounded-full text-xs font-medium ${isOpen ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}">
                            ${isOpen ? 'Buka' : 'Tutup'}
                        </span>
                    </div>
                    
                    <div class="flex items-start text-gray-600 text-sm mb-3">
                        <i class="fas fa-map-marker-alt text-gray-400 mt-0.5 mr-2 w-4"></i>
                        <p class="line-clamp-2">${branch.address || '-'}</p>
                    </div>
                    
                    <div class="flex items-center justify-between">
                        <div class="flex items-center text-sm text-gray-500">
                            <i class="fas fa-phone-alt text-gray-400 mr-2"></i>
                            <span>${branch.phone || '-'}</span>
                        </div>
                        <span class="text-primary-600 text-sm font-medium">
                            Detail <i class="fas fa-chevron-right ml-1"></i>
                        </span>
                    </div>
                </div>
            </a>
        `;
    }
    
    function handleSearch(query) {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(() => {
            filteredBranches = allBranches.filter(branch => {
                const searchStr = (branch.name + ' ' + branch.address + ' ' + branch.code).toLowerCase();
                return searchStr.includes(query.toLowerCase());
            });
            currentPage = 1; // Reset to first page on search
            renderBranches();
        }, 300);
    }
    
    // Init
    document.addEventListener('DOMContentLoaded', loadBranches);
</script>
@endpush
