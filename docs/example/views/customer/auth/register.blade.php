@extends('customer.layouts.app')

@section('title', 'Daftar')

@section('content')
<div class="min-h-screen flex flex-col">
    <!-- Header -->
    <div class="bg-gradient-to-br from-primary-600 to-primary-800 text-white pt-8 pb-16 px-6 rounded-b-3xl">
        <a href="{{ route('customer.login') }}" class="inline-flex items-center text-white/80 hover:text-white mb-4">
            <i class="fas fa-arrow-left mr-2"></i>
            <span>Kembali</span>
        </a>
        <div class="text-center">
            <h1 class="text-2xl font-bold">Daftar Akun</h1>
            <p class="text-primary-100 text-sm mt-1">Buat akun untuk mulai gadai online</p>
        </div>
    </div>
    
    <!-- Form Card -->
    <div class="flex-1 px-6 -mt-8">
        <div class="bg-white rounded-2xl shadow-lg p-6">
            <!-- Progress -->
            <div class="flex items-center justify-center mb-6">
                <div class="flex items-center">
                    <div class="w-8 h-8 rounded-full bg-primary-600 text-white flex items-center justify-center text-sm font-semibold">1</div>
                    <span class="ml-2 text-sm font-medium text-gray-700">Buat Akun</span>
                </div>
                <div class="w-12 h-0.5 bg-gray-200 mx-3"></div>
                <div class="flex items-center">
                    <div class="w-8 h-8 rounded-full bg-gray-200 text-gray-500 flex items-center justify-center text-sm font-semibold">2</div>
                    <span class="ml-2 text-sm text-gray-400">Lengkapi Profil</span>
                </div>
            </div>
            
            <form id="register-form" class="space-y-4">
                <!-- Name -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Nama Lengkap</label>
                    <div class="relative">
                        <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
                            <i class="fas fa-user"></i>
                        </span>
                        <input 
                            type="text" 
                            name="name" 
                            id="name"
                            placeholder="John Doe"
                            class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                            required
                        >
                    </div>
                    <p class="text-red-500 text-xs mt-1 hidden" id="name-error"></p>
                </div>
                
                <!-- Email -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                    <div class="relative">
                        <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
                            <i class="fas fa-envelope"></i>
                        </span>
                        <input 
                            type="email" 
                            name="email" 
                            id="email"
                            placeholder="email@example.com"
                            class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                            required
                        >
                    </div>
                    <p class="text-red-500 text-xs mt-1 hidden" id="email-error"></p>
                </div>
                
                <!-- Phone -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">No. Handphone</label>
                    <div class="relative">
                        <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
                            <i class="fas fa-phone"></i>
                        </span>
                        <input 
                            type="tel" 
                            name="phone" 
                            id="phone"
                            placeholder="08123456789"
                            class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                            required
                        >
                    </div>
                    <p class="text-red-500 text-xs mt-1 hidden" id="phone-error"></p>
                </div>
                
                <!-- Password -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                    <div class="relative">
                        <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
                            <i class="fas fa-lock"></i>
                        </span>
                        <input 
                            type="password" 
                            name="password" 
                            id="password"
                            placeholder="Min. 8 karakter"
                            class="w-full pl-10 pr-12 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                            required
                            minlength="8"
                        >
                        <button 
                            type="button" 
                            onclick="togglePassword('password')"
                            class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                        >
                            <i class="fas fa-eye" id="password-toggle-icon"></i>
                        </button>
                    </div>
                    <p class="text-red-500 text-xs mt-1 hidden" id="password-error"></p>
                </div>
                
                <!-- Confirm Password -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Konfirmasi Password</label>
                    <div class="relative">
                        <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
                            <i class="fas fa-lock"></i>
                        </span>
                        <input 
                            type="password" 
                            name="password_confirmation" 
                            id="password_confirmation"
                            placeholder="Ulangi password"
                            class="w-full pl-10 pr-12 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                            required
                        >
                        <button 
                            type="button" 
                            onclick="togglePassword('password_confirmation')"
                            class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                        >
                            <i class="fas fa-eye" id="password_confirmation-toggle-icon"></i>
                        </button>
                    </div>
                    <p class="text-red-500 text-xs mt-1 hidden" id="password_confirmation-error"></p>
                </div>
                
                <!-- Error Message -->
                <div id="form-error" class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg text-sm hidden">
                </div>
                
                <!-- Terms -->
                <div class="flex items-start space-x-2">
                    <input type="checkbox" id="terms" required class="mt-1 rounded border-gray-300 text-primary-600 focus:ring-primary-500">
                    <label for="terms" class="text-sm text-gray-600">
                        Saya menyetujui <a href="#" class="text-primary-600">Syarat & Ketentuan</a> serta <a href="#" class="text-primary-600">Kebijakan Privasi</a>
                    </label>
                </div>
                
                <!-- Submit Button -->
                <button 
                    type="submit" 
                    id="submit-btn"
                    class="w-full bg-primary-600 hover:bg-primary-700 text-white font-semibold py-3 rounded-lg transition flex items-center justify-center space-x-2"
                >
                    <span>Daftar</span>
                    <i class="fas fa-arrow-right"></i>
                </button>
            </form>
            
            <!-- Login Link -->
            <div class="mt-6 text-center">
                <p class="text-gray-600">
                    Sudah punya akun? 
                    <a href="{{ route('customer.login') }}" class="text-primary-600 font-semibold hover:text-primary-700">
                        Masuk
                    </a>
                </p>
            </div>
        </div>
    </div>
    
    <!-- Footer -->
    <div class="p-6 text-center text-xs text-gray-400">
        &copy; {{ date('Y') }} Intira. All rights reserved.
    </div>
</div>
@endsection

@push('scripts')
<script>
    function togglePassword(fieldId) {
        const passwordInput = document.getElementById(fieldId);
        const icon = document.getElementById(`${fieldId}-toggle-icon`);
        
        if (passwordInput.type === 'password') {
            passwordInput.type = 'text';
            icon.classList.remove('fa-eye');
            icon.classList.add('fa-eye-slash');
        } else {
            passwordInput.type = 'password';
            icon.classList.remove('fa-eye-slash');
            icon.classList.add('fa-eye');
        }
    }
    
    document.getElementById('register-form').addEventListener('submit', async function(e) {
        e.preventDefault();
        
        const submitBtn = document.getElementById('submit-btn');
        const formError = document.getElementById('form-error');
        
        // Reset errors
        formError.classList.add('hidden');
        document.querySelectorAll('[id$="-error"]').forEach(el => el.classList.add('hidden'));
        
        // Validate password confirmation
        const password = document.getElementById('password').value;
        const passwordConfirmation = document.getElementById('password_confirmation').value;
        
        if (password !== passwordConfirmation) {
            const errorEl = document.getElementById('password_confirmation-error');
            errorEl.textContent = 'Password tidak sama';
            errorEl.classList.remove('hidden');
            return;
        }
        
        // Disable button
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<div class="spinner"></div>';
        
        const data = {
            name: document.getElementById('name').value,
            email: document.getElementById('email').value,
            phone: document.getElementById('phone').value,
            password: password,
            password_confirmation: passwordConfirmation
        };
        
        try {
            const response = await api.post('/register', data);
            
            if (response.ok && response.data.success) {
                // Save token
                TokenManager.set(response.data.data.token);
                
                UI.toast('Registrasi berhasil!', 'success');
                
                // Redirect to complete profile
                setTimeout(() => {
                    window.location.href = '{{ route('customer.profile.complete') }}';
                }, 500);
            } else {
                // Show error
                formError.textContent = response.data.message || 'Registrasi gagal';
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
        submitBtn.innerHTML = '<span>Daftar</span><i class="fas fa-arrow-right"></i>';
    });
</script>
@endpush
