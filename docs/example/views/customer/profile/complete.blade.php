@extends('customer.layouts.app')

@section('title', 'Lengkapi Profil')

@section('content')
    <div class="min-h-screen pb-6">
        <!-- Header -->
        <div class="bg-gradient-to-br from-primary-600 to-primary-800 text-white pt-6 pb-16 px-6 rounded-b-3xl">
            <a href="{{ route('customer.dashboard') }}" class="inline-flex items-center text-white/80 hover:text-white mb-4">
                <i class="fas fa-arrow-left mr-2"></i>
                <span>Kembali</span>
            </a>

            <!-- Progress -->
            <div class="flex items-center justify-center mb-4">
                <div class="flex items-center">
                    <div class="w-8 h-8 rounded-full bg-white/30 text-white flex items-center justify-center text-sm">
                        <i class="fas fa-check"></i>
                    </div>
                    <span class="ml-2 text-sm text-primary-100">Buat Akun</span>
                </div>
                <div class="w-8 h-0.5 bg-white/30 mx-2"></div>
                <div class="flex items-center">
                    <div
                        class="w-8 h-8 rounded-full bg-white text-primary-600 flex items-center justify-center text-sm font-semibold">
                        2</div>
                    <span class="ml-2 text-sm font-medium">Lengkapi Profil</span>
                </div>
            </div>

            <div class="text-center">
                <h1 class="text-xl font-bold">Lengkapi Data Diri</h1>
                <p class="text-primary-100 text-sm mt-1">Data ini diperlukan untuk proses gadai</p>
            </div>
        </div>

        <!-- Form Card -->
        <div class="px-6 -mt-8">
            <div class="bg-white rounded-2xl shadow-lg p-6">
                <form id="profile-form" class="space-y-4">
                    <!-- NIK -->
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">NIK (No. KTP) <span
                                class="text-red-500">*</span></label>
                        <input type="text" name="nik" id="nik" placeholder="16 digit NIK" maxlength="16"
                            pattern="[0-9]{16}"
                            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                            required>
                        <p class="text-red-500 text-xs mt-1 hidden" id="nik-error"></p>
                    </div>

                    <!-- Birth Place & Date -->
                    <div class="grid grid-cols-2 gap-3">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Tempat Lahir <span
                                    class="text-red-500">*</span></label>
                            <input type="text" name="birth_place" id="birth_place" placeholder="Kota"
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                                required>
                            <p class="text-red-500 text-xs mt-1 hidden" id="birth_place-error"></p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Tanggal Lahir <span
                                    class="text-red-500">*</span></label>
                            <input type="date" name="birth_date" id="birth_date"
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                                required>
                            <p class="text-red-500 text-xs mt-1 hidden" id="birth_date-error"></p>
                        </div>
                    </div>

                    <!-- Gender -->
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Jenis Kelamin <span
                                class="text-red-500">*</span></label>
                        <div class="grid grid-cols-2 gap-3">
                            <label
                                class="flex items-center justify-center p-3 border border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50 transition gender-option">
                                <input type="radio" name="gender" value="L" class="hidden" required>
                                <i class="fas fa-male text-blue-500 mr-2"></i>
                                <span>Laki-laki</span>
                            </label>
                            <label
                                class="flex items-center justify-center p-3 border border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50 transition gender-option">
                                <input type="radio" name="gender" value="P" class="hidden">
                                <i class="fas fa-female text-pink-500 mr-2"></i>
                                <span>Perempuan</span>
                            </label>
                        </div>
                        <p class="text-red-500 text-xs mt-1 hidden" id="gender-error"></p>
                    </div>

                    <!-- Phone -->
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">No. Handphone <span
                                class="text-red-500">*</span></label>
                        <input type="tel" name="phone" id="phone" placeholder="08123456789"
                            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                            required>
                        <p class="text-red-500 text-xs mt-1 hidden" id="phone-error"></p>
                    </div>

                    <!-- Address Section -->
                    <div class="border-t border-gray-200 pt-4 mt-4">
                        <h3 class="font-semibold text-gray-800 mb-3">
                            <i class="fas fa-map-marker-alt text-primary-600 mr-2"></i>
                            Alamat
                        </h3>

                        <!-- Province -->
                        <div class="mb-3">
                            <label class="block text-sm font-medium text-gray-700 mb-1">Provinsi <span
                                    class="text-red-500">*</span></label>
                            <select name="province_code" id="province_code"
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                                required>
                                <option value="">Pilih Provinsi</option>
                            </select>
                            <p class="text-red-500 text-xs mt-1 hidden" id="province_code-error"></p>
                        </div>

                        <!-- City -->
                        <div class="mb-3">
                            <label class="block text-sm font-medium text-gray-700 mb-1">Kota/Kabupaten <span
                                    class="text-red-500">*</span></label>
                            <select name="city_code" id="city_code"
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                                required disabled>
                                <option value="">Pilih Kota/Kabupaten</option>
                            </select>
                            <p class="text-red-500 text-xs mt-1 hidden" id="city_code-error"></p>
                        </div>

                        <!-- District -->
                        <div class="mb-3">
                            <label class="block text-sm font-medium text-gray-700 mb-1">Kecamatan <span
                                    class="text-red-500">*</span></label>
                            <select name="district_code" id="district_code"
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                                required disabled>
                                <option value="">Pilih Kecamatan</option>
                            </select>
                            <p class="text-red-500 text-xs mt-1 hidden" id="district_code-error"></p>
                        </div>

                        <!-- Village -->
                        <div class="mb-3">
                            <label class="block text-sm font-medium text-gray-700 mb-1">Kelurahan/Desa <span
                                    class="text-red-500">*</span></label>
                            <select name="village_code" id="village_code"
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                                required disabled>
                                <option value="">Pilih Kelurahan/Desa</option>
                            </select>
                            <p class="text-red-500 text-xs mt-1 hidden" id="village_code-error"></p>
                        </div>

                        <!-- Full Address -->
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Alamat Lengkap <span
                                    class="text-red-500">*</span></label>
                            <textarea name="address" id="address" rows="3" placeholder="Jl. Nama Jalan No. XX, RT/RW ..."
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition resize-none"
                                required></textarea>
                            <p class="text-red-500 text-xs mt-1 hidden" id="address-error"></p>
                        </div>
                    </div>

                    <!-- Additional Info -->
                    <div class="border-t border-gray-200 pt-4 mt-4">
                        <h3 class="font-semibold text-gray-800 mb-3">
                            <i class="fas fa-briefcase text-primary-600 mr-2"></i>
                            Informasi Tambahan
                        </h3>

                        <!-- Occupation -->
                        <div class="mb-3">
                            <label class="block text-sm font-medium text-gray-700 mb-1">Pekerjaan</label>
                            <input type="text" name="occupation" id="occupation"
                                placeholder="Karyawan Swasta, Wiraswasta, dll"
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition">
                        </div>

                        <!-- Monthly Income -->
                        <div class="mb-3">
                            <label class="block text-sm font-medium text-gray-700 mb-1">Penghasilan Bulanan</label>
                            <select name="monthly_income" id="monthly_income"
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition">
                                @php
                                    $monthlyIncomeOptions = [
                                        '< Rp 3.000.000',
                                        'Rp 3.000.000 - 5.000.000',
                                        'Rp 5.000.000 - 10.000.000',
                                        'Rp 10.000.000 - 20.000.000',
                                        '> Rp 20.000.000',
                                    ];
                                @endphp
                                <option value="">Pilih Penghasilan</option>
                                @foreach ($monthlyIncomeOptions as $option)
                                    <option value="{{ $option }}">{{ $option }}</option>
                                @endforeach
                            </select>
                        </div>
                    </div>

                    <!-- Emergency Contact -->
                    <div class="border-t border-gray-200 pt-4 mt-4">
                        <h3 class="font-semibold text-gray-800 mb-3">
                            <i class="fas fa-phone-alt text-primary-600 mr-2"></i>
                            Kontak Darurat
                        </h3>

                        <div class="grid grid-cols-2 gap-3 mb-3">
                            <div>
                                <label class="block text-sm font-medium text-gray-700 mb-1">Nama</label>
                                <input type="text" name="emergency_contact_name" id="emergency_contact_name"
                                    placeholder="Nama lengkap"
                                    class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition">
                            </div>
                            <div>
                                <label class="block text-sm font-medium text-gray-700 mb-1">Hubungan</label>
                                <input type="text" name="emergency_contact_relation" id="emergency_contact_relation"
                                    placeholder="Suami, Istri, dll"
                                    class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition">
                            </div>
                        </div>

                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">No. Telepon</label>
                            <input type="tel" name="emergency_contact_phone" id="emergency_contact_phone"
                                placeholder="08123456789"
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition">
                        </div>
                    </div>

                    <!-- Error Message -->
                    <div id="form-error"
                        class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg text-sm hidden">
                    </div>

                    <!-- Submit Button -->
                    <button type="submit" id="submit-btn"
                        class="w-full bg-primary-600 hover:bg-primary-700 text-white font-semibold py-3 rounded-lg transition flex items-center justify-center space-x-2">
                        <span>Simpan & Lanjutkan</span>
                        <i class="fas fa-arrow-right"></i>
                    </button>
                </form>
            </div>
        </div>
    </div>
@endsection

@push('scripts')
    <script>
        // Gender selection
        document.querySelectorAll('.gender-option').forEach(option => {
            option.addEventListener('click', function() {
                document.querySelectorAll('.gender-option').forEach(o => {
                    o.classList.remove('border-primary-500', 'bg-primary-50');
                    o.classList.add('border-gray-300');
                });
                this.classList.remove('border-gray-300');
                this.classList.add('border-primary-500', 'bg-primary-50');
            });
        });

        // Load provinces on page load
        async function loadProvinces() {
            const response = await api.get('/locations/provinces');
            if (response.ok && response.data.success) {
                const select = document.getElementById('province_code');
                response.data.data.forEach(province => {
                    const option = document.createElement('option');
                    option.value = province.code;
                    option.textContent = province.name;
                    select.appendChild(option);
                });
            }
        }

        // Load cities when province changes
        document.getElementById('province_code').addEventListener('change', async function() {
            const citySelect = document.getElementById('city_code');
            const districtSelect = document.getElementById('district_code');
            const villageSelect = document.getElementById('village_code');

            citySelect.innerHTML = '<option value="">Pilih Kota/Kabupaten</option>';
            districtSelect.innerHTML = '<option value="">Pilih Kecamatan</option>';
            villageSelect.innerHTML = '<option value="">Pilih Kelurahan/Desa</option>';

            citySelect.disabled = true;
            districtSelect.disabled = true;
            villageSelect.disabled = true;

            if (this.value) {
                const response = await api.get(`/locations/cities/${this.value}`);
                if (response.ok && response.data.success) {
                    response.data.data.forEach(city => {
                        const option = document.createElement('option');
                        option.value = city.code;
                        option.textContent = city.name;
                        citySelect.appendChild(option);
                    });
                    citySelect.disabled = false;
                }
            }
        });

        // Load districts when city changes
        document.getElementById('city_code').addEventListener('change', async function() {
            const districtSelect = document.getElementById('district_code');
            const villageSelect = document.getElementById('village_code');

            districtSelect.innerHTML = '<option value="">Pilih Kecamatan</option>';
            villageSelect.innerHTML = '<option value="">Pilih Kelurahan/Desa</option>';

            districtSelect.disabled = true;
            villageSelect.disabled = true;

            if (this.value) {
                const response = await api.get(`/locations/districts/${this.value}`);
                if (response.ok && response.data.success) {
                    response.data.data.forEach(district => {
                        const option = document.createElement('option');
                        option.value = district.code;
                        option.textContent = district.name;
                        districtSelect.appendChild(option);
                    });
                    districtSelect.disabled = false;
                }
            }
        });

        // Load villages when district changes
        document.getElementById('district_code').addEventListener('change', async function() {
            const villageSelect = document.getElementById('village_code');

            villageSelect.innerHTML = '<option value="">Pilih Kelurahan/Desa</option>';
            villageSelect.disabled = true;

            if (this.value) {
                const response = await api.get(`/locations/villages/${this.value}`);
                if (response.ok && response.data.success) {
                    response.data.data.forEach(village => {
                        const option = document.createElement('option');
                        option.value = village.code;
                        option.textContent = village.name;
                        villageSelect.appendChild(option);
                    });
                    villageSelect.disabled = false;
                }
            }
        });

        // Form submit
        document.getElementById('profile-form').addEventListener('submit', async function(e) {
            e.preventDefault();

            const submitBtn = document.getElementById('submit-btn');
            const formError = document.getElementById('form-error');

            // Reset errors
            formError.classList.add('hidden');
            document.querySelectorAll('[id$="-error"]').forEach(el => el.classList.add('hidden'));

            // Disable button
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<div class="spinner"></div>';

            const data = {
                nik: document.getElementById('nik').value,
                birth_place: document.getElementById('birth_place').value,
                birth_date: document.getElementById('birth_date').value,
                gender: document.querySelector('input[name="gender"]:checked')?.value,
                phone: document.getElementById('phone').value,
                province_code: document.getElementById('province_code').value,
                city_code: document.getElementById('city_code').value,
                district_code: document.getElementById('district_code').value,
                village_code: document.getElementById('village_code').value,
                address: document.getElementById('address').value,
                occupation: document.getElementById('occupation').value,
                monthly_income: document.getElementById('monthly_income').value,
                emergency_contact_name: document.getElementById('emergency_contact_name').value,
                emergency_contact_phone: document.getElementById('emergency_contact_phone').value,
                emergency_contact_relation: document.getElementById('emergency_contact_relation').value,
            };

            try {
                const response = await api.put('/profile', data);

                if (response.ok && response.data.success) {
                    UI.toast(response.data.message, 'success');

                    // Redirect to dashboard
                    setTimeout(() => {
                        window.location.href = '{{ route('customer.dashboard') }}';
                    }, 1000);
                } else {
                    // Show error
                    formError.textContent = response.data.message || 'Gagal menyimpan profil';
                    formError.classList.remove('hidden');

                    // Show validation errors
                    if (response.data.errors) {
                        for (const [field, messages] of Object.entries(response.data.errors)) {
                            const errorEl = document.getElementById(`${field}-error`);
                            if (errorEl) {
                                errorEl.textContent = messages[0];
                                errorEl.classList.remove('hidden');
                            }
                        }
                    }
                }
            } catch (error) {
                formError.textContent = 'Terjadi kesalahan. Silakan coba lagi.';
                formError.classList.remove('hidden');
            }

            // Re-enable button
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<span>Simpan & Lanjutkan</span><i class="fas fa-arrow-right"></i>';
        });

        // Load provinces on page load
        document.addEventListener('DOMContentLoaded', loadProvinces);
    </script>
@endpush
