@extends('customer.layouts.app')

@section('title', 'Kalkulator Pinjaman')

@section('content')
<div class="min-h-screen pb-6">
    <!-- Header -->
    <div class="bg-gradient-to-br from-primary-600 to-primary-800 text-white pt-6 pb-16 px-6 rounded-b-3xl">
        <a href="{{ route('customer.dashboard') }}" class="inline-flex items-center text-white/80 hover:text-white mb-4">
            <i class="fas fa-arrow-left mr-2"></i>
            <span>Kembali</span>
        </a>
        <div class="text-center">
            <div class="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-3">
                <i class="fas fa-calculator text-3xl"></i>
            </div>
            <h1 class="text-xl font-bold">Kalkulator Pinjaman</h1>
            <p class="text-primary-100 text-sm mt-1">Simulasi pinjaman gadai Anda</p>
        </div>
    </div>
    
    <!-- Calculator Form -->
    <div class="px-6 -mt-8">
        <div class="bg-white rounded-2xl shadow-lg p-6 mb-6">
            <!-- Product Selection -->
            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-2">Pilih Produk Pinjaman</label>
                <div id="products-loading" class="skeleton h-12 rounded-lg"></div>
                <select 
                    id="loan_product_id" 
                    class="hidden w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                >
                    <option value="">Pilih Produk</option>
                </select>
            </div>
            
            <!-- Product Info -->
            <div id="product-info" class="hidden bg-gray-50 rounded-lg p-4 mb-4">
                <div class="flex items-center justify-between text-sm">
                    <span class="text-gray-600">Kategori:</span>
                    <span id="product-category" class="font-medium">-</span>
                </div>
                <div class="flex items-center justify-between text-sm mt-2">
                    <span class="text-gray-600">Tenor:</span>
                    <span id="product-tenor" class="font-medium">-</span>
                </div>
                <div class="flex items-center justify-between text-sm mt-2">
                    <span class="text-gray-600">Min - Max Pinjaman:</span>
                    <span id="product-range" class="font-medium">-</span>
                </div>
            </div>
            
            <!-- Loan Amount Input -->
            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-2">Jumlah Pinjaman</label>
                <div class="relative">
                    <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-medium">Rp</span>
                    <input 
                        type="text" 
                        id="loan_amount"
                        placeholder="0"
                        class="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition text-right text-lg font-semibold"
                    >
                </div>
                <p id="amount-error" class="text-red-500 text-xs mt-1 hidden"></p>
            </div>
            
            <!-- Quick Amount Buttons -->
            <div class="flex flex-wrap gap-2 mb-6">
                <button type="button" onclick="setAmount(1000000)" class="px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded-lg text-sm font-medium transition">1 Juta</button>
                <button type="button" onclick="setAmount(2000000)" class="px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded-lg text-sm font-medium transition">2 Juta</button>
                <button type="button" onclick="setAmount(5000000)" class="px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded-lg text-sm font-medium transition">5 Juta</button>
                <button type="button" onclick="setAmount(10000000)" class="px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded-lg text-sm font-medium transition">10 Juta</button>
                <button type="button" onclick="setAmount(25000000)" class="px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded-lg text-sm font-medium transition">25 Juta</button>
            </div>
            
            <!-- Calculate Button -->
            <button 
                type="button"
                id="calculate-btn"
                onclick="calculate()"
                class="w-full bg-primary-600 hover:bg-primary-700 text-white font-semibold py-3 rounded-lg transition flex items-center justify-center space-x-2"
            >
                <i class="fas fa-calculator"></i>
                <span>Hitung Simulasi</span>
            </button>
        </div>
        
        <!-- Calculation Result -->
        <div id="result-container" class="hidden">
            <h2 class="text-lg font-semibold text-gray-800 mb-3">Hasil Simulasi</h2>
            
            <div class="bg-white rounded-2xl shadow-lg overflow-hidden">
                <!-- Summary Header -->
                <div class="bg-primary-600 text-white p-4">
                    <p class="text-primary-100 text-sm">Yang Anda Terima</p>
                    <p id="result-cash" class="text-2xl font-bold">-</p>
                </div>
                
                <!-- Details -->
                <div class="p-4 space-y-3">
                    <div class="flex items-center justify-between">
                        <span class="text-gray-600">Pinjaman Pokok</span>
                        <span id="result-principal" class="font-semibold">-</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <span class="text-gray-600">Biaya Admin</span>
                        <span id="result-admin" class="font-medium text-red-600">-</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <span class="text-gray-600">Biaya Jasa/Bunga</span>
                        <span id="result-interest" class="font-medium text-red-600">-</span>
                    </div>
                    <div class="border-t border-gray-200 pt-3 flex items-center justify-between">
                        <span class="text-gray-600">Total Potongan</span>
                        <span id="result-deduction" class="font-semibold text-red-600">-</span>
                    </div>
                </div>
                
                <!-- Due Date & Extension -->
                <div class="bg-gray-50 p-4 space-y-3">
                    <div class="flex items-center justify-between">
                        <span class="text-gray-600">
                            <i class="fas fa-calendar-alt mr-1"></i> Tenor
                        </span>
                        <span id="result-tenor" class="font-semibold">-</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <span class="text-gray-600">
                            <i class="fas fa-clock mr-1"></i> Jatuh Tempo
                        </span>
                        <span id="result-due" class="font-semibold">-</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <span class="text-gray-600">
                            <i class="fas fa-redo mr-1"></i> Biaya Perpanjangan
                        </span>
                        <span id="result-extension" class="font-semibold text-end">-</span>
                    </div>
                </div>
                
                <!-- Notes -->
                <div id="result-notes" class="p-4 border-t border-gray-200">
                    <p class="text-sm font-medium text-gray-700 mb-2">
                        <i class="fas fa-info-circle text-primary-600 mr-1"></i> Catatan:
                    </p>
                    <ul class="text-sm text-gray-600 space-y-1"></ul>
                </div>
            </div>
            
            <!-- CTA -->
            <div class="mt-6">
                <a href="{{ route('customer.pawn-requests.create') }}" class="block w-full bg-green-600 hover:bg-green-700 text-white font-semibold py-3 rounded-lg transition text-center">
                    <i class="fas fa-paper-plane mr-2"></i>
                    Ajukan Gadai Sekarang
                </a>
            </div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
    let products = [];
    let selectedProduct = null;
    
    // Format number input
    const loanAmountInput = document.getElementById('loan_amount');
    loanAmountInput.addEventListener('input', function(e) {
        let value = this.value.replace(/\D/g, '');
        if (value) {
            this.value = new Intl.NumberFormat('id-ID').format(parseInt(value));
        }
    });
    
    function setAmount(amount) {
        loanAmountInput.value = new Intl.NumberFormat('id-ID').format(amount);
    }
    
    function getAmount() {
        return parseInt(loanAmountInput.value.replace(/\D/g, '')) || 0;
    }
    
    // Load products
    async function loadProducts() {
        const response = await api.get('/calculator/products');
        
        if (response.ok && response.data.success) {
            products = response.data.data;
            
            const select = document.getElementById('loan_product_id');
            products.forEach(product => {
                const option = document.createElement('option');
                option.value = product.id;
                option.textContent = product.name + (product.is_sharia ? ' (Syariah)' : '');
                option.dataset.product = JSON.stringify(product);
                select.appendChild(option);
            });
            
            document.getElementById('products-loading').classList.add('hidden');
            select.classList.remove('hidden');
        }
    }
    
    // Product change handler
    document.getElementById('loan_product_id').addEventListener('change', function() {
        const productInfo = document.getElementById('product-info');
        
        if (this.value) {
            const option = this.options[this.selectedIndex];
            selectedProduct = JSON.parse(option.dataset.product);
            
            document.getElementById('product-category').textContent = selectedProduct.category || '-';
            document.getElementById('product-tenor').textContent = selectedProduct.initial_tenor_days + ' hari';
            document.getElementById('product-range').textContent = 
                UI.formatCurrency(selectedProduct.loan_min) + ' - ' + UI.formatCurrency(selectedProduct.loan_max);
            
            productInfo.classList.remove('hidden');
        } else {
            selectedProduct = null;
            productInfo.classList.add('hidden');
        }
        
        // Hide result
        document.getElementById('result-container').classList.add('hidden');
    });
    
    // Calculate
    async function calculate() {
        const productId = document.getElementById('loan_product_id').value;
        const amount = getAmount();
        const amountError = document.getElementById('amount-error');
        
        // Reset error
        amountError.classList.add('hidden');
        
        // Validate
        if (!productId) {
            UI.toast('Pilih produk pinjaman terlebih dahulu', 'warning');
            return;
        }
        
        if (!amount) {
            amountError.textContent = 'Masukkan jumlah pinjaman';
            amountError.classList.remove('hidden');
            return;
        }
        
        if (selectedProduct && (amount < selectedProduct.loan_min || amount > selectedProduct.loan_max)) {
            amountError.textContent = `Jumlah harus antara ${UI.formatCurrency(selectedProduct.loan_min)} - ${UI.formatCurrency(selectedProduct.loan_max)}`;
            amountError.classList.remove('hidden');
            return;
        }
        
        const btn = document.getElementById('calculate-btn');
        btn.disabled = true;
        btn.innerHTML = '<div class="spinner"></div>';
        
        const response = await api.post('/calculator/calculate', {
            loan_product_id: parseInt(productId),
            loan_amount: amount
        });
        
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-calculator"></i><span>Hitung Simulasi</span>';
        
        if (response.ok && response.data.success) {
            renderResult(response.data.data);
        } else {
            UI.toast(response.data.message || 'Gagal menghitung', 'error');
        }
    }
    
    function renderResult(data) {
        const calc = data.calculation;
        
        document.getElementById('result-cash').textContent = calc.cash_received_formatted;
        document.getElementById('result-principal').textContent = calc.loan_amount_formatted;
        document.getElementById('result-admin').textContent = '- ' + calc.admin_fee_formatted;
        document.getElementById('result-interest').textContent = '- ' + calc.initial_fee_formatted;
        document.getElementById('result-deduction').textContent = '- ' + calc.total_deduction_formatted;
        document.getElementById('result-tenor').textContent = calc.tenor_days + ' hari';
        document.getElementById('result-due').textContent = calc.due_date_formatted;
        document.getElementById('result-extension').textContent = calc.extension_fee_formatted + ' / perpanjangan';
        
        // Notes
        const notesList = document.querySelector('#result-notes ul');
        notesList.innerHTML = (data.notes || [])
            .filter(n => n)
            .map(note => `<li class="flex items-start"><i class="fas fa-check text-green-500 mr-2 mt-0.5 text-xs"></i>${note}</li>`)
            .join('');
        
        document.getElementById('result-container').classList.remove('hidden');
        
        // Scroll to result
        document.getElementById('result-container').scrollIntoView({ behavior: 'smooth' });
    }
    
    // Load products on page load
    document.addEventListener('DOMContentLoaded', loadProducts);
</script>
@endpush
