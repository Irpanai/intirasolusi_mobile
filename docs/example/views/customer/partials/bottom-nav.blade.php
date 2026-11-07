<!-- Bottom Navigation -->
<div class="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-40">
    <div class="max-w-md mx-auto">
        <div class="grid grid-cols-5 py-2">
            <!-- Beranda -->
            <a href="{{ route('customer.dashboard') }}" class="flex flex-col items-center justify-center py-2 {{ $active === 'home' ? 'text-primary-600' : 'text-gray-400' }}">
                <i class="fas fa-home text-xl"></i>
                <span class="text-xs mt-1">Beranda</span>
            </a>
            <!-- Pengajuan -->
            <a href="{{ route('customer.pawn-requests.index') }}" class="flex flex-col items-center justify-center py-2 {{ $active === 'requests' ? 'text-primary-600' : 'text-gray-400' }}">
                <i class="fas fa-file-alt text-xl"></i>
                <span class="text-xs mt-1">Pengajuan</span>
            </a>
            <!-- Create Button (Center) -->
            <a href="{{ route('customer.pawn-requests.create') }}" class="flex items-center justify-center">
                <div class="w-14 h-14 bg-primary-600 rounded-full flex items-center justify-center shadow-lg -mt-6">
                    <i class="fas fa-plus text-white text-xl"></i>
                </div>
            </a>
            <!-- Transaksi -->
            <a href="{{ route('customer.transactions.index') }}" class="flex flex-col items-center justify-center py-2 {{ $active === 'transactions' ? 'text-primary-600' : 'text-gray-400' }}">
                <i class="fas fa-receipt text-xl"></i>
                <span class="text-xs mt-1">Transaksi</span>
            </a>
            <!-- Profil -->
            <a href="{{ route('customer.profile') }}" class="flex flex-col items-center justify-center py-2 {{ $active === 'profile' ? 'text-primary-600' : 'text-gray-400' }}">
                <i class="fas fa-user text-xl"></i>
                <span class="text-xs mt-1">Profil</span>
            </a>
        </div>
    </div>
</div>
