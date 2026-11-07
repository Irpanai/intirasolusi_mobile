@extends('customer.layouts.app')

@section('title', 'Login')

@section('content')
<div class="min-h-screen flex flex-col">
    <!-- Header -->
    <div class="bg-gradient-to-br from-primary-600 to-primary-800 text-white pt-12 pb-24 px-6 rounded-b-3xl">
        <div class="text-center">
            <div class="mx-auto mb-4 w-20 h-20 flex items-center justify-center rounded-full shadow-lg">
                <img src="{{ asset('assets/img/onelabs-white.png') }}" class="w-12 h-12" alt="">
            </div>
            <h1 class="text-2xl font-bold">OnePawner App</h1>
            <p class="text-primary-100 text-sm mt-1">
                Masuk untuk melanjutkan ke akun Anda
            </p>
        </div>
    </div>
    
    <!-- Form Card -->
    <div class="flex-1 px-6 -mt-10">
        <div class="bg-white rounded-2xl shadow-lg p-6">
            <h2 class="text-xl font-semibold text-gray-800 mb-6">Masuk ke Akun</h2>
            
            <form id="login-form" class="space-y-4">
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
                            placeholder="••••••••"
                            class="w-full pl-10 pr-12 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
                            required
                        >
                        <button 
                            type="button" 
                            onclick="togglePassword()"
                            class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                        >
                            <i class="fas fa-eye" id="password-toggle-icon"></i>
                        </button>
                    </div>
                    <p class="text-red-500 text-xs mt-1 hidden" id="password-error"></p>
                </div>
                
                <!-- Error Message -->
                <div id="form-error" class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg text-sm hidden">
                </div>
                
                <!-- Submit Button -->
                <button 
                    type="submit" 
                    id="submit-btn"
                    class="w-full bg-primary-600 hover:bg-primary-700 text-white font-semibold py-3 rounded-lg transition flex items-center justify-center space-x-2"
                >
                    <span>Masuk</span>
                    <i class="fas fa-arrow-right"></i>
                </button>
            </form>
            
            <!-- Divider -->
            <div class="relative my-6">
                <div class="absolute inset-0 flex items-center">
                    <div class="w-full border-t border-gray-200"></div>
                </div>
                <div class="relative flex justify-center text-sm">
                    <span class="px-4 bg-white text-gray-500">atau</span>
                </div>
            </div>
            
            <!-- Register Link -->
            <div class="text-center">
                <p class="text-gray-600">
                    Belum punya akun? 
                    <a href="{{ route('customer.register') }}" class="text-primary-600 font-semibold hover:text-primary-700">
                        Daftar Sekarang
                    </a>
                </p>
            </div>
        </div>
        
        <!-- Quick Links -->
        <div class="mt-6 flex justify-center space-x-6 text-sm hidden">
            <a href="{{ route('customer.calculator') }}" class="text-gray-500 hover:text-primary-600">
                <i class="fas fa-calculator mr-1"></i> Kalkulator
            </a>
            <a href="{{ route('customer.branches.index') }}" class="text-gray-500 hover:text-primary-600">
                <i class="fas fa-map-marker-alt mr-1"></i> Cabang
            </a>
        </div>
    </div>
    
    <!-- Footer -->
    <div class="p-6 text-center text-xs text-gray-400">
        &copy; {{ date('Y') }} Made with <i class="fas fa-heart text-red-500"></i> by onelabs.id
    </div>
</div>
@endsection

@push('scripts')
<script>
    function togglePassword() {
        const passwordInput = document.getElementById('password');
        const icon = document.getElementById('password-toggle-icon');
        
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
    
    document.getElementById('login-form').addEventListener('submit', async function(e) {
        e.preventDefault();
        
        const submitBtn = document.getElementById('submit-btn');
        const formError = document.getElementById('form-error');
        
        // Reset errors
        formError.classList.add('hidden');
        document.querySelectorAll('[id$="-error"]').forEach(el => el.classList.add('hidden'));
        
        // Disable button
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<div class="spinner"></div>';
        
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;
        
        try {
            const response = await api.post('/login', { email, password });
            
            if (response.ok && response.data.success) {
                // Save token
                TokenManager.set(response.data.data.token);
                
                UI.toast('Login berhasil!', 'success');
                
                // Redirect based on profile completion
                setTimeout(() => {
                    if (response.data.data.requires_profile_completion) {
                        window.location.href = '{{ route('customer.profile.complete') }}';
                    } else {
                        window.location.href = '{{ route('customer.dashboard') }}';
                    }
                }, 500);
            } else {
                // Show error
                formError.textContent = response.data.message || 'Login gagal';
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
        submitBtn.innerHTML = '<span>Masuk</span><i class="fas fa-arrow-right"></i>';
    });
</script>
@endpush
