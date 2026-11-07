<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <meta name="theme-color" content="#6366f1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Intira') - Customer App</title>
    
    <!-- Tailwind CSS via CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        primary: {
                            50: '#eef2ff',
                            100: '#e0e7ff',
                            200: '#c7d2fe',
                            300: '#a5b4fc',
                            400: '#818cf8',
                            500: '#6366f1',
                            600: '#4f46e5',
                            700: '#4338ca',
                            800: '#3730a3',
                            900: '#312e81',
                        }
                    }
                }
            }
        }
    </script>
    
    <!-- Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    
    <style>
        * {
            font-family: 'Inter', sans-serif;
        }
        
        /* Hide scrollbar but allow scrolling */
        .no-scrollbar::-webkit-scrollbar {
            display: none;
        }
        .no-scrollbar {
            -ms-overflow-style: none;
            scrollbar-width: none;
        }
        
        /* Loading spinner */
        .spinner {
            border: 3px solid #f3f3f3;
            border-top: 3px solid #6366f1;
            border-radius: 50%;
            width: 24px;
            height: 24px;
            animation: spin 1s linear infinite;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        /* Skeleton loading */
        .skeleton {
            background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
            background-size: 200% 100%;
            animation: shimmer 1.5s infinite;
        }
        
        @keyframes shimmer {
            0% { background-position: 200% 0; }
            100% { background-position: -200% 0; }
        }
        
        /* Toast notification */
        .toast {
            transform: translateX(100%);
            transition: transform 0.3s ease;
        }
        .toast.show {
            transform: translateX(0);
        }
        
        /* Pull to refresh indicator */
        .pull-indicator {
            transition: transform 0.2s ease;
        }
    </style>
    
    @stack('styles')
</head>
<body class="bg-gray-100 min-h-screen">
    <!-- Toast Container -->
    <div id="toast-container" class="fixed top-4 right-4 z-50 space-y-2"></div>
    
    <!-- Loading Overlay -->
    <div id="loading-overlay" class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center hidden">
        <div class="bg-white rounded-lg p-6 flex flex-col items-center">
            <div class="spinner mb-3"></div>
            <span class="text-gray-600 text-sm">Memuat...</span>
        </div>
    </div>
    
    <!-- Main Content -->
    <div id="app" class="max-w-lg mx-auto bg-white min-h-screen shadow-xl relative">
        @yield('content')
    </div>
    
    <!-- Bottom Navigation (for authenticated pages) -->
    @auth
    @yield('bottom-nav')
    @endauth
    
    <!-- API Helper Script -->
    <script>
        // Configuration
        const API_BASE_URL = '{{ url('/api') }}';
        
        // Token management
        const TokenManager = {
            get() {
                return localStorage.getItem('auth_token');
            },
            set(token) {
                localStorage.setItem('auth_token', token);
            },
            remove() {
                localStorage.removeItem('auth_token');
            },
            exists() {
                return !!this.get();
            }
        };
        
        // API Helper
        const api = {
            async request(method, endpoint, data = null, isFormData = false) {
                const headers = {
                    'Accept': 'application/json',
                };
                
                if (!isFormData) {
                    headers['Content-Type'] = 'application/json';
                }
                
                const token = TokenManager.get();
                if (token) {
                    headers['Authorization'] = `Bearer ${token}`;
                }
                
                const options = {
                    method,
                    headers,
                };
                
                if (data) {
                    options.body = isFormData ? data : JSON.stringify(data);
                }
                
                try {
                    const response = await fetch(`${API_BASE_URL}${endpoint}`, options);
                    const result = await response.json();
                    
                    if (response.status === 401) {
                        TokenManager.remove();
                        window.location.href = '{{ route('customer.login') }}';
                        return null;
                    }
                    
                    return {
                        ok: response.ok,
                        status: response.status,
                        data: result
                    };
                } catch (error) {
                    console.error('API Error:', error);
                    return {
                        ok: false,
                        status: 500,
                        data: { success: false, message: 'Koneksi gagal. Silakan coba lagi.' }
                    };
                }
            },
            
            get(endpoint) {
                return this.request('GET', endpoint);
            },
            
            post(endpoint, data, isFormData = false) {
                return this.request('POST', endpoint, data, isFormData);
            },
            
            put(endpoint, data) {
                return this.request('PUT', endpoint, data);
            },
            
            delete(endpoint) {
                return this.request('DELETE', endpoint);
            }
        };
        
        // UI Helpers
        const UI = {
            showLoading() {
                document.getElementById('loading-overlay').classList.remove('hidden');
            },
            
            hideLoading() {
                document.getElementById('loading-overlay').classList.add('hidden');
            },
            
            toast(message, type = 'info') {
                const container = document.getElementById('toast-container');
                const colors = {
                    success: 'bg-green-500',
                    error: 'bg-red-500',
                    warning: 'bg-yellow-500',
                    info: 'bg-primary-500'
                };
                const icons = {
                    success: 'fa-check-circle',
                    error: 'fa-times-circle',
                    warning: 'fa-exclamation-circle',
                    info: 'fa-info-circle'
                };
                
                const toast = document.createElement('div');
                toast.className = `toast ${colors[type]} text-white px-4 py-3 rounded-lg shadow-lg flex items-center space-x-2 min-w-[250px]`;
                toast.innerHTML = `
                    <i class="fas ${icons[type]}"></i>
                    <span class="flex-1">${message}</span>
                    <button onclick="this.parentElement.remove()" class="ml-2">
                        <i class="fas fa-times"></i>
                    </button>
                `;
                
                container.appendChild(toast);
                
                setTimeout(() => toast.classList.add('show'), 10);
                setTimeout(() => {
                    toast.classList.remove('show');
                    setTimeout(() => toast.remove(), 300);
                }, 4000);
            },
            
            formatCurrency(amount) {
                return new Intl.NumberFormat('id-ID', {
                    style: 'currency',
                    currency: 'IDR',
                    minimumFractionDigits: 0,
                    maximumFractionDigits: 0
                }).format(amount);
            },
            
            formatDate(dateString) {
                const date = new Date(dateString);
                return date.toLocaleDateString('id-ID', {
                    day: '2-digit',
                    month: 'short',
                    year: 'numeric'
                });
            },
            
            skeleton(count = 1, height = 'h-4') {
                let html = '';
                for (let i = 0; i < count; i++) {
                    html += `<div class="skeleton ${height} rounded mb-2"></div>`;
                }
                return html;
            }
        };
        
        // Auth check on page load
        document.addEventListener('DOMContentLoaded', function() {
            const publicPages = ['/customer/login', '/customer/register', '/customer/calculator', '/customer/branches'];
            const currentPath = window.location.pathname;
            const isPublicPage = publicPages.some(page => currentPath.startsWith(page));
            
            if (!isPublicPage && !TokenManager.exists()) {
                window.location.href = '{{ route('customer.login') }}';
            }
        });
    </script>
    
    @stack('scripts')
</body>
</html>
