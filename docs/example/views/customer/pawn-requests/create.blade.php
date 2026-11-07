@extends('customer.layouts.app')

@section('title', 'Ajukan Gadai')

@section('content')
<div class="min-h-screen pb-6">
    <!-- Header -->
    <div class="bg-gradient-to-br from-primary-600 to-primary-800 text-white pt-6 pb-12 px-6">
        <a href="{{ route('customer.pawn-requests.index') }}" class="inline-flex items-center text-white/80 hover:text-white mb-4">
            <i class="fas fa-arrow-left mr-2"></i>
            <span>Kembali</span>
        </a>
        <h1 class="text-xl font-bold">Ajukan Gadai Online</h1>
        <p class="text-primary-100 text-sm mt-1">Isi form berikut untuk mengajukan gadai</p>
    </div>
    
    <!-- Form -->
    <div class="px-6 -mt-4">
        <div class="bg-white rounded-2xl shadow-lg p-6">
            <form id="pawn-form" enctype="multipart/form-data">
                <!-- Step Indicator -->
                <div class="flex items-center justify-center mb-6">
                    <div class="flex items-center text-sm">
                        <div class="step-indicator w-8 h-8 rounded-full bg-primary-600 text-white flex items-center justify-center font-semibold" data-step="1">1</div>
                        <span class="ml-2 text-gray-700">Info Barang</span>
                    </div>
                    <div class="w-8 h-0.5 bg-gray-200 mx-2"></div>
                    <div class="flex items-center text-sm">
                        <div class="step-indicator w-8 h-8 rounded-full bg-gray-200 text-gray-500 flex items-center justify-center font-semibold" data-step="2">2</div>
                        <span class="ml-2 text-gray-400">Foto Barang</span>
                    </div>
                    <div class="w-8 h-0.5 bg-gray-200 mx-2"></div>
                    <div class="flex items-center text-sm">
                        <div class="step-indicator w-8 h-8 rounded-full bg-gray-200 text-gray-500 flex items-center justify-center font-semibold" data-step="3">3</div>
                        <span class="ml-2 text-gray-400">Kirim</span>
                    </div>
                </div>
                
                <!-- Step 1: Product & Collateral Info -->
                <div id="step-1" class="step-content">
                    <!-- Loan Product -->
                    <div class="mb-4">
                        <label class="block text-sm font-medium text-gray-700 mb-1">Produk Pinjaman <span class="text-red-500">*</span></label>
                        <select id="loan_product_id" name="loan_product_id" class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition" required>
                            <option value="">Pilih Produk</option>
                        </select>
                        <p class="text-red-500 text-xs mt-1 hidden" id="loan_product_id-error"></p>
                    </div>
                    
                    <!-- Collateral Category -->
                    <div class="mb-4">
                        <label class="block text-sm font-medium text-gray-700 mb-1">Kategori Barang <span class="text-red-500">*</span></label>
                        <select id="collateral_category_id" name="collateral_category_id" class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition" required>
                            <option value="">Pilih Kategori</option>
                        </select>
                        <p class="text-red-500 text-xs mt-1 hidden" id="collateral_category_id-error"></p>
                    </div>
                    
                    <!-- Collateral Name -->
                    <div class="mb-4">
                        <label class="block text-sm font-medium text-gray-700 mb-1">Nama Barang Jaminan <span class="text-red-500">*</span></label>
                        <input type="text" id="collateral_name" name="collateral_name" placeholder="Contoh: Cincin Emas 5 gram" class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition" required>
                        <p class="text-red-500 text-xs mt-1 hidden" id="collateral_name-error"></p>
                    </div>
                    
                    <!-- Collateral Description -->
                    <div class="mb-4">
                        <label class="block text-sm font-medium text-gray-700 mb-1">Deskripsi Barang</label>
                        <textarea id="collateral_description" name="collateral_description" rows="3" placeholder="Deskripsi detail barang (warna, kondisi, dll)" class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition resize-none"></textarea>
                    </div>
                    
                    <!-- Estimated Value -->
                    <div class="mb-4">
                        <label class="block text-sm font-medium text-gray-700 mb-1">Estimasi Nilai Barang</label>
                        <div class="relative">
                            <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500">Rp</span>
                            <input type="text" id="estimated_value" name="estimated_value" placeholder="0" class="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition text-right">
                        </div>
                        <p class="text-gray-500 text-xs mt-1">Opsional - Perkiraan harga barang Anda</p>
                    </div>
                    
                    <!-- Requested Loan Amount -->
                    <div class="mb-4">
                        <label class="block text-sm font-medium text-gray-700 mb-1">Jumlah Pinjaman yang Diinginkan <span class="text-red-500">*</span></label>
                        <div class="relative">
                            <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500">Rp</span>
                            <input type="text" id="requested_loan_amount" name="requested_loan_amount" placeholder="0" class="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition text-right font-semibold" required>
                        </div>
                        <p id="loan-range-info" class="text-gray-500 text-xs mt-1"></p>
                        <p class="text-red-500 text-xs mt-1 hidden" id="requested_loan_amount-error"></p>
                    </div>
                    
                    <!-- Preferred Branch -->
                    <div class="mb-4">
                        <label class="block text-sm font-medium text-gray-700 mb-1">Cabang Preferensi</label>
                        <select id="preferred_branch_id" name="preferred_branch_id" class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition">
                            <option value="">Pilih Cabang (Opsional)</option>
                        </select>
                        <p class="text-gray-500 text-xs mt-1">Cabang yang ingin Anda kunjungi untuk proses gadai</p>
                    </div>
                    
                    <!-- Notes -->
                    <div class="mb-6">
                        <label class="block text-sm font-medium text-gray-700 mb-1">Catatan Tambahan</label>
                        <textarea id="customer_notes" name="customer_notes" rows="2" placeholder="Catatan untuk admin (opsional)" class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition resize-none"></textarea>
                    </div>
                    
                    <button type="button" onclick="nextStep(2)" class="w-full bg-primary-600 hover:bg-primary-700 text-white font-semibold py-3 rounded-lg transition">
                        Lanjut <i class="fas fa-arrow-right ml-2"></i>
                    </button>
                </div>
                
                <!-- Step 2: Photos -->
                <div id="step-2" class="step-content hidden">
                    <div class="text-center mb-6">
                        <div class="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-3">
                            <i class="fas fa-camera text-2xl text-primary-600"></i>
                        </div>
                        <h3 class="font-semibold text-gray-800">Upload Foto Barang</h3>
                        <p class="text-gray-500 text-sm">Foto yang jelas membantu proses review lebih cepat</p>
                    </div>
                    
                    <!-- Photo Upload Area -->
                    <div class="mb-6">
                        <div id="photo-preview" class="grid grid-cols-3 gap-2 mb-3"></div>
                        
                        <label class="block border-2 border-dashed border-gray-300 rounded-xl p-6 text-center cursor-pointer hover:border-primary-500 transition" id="photo-upload-label">
                            <input type="file" id="collateral_photos" name="collateral_photos[]" accept="image/*" multiple class="hidden" onchange="handlePhotoUpload(this)">
                            <i class="fas fa-cloud-upload-alt text-3xl text-gray-400 mb-2"></i>
                            <p class="text-gray-600 font-medium">Tap untuk upload foto</p>
                            <p class="text-gray-400 text-sm">JPG, PNG (Max 5MB per foto)</p>
                        </label>
                        <p class="text-gray-500 text-xs mt-2 text-center">Minimal 1 foto, maksimal 5 foto</p>
                        <p class="text-red-500 text-xs mt-1 hidden text-center" id="collateral_photos-error"></p>
                    </div>
                    
                    <!-- Tips -->
                    <div class="bg-blue-50 rounded-lg p-4 mb-6">
                        <p class="font-medium text-blue-800 mb-2">
                            <i class="fas fa-lightbulb mr-1"></i> Tips foto yang baik:
                        </p>
                        <ul class="text-sm text-blue-700 space-y-1">
                            <li><i class="fas fa-check mr-1"></i> Foto dengan pencahayaan yang cukup</li>
                            <li><i class="fas fa-check mr-1"></i> Foto dari berbagai sisi</li>
                            <li><i class="fas fa-check mr-1"></i> Pastikan foto tidak blur</li>
                            <li><i class="fas fa-check mr-1"></i> Sertakan foto cap/merk jika ada</li>
                        </ul>
                    </div>
                    
                    <div class="flex space-x-3">
                        <button type="button" onclick="prevStep(1)" class="flex-1 bg-gray-100 hover:bg-gray-200 text-gray-700 font-semibold py-3 rounded-lg transition">
                            <i class="fas fa-arrow-left mr-2"></i> Kembali
                        </button>
                        <button type="button" onclick="nextStep(3)" class="flex-1 bg-primary-600 hover:bg-primary-700 text-white font-semibold py-3 rounded-lg transition">
                            Lanjut <i class="fas fa-arrow-right ml-2"></i>
                        </button>
                    </div>
                </div>
                
                <!-- Step 3: Confirmation -->
                <div id="step-3" class="step-content hidden">
                    <div class="text-center mb-6">
                        <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-3">
                            <i class="fas fa-check-circle text-2xl text-green-600"></i>
                        </div>
                        <h3 class="font-semibold text-gray-800">Konfirmasi Pengajuan</h3>
                        <p class="text-gray-500 text-sm">Pastikan data sudah benar sebelum mengirim</p>
                    </div>
                    
                    <!-- Summary -->
                    <div class="bg-gray-50 rounded-xl p-4 mb-6 divide-y divide-gray-200">
                        <div class="py-3">
                            <p class="text-xs text-gray-500 uppercase tracking-wide mb-1">Produk</p>
                            <p id="summary-product" class="font-medium text-gray-800">-</p>
                        </div>
                        <div class="py-3">
                            <p class="text-xs text-gray-500 uppercase tracking-wide mb-1">Kategori Barang</p>
                            <p id="summary-category" class="font-medium text-gray-800">-</p>
                        </div>
                        <div class="py-3">
                            <p class="text-xs text-gray-500 uppercase tracking-wide mb-1">Barang Jaminan</p>
                            <p id="summary-collateral" class="font-medium text-gray-800">-</p>
                        </div>
                        <div class="py-3">
                            <p class="text-xs text-gray-500 uppercase tracking-wide mb-1">Jumlah Pinjaman</p>
                            <p id="summary-amount" class="font-semibold text-primary-600 text-lg">-</p>
                        </div>
                        <div class="py-3">
                            <p class="text-xs text-gray-500 uppercase tracking-wide mb-1">Jumlah Foto</p>
                            <p id="summary-photos" class="font-medium text-gray-800">-</p>
                        </div>
                        <div class="py-3">
                            <p class="text-xs text-gray-500 uppercase tracking-wide mb-1">Cabang Preferensi</p>
                            <p id="summary-branch" class="font-medium text-gray-800">-</p>
                        </div>
                    </div>
                    
                    <!-- Terms -->
                    <div class="bg-white border border-gray-200 rounded-xl p-4 mb-6">
                        <label class="flex items-start cursor-pointer">
                            <input type="checkbox" id="terms" class="mt-0.5 w-5 h-5 rounded border-gray-300 text-primary-600 focus:ring-primary-500">
                            <span class="ml-3 text-sm text-gray-700">
                                Saya menyatakan data yang saya berikan adalah benar dan menyetujui <a href="#" class="text-primary-600 font-medium hover:underline">Syarat & Ketentuan</a> gadai online.
                            </span>
                        </label>
                    </div>
                    
                    <!-- Error Message -->
                    <div id="form-error" class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg text-sm hidden mb-4">
                    </div>
                    
                    <!-- Upload Progress -->
                    <div id="upload-progress" class="hidden mb-4">
                        <div class="flex items-center justify-between text-sm text-gray-600 mb-2">
                            <span>Mengupload foto...</span>
                            <span id="progress-text">0%</span>
                        </div>
                        <div class="w-full bg-gray-200 rounded-full h-2">
                            <div id="progress-bar" class="bg-primary-600 h-2 rounded-full transition-all duration-300" style="width: 0%"></div>
                        </div>
                    </div>
                    
                    <div class="flex space-x-3">
                        <button type="button" onclick="prevStep(2)" class="flex-1 bg-gray-100 hover:bg-gray-200 text-gray-700 font-semibold py-3 rounded-lg transition">
                            <i class="fas fa-arrow-left mr-2"></i> Kembali
                        </button>
                        <button type="submit" id="submit-btn" disabled class="flex-1 bg-gray-300 text-gray-500 font-semibold py-3 rounded-lg transition cursor-not-allowed disabled:opacity-60">
                            <i class="fas fa-paper-plane mr-2"></i> Kirim
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
    let products = [];
    let branches = [];
    let categories = [];
    let uploadedPhotos = []; // Will store compressed image blobs
    let currentStep = 1;
    
    // Image compression function
    async function compressImage(file, maxWidth = 1200, quality = 0.7) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = function(e) {
                const img = new Image();
                img.onload = function() {
                    const canvas = document.createElement('canvas');
                    let width = img.width;
                    let height = img.height;
                    
                    // Scale down if too large
                    if (width > maxWidth) {
                        height = Math.round(height * maxWidth / width);
                        width = maxWidth;
                    }
                    
                    canvas.width = width;
                    canvas.height = height;
                    
                    const ctx = canvas.getContext('2d');
                    ctx.drawImage(img, 0, 0, width, height);
                    
                    canvas.toBlob(function(blob) {
                        if (blob) {
                            // Create a new File from blob with original name
                            const compressedFile = new File([blob], file.name, {
                                type: 'image/jpeg',
                                lastModified: Date.now()
                            });
                            resolve(compressedFile);
                        } else {
                            resolve(file); // Fallback to original
                        }
                    }, 'image/jpeg', quality);
                };
                img.onerror = () => reject(new Error('Failed to load image'));
                img.src = e.target.result;
            };
            reader.onerror = () => reject(new Error('Failed to read file'));
            reader.readAsDataURL(file);
        });
    }
    
    // Format currency inputs
    ['estimated_value', 'requested_loan_amount'].forEach(id => {
        document.getElementById(id).addEventListener('input', function() {
            let value = this.value.replace(/\D/g, '');
            if (value) {
                this.value = new Intl.NumberFormat('id-ID').format(parseInt(value));
            }
        });
    });
    
    function getNumericValue(id) {
        return parseInt(document.getElementById(id).value.replace(/\D/g, '')) || 0;
    }
    
    // Load products
    async function loadProducts() {
        const response = await api.get('/calculator/products');
        if (response.ok && response.data.success) {
            products = response.data.data;
            const select = document.getElementById('loan_product_id');
            products.forEach(p => {
                const option = document.createElement('option');
                option.value = p.id;
                option.textContent = p.name + (p.is_sharia ? ' (Syariah)' : '');
                option.dataset.product = JSON.stringify(p);
                select.appendChild(option);
            });
        }
    }
    
    // Load collateral categories
    async function loadCategories() {
        const response = await api.get('/calculator/collateral-categories');
        if (response.ok && response.data.success) {
            categories = response.data.data;
            const select = document.getElementById('collateral_category_id');
            categories.forEach(c => {
                const option = document.createElement('option');
                option.value = c.id;
                option.textContent = c.name;
                select.appendChild(option);
            });
        }
    }
    
    // Load branches
    async function loadBranches() {
        const response = await api.get('/branches');
        if (response.ok && response.data.success) {
            branches = response.data.data.data || response.data.data;
            const select = document.getElementById('preferred_branch_id');
            branches.forEach(b => {
                const option = document.createElement('option');
                option.value = b.id;
                option.textContent = b.name;
                select.appendChild(option);
            });
        }
    }
    
    // Show loan range on product change
    document.getElementById('loan_product_id').addEventListener('change', function() {
        const info = document.getElementById('loan-range-info');
        if (this.value) {
            const product = JSON.parse(this.options[this.selectedIndex].dataset.product);
            info.textContent = `Range: ${UI.formatCurrency(product.loan_min)} - ${UI.formatCurrency(product.loan_max)}`;
        } else {
            info.textContent = '';
        }
    });
    
    // Photo upload handler with compression
    async function handlePhotoUpload(input) {
        const files = Array.from(input.files);
        const preview = document.getElementById('photo-preview');
        const error = document.getElementById('collateral_photos-error');
        const uploadLabel = document.getElementById('photo-upload-label');
        
        error.classList.add('hidden');
        
        // Validate count
        if (uploadedPhotos.length + files.length > 5) {
            error.textContent = 'Maksimal 5 foto';
            error.classList.remove('hidden');
            input.value = '';
            return;
        }
        
        // Show processing indicator
        uploadLabel.innerHTML = `
            <div class="flex items-center justify-center">
                <div class="spinner mr-2"></div>
                <span class="text-gray-600">Memproses foto...</span>
            </div>
        `;
        
        for (const file of files) {
            if (file.size > 10 * 1024 * 1024) { // Allow up to 10MB raw (will be compressed)
                error.textContent = 'Ukuran file terlalu besar';
                error.classList.remove('hidden');
                continue;
            }
            
            try {
                // Compress the image
                const compressedFile = await compressImage(file);
                console.log(`Compressed: ${(file.size / 1024).toFixed(0)}KB -> ${(compressedFile.size / 1024).toFixed(0)}KB`);
                
                uploadedPhotos.push(compressedFile);
                
                // Create preview
                const reader = new FileReader();
                reader.onload = function(e) {
                    const div = document.createElement('div');
                    div.className = 'relative aspect-square';
                    div.innerHTML = `
                        <img src="${e.target.result}" class="w-full h-full object-cover rounded-lg">
                        <button type="button" onclick="removePhoto(${uploadedPhotos.length - 1})" class="absolute -top-2 -right-2 w-6 h-6 bg-red-500 text-white rounded-full flex items-center justify-center text-xs hover:bg-red-600">
                            <i class="fas fa-times"></i>
                        </button>
                        <span class="absolute bottom-1 right-1 bg-black/60 text-white text-[10px] px-1 rounded">
                            ${(compressedFile.size / 1024).toFixed(0)}KB
                        </span>
                    `;
                    preview.appendChild(div);
                };
                reader.readAsDataURL(compressedFile);
            } catch (err) {
                console.error('Compression failed:', err);
                error.textContent = 'Gagal memproses foto';
                error.classList.remove('hidden');
            }
        }
        
        // Restore upload label
        uploadLabel.innerHTML = `
            <input type="file" id="collateral_photos" name="collateral_photos[]" accept="image/*" multiple class="hidden" onchange="handlePhotoUpload(this)">
            <i class="fas fa-cloud-upload-alt text-3xl text-gray-400 mb-2"></i>
            <p class="text-gray-600 font-medium">Tap untuk upload foto</p>
            <p class="text-gray-400 text-sm">JPG, PNG (Max 5MB per foto)</p>
        `;
        
        input.value = '';
    }
    
    function removePhoto(index) {
        uploadedPhotos.splice(index, 1);
        refreshPhotoPreview();
    }
    
    function refreshPhotoPreview() {
        const preview = document.getElementById('photo-preview');
        preview.innerHTML = '';
        
        uploadedPhotos.forEach((file, index) => {
            const reader = new FileReader();
            reader.onload = function(e) {
                const div = document.createElement('div');
                div.className = 'relative aspect-square';
                div.innerHTML = `
                    <img src="${e.target.result}" class="w-full h-full object-cover rounded-lg">
                    <button type="button" onclick="removePhoto(${index})" class="absolute -top-2 -right-2 w-6 h-6 bg-red-500 text-white rounded-full flex items-center justify-center text-xs hover:bg-red-600">
                        <i class="fas fa-times"></i>
                    </button>
                    <span class="absolute bottom-1 right-1 bg-black/60 text-white text-[10px] px-1 rounded">
                        ${(file.size / 1024).toFixed(0)}KB
                    </span>
                `;
                preview.appendChild(div);
            };
            reader.readAsDataURL(file);
        });
    }
    
    // Step navigation
    function nextStep(step) {
        // Validate current step
        if (currentStep === 1) {
            if (!validateStep1()) return;
        } else if (currentStep === 2) {
            if (!validateStep2()) return;
        }
        
        if (step === 3) {
            updateSummary();
        }
        
        showStep(step);
    }
    
    function prevStep(step) {
        showStep(step);
    }
    
    function showStep(step) {
        currentStep = step;
        
        // Update step indicators
        document.querySelectorAll('.step-indicator').forEach(ind => {
            const s = parseInt(ind.dataset.step);
            if (s < step) {
                ind.classList.remove('bg-gray-200', 'text-gray-500', 'bg-primary-600', 'text-white');
                ind.classList.add('bg-green-500', 'text-white');
                ind.innerHTML = '<i class="fas fa-check"></i>';
            } else if (s === step) {
                ind.classList.remove('bg-gray-200', 'text-gray-500', 'bg-green-500');
                ind.classList.add('bg-primary-600', 'text-white');
                ind.textContent = s;
            } else {
                ind.classList.remove('bg-primary-600', 'text-white', 'bg-green-500');
                ind.classList.add('bg-gray-200', 'text-gray-500');
                ind.textContent = s;
            }
        });
        
        // Show content
        document.querySelectorAll('.step-content').forEach(content => {
            content.classList.add('hidden');
        });
        document.getElementById(`step-${step}`).classList.remove('hidden');
    }
    
    function validateStep1() {
        const productId = document.getElementById('loan_product_id').value;
        const collateralName = document.getElementById('collateral_name').value;
        const amount = getNumericValue('requested_loan_amount');
        
        if (!productId) {
            UI.toast('Pilih produk pinjaman', 'warning');
            return false;
        }
        if (!collateralName.trim()) {
            UI.toast('Masukkan nama barang jaminan', 'warning');
            return false;
        }
        if (!amount) {
            UI.toast('Masukkan jumlah pinjaman', 'warning');
            return false;
        }
        
        const product = JSON.parse(document.getElementById('loan_product_id').options[document.getElementById('loan_product_id').selectedIndex].dataset.product);
        if (amount < product.loan_min || amount > product.loan_max) {
            UI.toast(`Jumlah harus antara ${UI.formatCurrency(product.loan_min)} - ${UI.formatCurrency(product.loan_max)}`, 'warning');
            return false;
        }
        
        return true;
    }
    
    function validateStep2() {
        if (uploadedPhotos.length === 0) {
            UI.toast('Upload minimal 1 foto barang', 'warning');
            return false;
        }
        return true;
    }
    
    function updateSummary() {
        const productSelect = document.getElementById('loan_product_id');
        const categorySelect = document.getElementById('collateral_category_id');
        const branchSelect = document.getElementById('preferred_branch_id');
        
        document.getElementById('summary-product').textContent = productSelect.options[productSelect.selectedIndex].text;
        document.getElementById('summary-category').textContent = categorySelect.value ? categorySelect.options[categorySelect.selectedIndex].text : '-';
        document.getElementById('summary-collateral').textContent = document.getElementById('collateral_name').value;
        document.getElementById('summary-amount').textContent = UI.formatCurrency(getNumericValue('requested_loan_amount'));
        document.getElementById('summary-photos').textContent = uploadedPhotos.length + ' foto';
        document.getElementById('summary-branch').textContent = branchSelect.value ? branchSelect.options[branchSelect.selectedIndex].text : 'Tidak dipilih';
    }
    
    // Form submit with progress tracking
    document.getElementById('pawn-form').addEventListener('submit', async function(e) {
        e.preventDefault();
        
        if (!document.getElementById('terms').checked) {
            UI.toast('Setujui syarat dan ketentuan', 'warning');
            return;
        }
        
        const submitBtn = document.getElementById('submit-btn');
        const formError = document.getElementById('form-error');
        const progressDiv = document.getElementById('upload-progress');
        const progressBar = document.getElementById('progress-bar');
        const progressText = document.getElementById('progress-text');
        
        formError.classList.add('hidden');
        progressDiv.classList.remove('hidden');
        submitBtn.disabled = true;
        submitBtn.innerHTML = `
            <svg class="animate-spin -ml-1 mr-2 h-5 w-5 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Mengirim...
        `;
        
        // Build FormData
        const formData = new FormData();
        formData.append('loan_product_id', document.getElementById('loan_product_id').value);
        formData.append('collateral_category_id', document.getElementById('collateral_category_id').value);
        formData.append('collateral_name', document.getElementById('collateral_name').value);
        formData.append('collateral_description', document.getElementById('collateral_description').value);
        formData.append('estimated_value', getNumericValue('estimated_value'));
        formData.append('requested_loan_amount', getNumericValue('requested_loan_amount'));
        formData.append('preferred_branch_id', document.getElementById('preferred_branch_id').value);
        formData.append('customer_notes', document.getElementById('customer_notes').value);
        
        uploadedPhotos.forEach(photo => {
            formData.append('collateral_photos[]', photo);
        });
        
        // Use XMLHttpRequest for progress tracking
        const xhr = new XMLHttpRequest();
        const token = localStorage.getItem('auth_token');
        
        xhr.upload.addEventListener('progress', function(e) {
            if (e.lengthComputable) {
                const percent = Math.round((e.loaded / e.total) * 100);
                progressBar.style.width = percent + '%';
                progressText.textContent = percent + '%';
            }
        });
        
        xhr.addEventListener('load', function() {
            progressDiv.classList.add('hidden');
            
            try {
                const response = JSON.parse(xhr.responseText);
                
                if (xhr.status >= 200 && xhr.status < 300 && response.success) {
                    UI.toast(response.message, 'success');
                    setTimeout(() => {
                        window.location.href = `/customer/pawn-requests/${response.data.request_code}`;
                    }, 1000);
                } else {
                    formError.textContent = response.message || 'Gagal mengirim pengajuan';
                    formError.classList.remove('hidden');
                    
                    if (response.errors) {
                        for (const [field, messages] of Object.entries(response.errors)) {
                            const errorEl = document.getElementById(`${field}-error`);
                            if (errorEl) {
                                errorEl.textContent = messages[0];
                                errorEl.classList.remove('hidden');
                            }
                        }
                    }
                    updateSubmitButton();
                }
            } catch (err) {
                formError.textContent = 'Terjadi kesalahan parsing response';
                formError.classList.remove('hidden');
                updateSubmitButton();
            }
        });
        
        xhr.addEventListener('error', function() {
            progressDiv.classList.add('hidden');
            formError.textContent = 'Gagal menghubungi server. Periksa koneksi internet Anda.';
            formError.classList.remove('hidden');
            updateSubmitButton();
        });
        
        xhr.addEventListener('timeout', function() {
            progressDiv.classList.add('hidden');
            formError.textContent = 'Request timeout. Coba lagi.';
            formError.classList.remove('hidden');
            updateSubmitButton();
        });
        
        xhr.open('POST', '/api/pawn-requests');
        xhr.setRequestHeader('Authorization', 'Bearer ' + token);
        xhr.setRequestHeader('Accept', 'application/json');
        xhr.timeout = 120000; // 2 minutes timeout
        xhr.send(formData);
    });
    
    // Terms checkbox handler
    document.getElementById('terms').addEventListener('change', updateSubmitButton);
    
    function updateSubmitButton() {
        const termsChecked = document.getElementById('terms').checked;
        const submitBtn = document.getElementById('submit-btn');
        
        if (termsChecked) {
            submitBtn.disabled = false;
            submitBtn.classList.remove('bg-gray-300', 'text-gray-500', 'cursor-not-allowed');
            submitBtn.classList.add('bg-green-600', 'hover:bg-green-700', 'text-white');
        } else {
            submitBtn.disabled = true;
            submitBtn.classList.add('bg-gray-300', 'text-gray-500', 'cursor-not-allowed');
            submitBtn.classList.remove('bg-green-600', 'hover:bg-green-700', 'text-white');
        }
        submitBtn.innerHTML = '<i class="fas fa-paper-plane mr-2"></i> Kirim';
    }
    
    // Init
    document.addEventListener('DOMContentLoaded', function() {
        loadProducts();
        loadCategories();
        loadBranches();
    });
</script>
@endpush
