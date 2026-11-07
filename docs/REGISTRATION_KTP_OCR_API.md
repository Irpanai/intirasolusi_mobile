# Registration Flow dengan KTP OCR - API Requirements

## Ringkasan Perubahan

Alur registrasi baru menggunakan KTP OCR (Google ML Kit on-device) untuk auto-fill data.
**Tanpa face comparison** - foto selfie hanya untuk dokumentasi.

## Alur Registrasi Baru (Mobile)

```
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: Email & Password                                       │
│  - Input: email, password, password_confirmation                │
│  - Tidak perlu no HP                                            │
└─────────────────────────┬───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: Scan KTP (On-Device OCR)                               │
│  - Buka kamera untuk capture KTP                                │
│  - OCR langsung di device (Google ML Kit) - GRATIS              │
│  - Auto-fill: NIK, Nama, TTL, Alamat, dst                       │
│  - Foto KTP disimpan untuk upload                               │
└─────────────────────────┬───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: Foto Selfie                                            │
│  - Capture foto wajah dengan kamera depan                       │
│  - Hanya untuk dokumentasi (tanpa face matching)                │
│  - Foto selfie disimpan untuk upload                            │
└─────────────────────────┬───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: Review & Lengkapi Data                                 │
│  - Tampilkan hasil OCR dari KTP                                 │
│  - User dapat koreksi jika ada kesalahan OCR                    │
│  - Input data tambahan (phone optional)                         │
└─────────────────────────┬───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 5: Submit Registrasi                                      │
│  - Upload foto KTP + selfie ke server                           │
│  - Kirim semua data ke backend                                  │
│  - Return: user data + token                                    │
└─────────────────────────────────────────────────────────────────┘
```

## Teknologi yang Digunakan

| Komponen | Teknologi | Biaya |
|----------|-----------|-------|
| OCR KTP | Google ML Kit (on-device) | **GRATIS** |
| Face Detection | Google ML Kit (on-device) | **GRATIS** |
| Face Comparison | Tidak digunakan | - |
| Storage | Server Laravel | Existing |

---

## API Endpoint

Karena OCR dilakukan di device (Google ML Kit), backend hanya perlu **1 endpoint** untuk registrasi.

### POST /api/register

Endpoint untuk registrasi dengan upload foto KTP dan selfie.

**Headers:**
```
Content-Type: multipart/form-data
```

**Request (multipart/form-data):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | String | Yes | Email user (unique) |
| password | String | Yes | Password (min 8 char) |
| password_confirmation | String | Yes | Konfirmasi password |
| ktp_image | File | Yes | Foto KTP (JPEG/PNG, max 5MB) |
| selfie_image | File | Yes | Foto Selfie (JPEG/PNG, max 5MB) |
| nik | String | Yes | NIK 16 digit (hasil OCR di device) |
| name | String | Yes | Nama lengkap sesuai KTP |
| birth_place | String | Yes | Tempat lahir |
| birth_date | String | Yes | Tanggal lahir (YYYY-MM-DD) |
| gender | String | Yes | male / female |
| address | String | Yes | Alamat sesuai KTP |
| rt_rw | String | No | RT/RW |
| village | String | No | Kelurahan/Desa |
| district | String | No | Kecamatan |
| city | String | No | Kabupaten/Kota |
| province | String | No | Provinsi |
| religion | String | No | Agama |
| marital_status | String | No | Status perkawinan |
| occupation | String | No | Pekerjaan |
| phone | String | No | Nomor HP (opsional) |
| agree_terms | Boolean | Yes | Persetujuan S&K (true) |

**Request Example (cURL):**
```bash
curl -X POST https://api.example.com/api/register \
  -H "Content-Type: multipart/form-data" \
  -F "email=john.doe@email.com" \
  -F "password=SecureP@ss123" \
  -F "password_confirmation=SecureP@ss123" \
  -F "ktp_image=@/path/to/ktp.jpg" \
  -F "selfie_image=@/path/to/selfie.jpg" \
  -F "nik=3275012345670001" \
  -F "name=JOHN DOE" \
  -F "birth_place=JAKARTA" \
  -F "birth_date=1990-05-15" \
  -F "gender=male" \
  -F "address=JL. MERDEKA NO. 123" \
  -F "rt_rw=001/002" \
  -F "village=SUKAMAJU" \
  -F "district=CILANDAK" \
  -F "city=JAKARTA SELATAN" \
  -F "province=DKI JAKARTA" \
  -F "phone=081234567890" \
  -F "agree_terms=true"
```

**Response Success (201):**
```json
{
  "success": true,
  "message": "Registrasi berhasil",
  "data": {
    "user": {
      "id": 123,
      "name": "JOHN DOE",
      "email": "john.doe@email.com",
      "phone": "081234567890",
      "email_verified_at": null,
      "created_at": "2026-02-18T10:30:00.000000Z"
    },
    "customer": {
      "id": 456,
      "customer_code": "CST-20260218-0001",
      "nik": "3275012345670001",
      "name": "JOHN DOE",
      "birth_place": "JAKARTA",
      "birth_date": "1990-05-15",
      "gender": "male",
      "address": "JL. MERDEKA NO. 123",
      "rt_rw": "001/002",
      "village": "SUKAMAJU",
      "district": "CILANDAK",
      "city": "JAKARTA SELATAN",
      "province": "DKI JAKARTA",
      "is_verified": false,
      "is_profile_complete": true,
      "ktp_photo": "https://storage.example.com/customers/456/ktp.jpg",
      "selfie_photo": "https://storage.example.com/customers/456/selfie.jpg"
    },
    "token": "1|laravel_sanctum_token_abc123xyz...",
    "token_type": "Bearer"
  }
}
```

**Response Error - Email Sudah Terdaftar (422):**
```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "email": ["Email sudah digunakan"]
  }
}
```

**Response Error - NIK Sudah Terdaftar (422):**
```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "nik": ["NIK sudah terdaftar dengan akun lain"]
  }
}
```

**Response Error - Validation Error (422):**
```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "nik": ["NIK harus 16 digit"],
    "ktp_image": ["Foto KTP wajib diupload"],
    "birth_date": ["Format tanggal tidak valid"]
  }
}
```

---

## Error Codes Reference

| Code | HTTP Status | Description |
|------|-------------|-------------|
| DUPLICATE_EMAIL | 422 | Email sudah terdaftar |
| DUPLICATE_NIK | 422 | NIK sudah terdaftar |
| VALIDATION_ERROR | 422 | Error validasi input |
| INVALID_NIK_FORMAT | 422 | Format NIK tidak valid (harus 16 digit) |
| FILE_TOO_LARGE | 422 | Ukuran file melebihi 5MB |
| INVALID_FILE_TYPE | 422 | Tipe file tidak valid (harus JPEG/PNG) |

---

## Laravel Implementation Notes

### 1. Database Migration (customers table update)

```php
Schema::table('customers', function (Blueprint $table) {
    $table->string('nik', 16)->unique()->after('user_id');
    $table->string('birth_place')->nullable();
    $table->date('birth_date')->nullable();
    $table->enum('gender', ['male', 'female'])->nullable();
    $table->string('rt_rw')->nullable();
    $table->string('village')->nullable()->comment('Kelurahan/Desa');
    $table->string('district')->nullable()->comment('Kecamatan');
    $table->string('city')->nullable()->comment('Kabupaten/Kota');
    $table->string('province')->nullable();
    $table->string('religion')->nullable();
    $table->string('marital_status')->nullable();
    $table->string('occupation')->nullable();
    $table->string('ktp_photo')->nullable();
    $table->string('selfie_photo')->nullable();
    $table->boolean('is_verified')->default(false);
    $table->timestamp('verified_at')->nullable();
});
```

### 2. Controller Example

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;

class RegisterController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email|unique:users,email',
            'password' => 'required|min:8|confirmed',
            'ktp_image' => 'required|image|mimes:jpeg,png,jpg|max:5120',
            'selfie_image' => 'required|image|mimes:jpeg,png,jpg|max:5120',
            'nik' => 'required|string|size:16|unique:customers,nik',
            'name' => 'required|string|max:255',
            'birth_place' => 'required|string|max:100',
            'birth_date' => 'required|date|before:today',
            'gender' => 'required|in:male,female',
            'address' => 'required|string',
            'rt_rw' => 'nullable|string|max:10',
            'village' => 'nullable|string|max:100',
            'district' => 'nullable|string|max:100',
            'city' => 'nullable|string|max:100',
            'province' => 'nullable|string|max:100',
            'religion' => 'nullable|string|max:50',
            'marital_status' => 'nullable|string|max:50',
            'occupation' => 'nullable|string|max:100',
            'phone' => 'nullable|string|max:20',
            'agree_terms' => 'required|accepted',
        ]);

        return DB::transaction(function () use ($request, $validated) {
            // Create user
            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'phone' => $validated['phone'] ?? null,
                'password' => Hash::make($validated['password']),
            ]);

            // Upload photos
            $ktpPath = $request->file('ktp_image')
                ->store("customers/{$user->id}", 'public');
            $selfiePath = $request->file('selfie_image')
                ->store("customers/{$user->id}", 'public');

            // Create customer
            $customer = Customer::create([
                'user_id' => $user->id,
                'customer_code' => $this->generateCustomerCode(),
                'nik' => $validated['nik'],
                'name' => $validated['name'],
                'birth_place' => $validated['birth_place'],
                'birth_date' => $validated['birth_date'],
                'gender' => $validated['gender'],
                'address' => $validated['address'],
                'rt_rw' => $validated['rt_rw'] ?? null,
                'village' => $validated['village'] ?? null,
                'district' => $validated['district'] ?? null,
                'city' => $validated['city'] ?? null,
                'province' => $validated['province'] ?? null,
                'religion' => $validated['religion'] ?? null,
                'marital_status' => $validated['marital_status'] ?? null,
                'occupation' => $validated['occupation'] ?? null,
                'ktp_photo' => $ktpPath,
                'selfie_photo' => $selfiePath,
                'is_profile_complete' => true,
            ]);

            // Generate token
            $token = $user->createToken('mobile-app')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Registrasi berhasil',
                'data' => [
                    'user' => $user,
                    'customer' => $customer,
                    'token' => $token,
                    'token_type' => 'Bearer',
                ],
            ], 201);
        });
    }

    private function generateCustomerCode(): string
    {
        $date = now()->format('Ymd');
        $lastCustomer = Customer::whereDate('created_at', today())
            ->orderBy('id', 'desc')
            ->first();
        
        $sequence = $lastCustomer 
            ? ((int) substr($lastCustomer->customer_code, -4)) + 1 
            : 1;
        
        return "CST-{$date}-" . str_pad($sequence, 4, '0', STR_PAD_LEFT);
    }
}
```

### 3. Route

```php
// routes/api.php
Route::post('/register', [RegisterController::class, 'register']);
```

---

## Security Considerations

1. **HTTPS Only**: Semua endpoint harus HTTPS
2. **NIK Validation**: Validasi format NIK (16 digit)
3. **Image Storage**: Foto KTP/selfie disimpan di storage private
4. **Rate Limiting**: Limit register requests per IP
5. **Duplicate Detection**: Cek NIK & email sudah terdaftar

---

## Mobile Implementation

### Packages Diperlukan (Flutter)
```yaml
dependencies:
  camera: ^0.10.5+9                        # Akses kamera
  google_mlkit_text_recognition: ^0.11.0   # OCR on-device (GRATIS)
  google_mlkit_face_detection: ^0.9.0      # Face detection (GRATIS)
  permission_handler: ^11.3.0              # Request permissions
  image: ^4.1.7                            # Image processing
```

### Flow di Mobile

```
1. STEP 1: Form email + password + konfirmasi
           ↓
2. STEP 2: Buka kamera → Capture KTP
           → OCR on-device (Google ML Kit)
           → Extract NIK, Nama, TTL, Alamat
           ↓
3. STEP 3: Buka kamera depan → Capture Selfie
           → Face detection untuk validasi ada wajah
           ↓
4. STEP 4: Review hasil OCR
           → User bisa edit jika salah
           → Input phone (optional)
           ↓
5. STEP 5: Submit ke /api/register
           → Upload foto + data
           → Terima token
           → Masuk ke dashboard
```

### OCR Parsing untuk KTP Indonesia

Data yang bisa di-extract dari KTP:
- NIK (16 digit, posisi atas)
- Nama
- Tempat/Tgl Lahir
- Jenis Kelamin
- Alamat
- RT/RW
- Kel/Desa
- Kecamatan
- Agama
- Status Perkawinan
- Pekerjaan
- Kewarganegaraan

### Tips OCR Akurat
1. Guide overlay untuk positioning KTP
2. Gunakan flash jika gelap
3. Deteksi blur sebelum capture
4. Crop ke area KTP saja
5. Rotate jika perlu (landscape)

