@extends('customer.layouts.app')

@section('title', 'Edit Profil')

@section('content')
    <div class="min-h-screen pb-24">
        <!-- Header -->
        <div class="bg-gradient-to-br from-primary-600 to-primary-800 text-white pt-6 pb-16 px-6">
            <a href="{{ route('customer.profile') }}" class="inline-flex items-center text-white/80 hover:text-white mb-4">
                <i class="fas fa-arrow-left mr-2"></i>
                <span>Kembali</span>
            </a>
            <h1 class="text-xl font-bold">Edit Profil</h1>
            <p class="text-primary-100 text-sm mt-1">Perbarui informasi profil Anda</p>
        </div>

        <!-- Form Card -->
        <div class="px-6 -mt-8">
            <!-- Loading State -->
            <div id="loading-state" class="bg-white rounded-2xl shadow-lg p-6">
                <div class="skeleton h-12 rounded-lg mb-4"></div>
                <div class="skeleton h-12 rounded-lg mb-4"></div>
                <div class="skeleton h-12 rounded-lg mb-4"></div>
                <div class="skeleton h-24 rounded-lg mb-4"></div>
            </div>

            <!-- Form (hidden until loaded) -->
            <div id="form-container" class="hidden bg-white rounded-2xl shadow-lg p-6">
                <form id="profile-form" class="space-y-4">
                    <!-- NIK -->
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">NIK (No. KTP) <span
                                class="text-red-500">*</span></label>
                        <input type="text" name="nik" id="nik" placeholder="16 digit NIK" maxlength="16"
                            pattern="[0-9]{16}"
                            class="w-full px-4 py-3 border border-gray-300 rounded-lg bg-gray-100 text-gray-600 cursor-not-allowed outline-none transition"
                            readonly>
                        <p class="text-xs text-gray-500 mt-1">NIK tidak dapat diubah setelah profil lengkap</p>
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
                            @php
                                $monthlyIncomeOptions = [
                                    '< Rp 3.000.000',
                                    'Rp 3.000.000 - 5.000.000',
                                    'Rp 5.000.000 - 10.000.000',
                                    'Rp 10.000.000 - 20.000.000',
                                    '> Rp 20.000.000',
                                ];
                            @endphp
                            <select name="monthly_income" id="monthly_income"
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition">
                                <option value="">Pilih Kisaran Penghasilan</option>
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
                        class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg text-sm hidden"></div>

                    <!-- Submit Button -->
                    <button type="submit" id="submit-btn"
                        class="w-full bg-primary-600 hover:bg-primary-700 text-white font-semibold py-3 rounded-lg transition flex items-center justify-center space-x-2">
                        <i class="fas fa-save mr-2"></i>
                        <span>Simpan Perubahan</span>
                    </button>
                </form>
            </div>
        </div>
    </div>

    <!-- Bottom Navigation -->
    @include('customer.partials.bottom-nav', ['active' => 'profile'])
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

        // Location helpers
        async function loadProvinces(selectedCode = null) {
            const response = await api.get('/locations/provinces');
            if (response.ok && response.data.success) {
                const select = document.getElementById('province_code');
                response.data.data.forEach(province => {
                    const option = document.createElement('option');
                    option.value = province.code;
                    option.textContent = province.name;
                    if (selectedCode && province.code === selectedCode) {
                        option.selected = true;
                    }
                    select.appendChild(option);
                });
            }
        }

        async function loadCities(provinceCode, selectedCode = null) {
            const citySelect = document.getElementById('city_code');
            citySelect.innerHTML = '<option value="">Pilih Kota/Kabupaten</option>';
            citySelect.disabled = true;

            if (provinceCode) {
                const response = await api.get(`/locations/cities/${provinceCode}`);
                if (response.ok && response.data.success) {
                    response.data.data.forEach(city => {
                        const option = document.createElement('option');
                        option.value = city.code;
                        option.textContent = city.name;
                        if (selectedCode && city.code === selectedCode) {
                            option.selected = true;
                        }
                        citySelect.appendChild(option);
                    });
                    citySelect.disabled = false;
                }
            }
        }

        async function loadDistricts(cityCode, selectedCode = null) {
            const districtSelect = document.getElementById('district_code');
            districtSelect.innerHTML = '<option value="">Pilih Kecamatan</option>';
            districtSelect.disabled = true;

            if (cityCode) {
                const response = await api.get(`/locations/districts/${cityCode}`);
                if (response.ok && response.data.success) {
                    response.data.data.forEach(district => {
                        const option = document.createElement('option');
                        option.value = district.code;
                        option.textContent = district.name;
                        if (selectedCode && district.code === selectedCode) {
                            option.selected = true;
                        }
                        districtSelect.appendChild(option);
                    });
                    districtSelect.disabled = false;
                }
            }
        }

        async function loadVillages(districtCode, selectedCode = null) {
            const villageSelect = document.getElementById('village_code');
            villageSelect.innerHTML = '<option value="">Pilih Kelurahan/Desa</option>';
            villageSelect.disabled = true;

            if (districtCode) {
                const response = await api.get(`/locations/villages/${districtCode}`);
                if (response.ok && response.data.success) {
                    response.data.data.forEach(village => {
                        const option = document.createElement('option');
                        option.value = village.code;
                        option.textContent = village.name;
                        if (selectedCode && village.code === selectedCode) {
                            option.selected = true;
                        }
                        villageSelect.appendChild(option);
                    });
                    villageSelect.disabled = false;
                }
            }
        }

        // Load existing profile
        async function loadProfile() {
            const response = await api.get('/profile');

            if (response.ok && response.data.success) {
                const data = response.data.data;
                const customer = data.customer || data;

                // Fill basic fields
                document.getElementById('nik').value = customer.nik || '';
                document.getElementById('birth_place').value = customer.birth_place || '';
                document.getElementById('birth_date').value = customer.birth_date || '';
                document.getElementById('phone').value = customer.phone || '';
                document.getElementById('address').value = customer.address || '';
                document.getElementById('occupation').value = customer.occupation || '';
                
                // Monthly income select - find matching option
                const monthlyIncomeSelect = document.getElementById('monthly_income');
                const monthlyIncomeValue = customer.monthly_income || '';
                if (monthlyIncomeValue) {
                    // Try exact match first
                    let found = false;
                    for (let option of monthlyIncomeSelect.options) {
                        if (option.value === monthlyIncomeValue) {
                            option.selected = true;
                            found = true;
                            break;
                        }
                    }
                    // If no exact match, try partial match (in case of formatting differences)
                    if (!found) {
                        const cleanValue = monthlyIncomeValue.replace(/\s+/g, '').toLowerCase();
                        for (let option of monthlyIncomeSelect.options) {
                            if (option.value.replace(/\s+/g, '').toLowerCase() === cleanValue) {
                                option.selected = true;
                                break;
                            }
                        }
                    }
                }
                
                document.getElementById('emergency_contact_name').value = customer.emergency_contact_name || '';
                document.getElementById('emergency_contact_phone').value = customer.emergency_contact_phone || '';
                document.getElementById('emergency_contact_relation').value = customer.emergency_contact_relation || '';

                // Gender
                if (customer.gender) {
                    const genderRadio = document.querySelector(`input[name="gender"][value="${customer.gender}"]`);
                    if (genderRadio) {
                        genderRadio.checked = true;
                        genderRadio.closest('.gender-option').classList.remove('border-gray-300');
                        genderRadio.closest('.gender-option').classList.add('border-primary-500', 'bg-primary-50');
                    }
                }

                // Load location dropdowns with existing data
                await loadProvinces(customer.province_code);

                if (customer.province_code) {
                    await loadCities(customer.province_code, customer.city_code);
                }
                if (customer.city_code) {
                    await loadDistricts(customer.city_code, customer.district_code);
                }
                if (customer.district_code) {
                    await loadVillages(customer.district_code, customer.village_code);
                }

                // Show form
                document.getElementById('loading-state').classList.add('hidden');
                document.getElementById('form-container').classList.remove('hidden');
            } else {
                UI.toast('Gagal memuat profil', 'error');
                setTimeout(() => {
                    window.location.href = '{{ route('customer.profile') }}';
                }, 1500);
            }
        }

        // Province change handler
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
                await loadCities(this.value);
            }
        });

        // City change handler
        document.getElementById('city_code').addEventListener('change', async function() {
            const districtSelect = document.getElementById('district_code');
            const villageSelect = document.getElementById('village_code');

            districtSelect.innerHTML = '<option value="">Pilih Kecamatan</option>';
            villageSelect.innerHTML = '<option value="">Pilih Kelurahan/Desa</option>';

            districtSelect.disabled = true;
            villageSelect.disabled = true;

            if (this.value) {
                await loadDistricts(this.value);
            }
        });

        // District change handler
        document.getElementById('district_code').addEventListener('change', async function() {
            const villageSelect = document.getElementById('village_code');

            villageSelect.innerHTML = '<option value="">Pilih Kelurahan/Desa</option>';
            villageSelect.disabled = true;

            if (this.value) {
                await loadVillages(this.value);
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
                    UI.toast('Profil berhasil diperbarui', 'success');

                    setTimeout(() => {
                        window.location.href = '{{ route('customer.profile') }}';
                    }, 1000);
                } else {
                    formError.textContent = response.data.message || 'Gagal menyimpan profil';
                    formError.classList.remove('hidden');

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

            submitBtn.disabled = false;
            submitBtn.innerHTML = '<i class="fas fa-save mr-2"></i><span>Simpan Perubahan</span>';
        });

        // Init
        document.addEventListener('DOMContentLoaded', loadProfile);
    </script>
@endpush
