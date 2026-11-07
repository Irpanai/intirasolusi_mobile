# API Change Password

## Endpoint

```
POST /api/profile/change-password
```

## Headers

| Header | Value | Required |
|--------|-------|----------|
| Content-Type | application/json | Yes |
| Accept | application/json | Yes |
| Authorization | Bearer {token} | Yes |

## Request Body

```json
{
  "current_password": "string",
  "new_password": "string",
  "new_password_confirmation": "string"
}
```

### Parameters

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| current_password | string | Yes | Must match current user password |
| new_password | string | Yes | Min 6 characters |
| new_password_confirmation | string | Yes | Must match new_password |

## Responses

### Success (200 OK)

```json
{
  "success": true,
  "message": "Password berhasil diubah"
}
```

### Validation Error (422 Unprocessable Entity)

**Password lama salah:**
```json
{
  "success": false,
  "message": "Password saat ini tidak sesuai",
  "errors": {
    "current_password": ["Password saat ini tidak sesuai"]
  }
}
```

**Password baru terlalu pendek:**
```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "new_password": ["Password minimal 6 karakter"]
  }
}
```

**Konfirmasi password tidak cocok:**
```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "new_password_confirmation": ["Konfirmasi password tidak cocok"]
  }
}
```

### Unauthorized (401)

```json
{
  "success": false,
  "message": "Unauthenticated"
}
```

### Server Error (500)

```json
{
  "success": false,
  "message": "Terjadi kesalahan pada server"
}
```

## Example Request

### cURL

```bash
curl -X POST https://intirasolusi.id/api/profile/change-password \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." \
  -d '{
    "current_password": "password123",
    "new_password": "newpassword456",
    "new_password_confirmation": "newpassword456"
  }'
```

### JavaScript (Fetch)

```javascript
const response = await fetch('https://intirasolusi.id/api/profile/change-password', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    current_password: 'password123',
    new_password: 'newpassword456',
    new_password_confirmation: 'newpassword456'
  })
});

const data = await response.json();
```

## Laravel Backend Implementation

### Route

```php
// routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/profile/change-password', [ProfileController::class, 'changePassword']);
});
```

### Controller

```php
// app/Http/Controllers/Api/ProfileController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class ProfileController extends Controller
{
    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => ['required', 'current_password'],
            'new_password' => ['required', 'min:6', 'confirmed'],
        ], [
            'current_password.current_password' => 'Password saat ini tidak sesuai',
            'new_password.min' => 'Password minimal 6 karakter',
            'new_password.confirmed' => 'Konfirmasi password tidak cocok',
        ]);

        $user = $request->user();
        $user->update([
            'password' => Hash::make($request->new_password)
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil diubah'
        ]);
    }
}
```

### Form Request (Optional)

```php
// app/Http/Requests/ChangePasswordRequest.php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ChangePasswordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'current_password' => ['required', 'current_password'],
            'new_password' => ['required', 'min:6', 'confirmed'],
        ];
    }

    public function messages(): array
    {
        return [
            'current_password.required' => 'Password saat ini wajib diisi',
            'current_password.current_password' => 'Password saat ini tidak sesuai',
            'new_password.required' => 'Password baru wajib diisi',
            'new_password.min' => 'Password minimal 6 karakter',
            'new_password.confirmed' => 'Konfirmasi password tidak cocok',
        ];
    }
}
```

## Notes

1. **Security**: Selalu gunakan HTTPS untuk request yang mengandung password
2. **Token**: Token didapat dari response login/register
3. **Rate Limiting**: Disarankan untuk menambahkan rate limiting pada endpoint ini untuk mencegah brute force
4. **Logging**: Log semua aktivitas perubahan password untuk audit trail
5. **Notification**: Opsional - kirim email notifikasi ke user setelah password berubah

## Mobile App Integration

File terkait di Flutter app:
- `lib/core/constants/api_endpoints.dart` - Endpoint definition
- `lib/data/datasources/remote/auth_remote_datasource.dart` - API call implementation
- `lib/data/repositories/auth_repository.dart` - Repository method
- `lib/presentation/screens/profile/change_password_screen.dart` - UI Screen
