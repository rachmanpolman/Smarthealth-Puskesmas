-- ==============================================================================
-- PUSKESMAS PEDULI (SMART HEALTH) - OFFICIAL POSTGRESQL SCHEMA FOR SUPABASE
-- Disesuaikan 100% dengan Entity Relationship Diagram (ERD) Supabase Proyek
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. TABEL PUSKESMAS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.puskesmas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nama TEXT NOT NULL,
    alamat TEXT NOT NULL,
    latitude FLOAT8 NOT NULL,
    longitude FLOAT8 NOT NULL,
    no_telp TEXT
);

-- ==============================================================================
-- 3. TABEL PROFIL PENGGUNA (PASIEN)
-- Terhubung langsung ke tabel internal Supabase: auth.users(id)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profil_pengguna (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nama_lengkap TEXT NOT NULL,
    no_telp TEXT,
    alamat TEXT,
    foto_profil TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 4. TABEL DOKTER
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.dokter (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    puskesmas_id UUID REFERENCES public.puskesmas(id) ON DELETE SET NULL,
    nama_dokter TEXT NOT NULL,
    spesialisasi TEXT NOT NULL,
    deskripsi TEXT,
    foto_dokter TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 5. TABEL JADWAL PRAKTIK
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.jadwal_praktik (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dokter_id UUID NOT NULL REFERENCES public.dokter(id) ON DELETE CASCADE,
    hari TEXT NOT NULL,
    jam_mulai TIME NOT NULL,
    jam_selesai TIME NOT NULL,
    kuota INT4 DEFAULT 20
);

-- ==============================================================================
-- 6. TABEL RESERVASI (TIKET ANTREAN DOKTER)
-- ID reservasi (UUID) digunakan langsung sebagai data encoded QR Code
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.reservasi (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pengguna_id UUID NOT NULL REFERENCES public.profil_pengguna(id) ON DELETE CASCADE,
    jadwal_id UUID NOT NULL REFERENCES public.jadwal_praktik(id) ON DELETE CASCADE,
    tanggal_kunjungan DATE NOT NULL,
    keluhan TEXT,
    status TEXT DEFAULT 'Menunggu',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 7. SETUP ROW-LEVEL SECURITY (RLS)
-- ==============================================================================
ALTER TABLE public.profil_pengguna ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.puskesmas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dokter ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jadwal_praktik ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservasi ENABLE ROW LEVEL SECURITY;

-- Policy profil_pengguna (Hanya pemilik akun yang dapat mengakses datanya)
DROP POLICY IF EXISTS "User bisa melihat profil sendiri" ON public.profil_pengguna;
CREATE POLICY "User bisa melihat profil sendiri" 
    ON public.profil_pengguna FOR SELECT 
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "User bisa update profil sendiri" ON public.profil_pengguna;
CREATE POLICY "User bisa update profil sendiri" 
    ON public.profil_pengguna FOR UPDATE 
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "User bisa insert profil saat daftar" ON public.profil_pengguna;
CREATE POLICY "User bisa insert profil saat daftar" 
    ON public.profil_pengguna FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- Policy puskesmas (Publik boleh membaca info lokasi)
DROP POLICY IF EXISTS "Publik bisa melihat data puskesmas" ON public.puskesmas;
CREATE POLICY "Publik bisa melihat data puskesmas" 
    ON public.puskesmas FOR SELECT 
    USING (true);

-- Policy dokter & jadwal (Publik boleh membaca katalog dokter dan jadwal praktik)
DROP POLICY IF EXISTS "Publik bisa melihat data dokter" ON public.dokter;
CREATE POLICY "Publik bisa melihat data dokter" 
    ON public.dokter FOR SELECT 
    USING (true);

DROP POLICY IF EXISTS "Publik bisa melihat jadwal dokter" ON public.jadwal_praktik;
CREATE POLICY "Publik bisa melihat jadwal dokter" 
    ON public.jadwal_praktik FOR SELECT 
    USING (true);

-- Policy reservasi (Pasien mengelola reservasinya sendiri, loket dapat melihat untuk verifikasi)
DROP POLICY IF EXISTS "Pasien bisa melihat reservasinya" ON public.reservasi;
CREATE POLICY "Pasien bisa melihat reservasinya" 
    ON public.reservasi FOR SELECT 
    USING (true); -- Mengizinkan pembacaan untuk pasien dan fitur scan QR loket medis

DROP POLICY IF EXISTS "Pasien bisa membuat reservasi" ON public.reservasi;
CREATE POLICY "Pasien bisa membuat reservasi" 
    ON public.reservasi FOR INSERT 
    WITH CHECK (auth.uid() = pengguna_id);

DROP POLICY IF EXISTS "Pasien bisa update reservasi miliknya" ON public.reservasi;
CREATE POLICY "Pasien bisa update reservasi miliknya" 
    ON public.reservasi FOR UPDATE 
    USING (auth.uid() = pengguna_id);

DROP POLICY IF EXISTS "Pasien bisa menghapus reservasi miliknya" ON public.reservasi;
CREATE POLICY "Pasien bisa menghapus reservasi miliknya" 
    ON public.reservasi FOR DELETE 
    USING (auth.uid() = pengguna_id);

-- ==============================================================================
-- 8. SAMPLE DUMMY DATA UNTUK PUSKESMAS, DOKTER, DAN JADWAL
-- ==============================================================================

-- 1. Puskesmas Pariwisata Sungailiat
INSERT INTO public.puskesmas (id, nama, alamat, latitude, longitude, no_telp)
VALUES (
    'e58ed763-928c-4155-bee9-fdbaaadc15f3',
    'Puskesmas Pariwisata Sungailiat',
    'Jl. Jenderal Sudirman No. 45, Sungailiat, Bangka Belitung',
    -1.858712,
    106.118942,
    '(0717) 94443'
)
ON CONFLICT (id) DO UPDATE 
SET nama = EXCLUDED.nama, alamat = EXCLUDED.alamat, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude;

-- 2. Data Dokter Spesialis
INSERT INTO public.dokter (id, puskesmas_id, nama_dokter, spesialisasi, deskripsi, foto_dokter)
VALUES 
    (
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'e58ed763-928c-4155-bee9-fdbaaadc15f3',
        'dr. Andi Pratama, Sp.PD',
        'Spesialis Penyakit Dalam',
        'Melayani konsultasi penyakit dalam, diabetes, hipertensi, dan gangguan metabolik.',
        'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400'
    ),
    (
        'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
        'e58ed763-928c-4155-bee9-fdbaaadc15f3',
        'dr. Sarah Wijaya, Sp.A',
        'Spesialis Anak',
        'Melayani tumbuh kembang anak, imunisasi rutin, dan kesehatan balita.',
        'https://images.unsplash.com/photo-1594824813511-209f92e022f4?w=400'
    ),
    (
        'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
        'e58ed763-928c-4155-bee9-fdbaaadc15f3',
        'drg. Budi Santoso',
        'Spesialis Gigi & Mulut',
        'Melayani penambalan gigi, pembersihan karang gigi (scaling), dan pencabutan.',
        'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=400'
    ),
    (
        'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
        'e58ed763-928c-4155-bee9-fdbaaadc15f3',
        'dr. Maya Lestari, Sp.OG',
        'Spesialis Kebidanan & Kandungan',
        'Melayani pemeriksaan kehamilan (ANC), USG dasar, dan konsultasi KB.',
        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400'
    )
ON CONFLICT (id) DO NOTHING;

-- 3. Data Jadwal Praktik Dokter
INSERT INTO public.jadwal_praktik (dokter_id, hari, jam_mulai, jam_selesai, kuota)
VALUES
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Senin', '08:00', '12:00', 25),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Rabu', '08:00', '12:00', 25),
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'Selasa', '09:00', '13:00', 20),
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'Kamis', '09:00', '13:00', 20),
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'Senin', '08:30', '11:30', 15),
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'Jumat', '08:30', '11:00', 15),
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'Rabu', '10:00', '14:00', 20),
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'Sabtu', '08:00', '12:00', 20)
ON CONFLICT DO NOTHING;
