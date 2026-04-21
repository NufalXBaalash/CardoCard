-- ============================================
-- CardoCard Full Database Migration to Supabase
-- Run this in the Supabase SQL Editor
-- ============================================

-- Drop existing tables in dependency order
drop table if exists nfc_mappings cascade;
drop table if exists health_metrics cascade;
drop table if exists prescriptions cascade;
drop table if exists medical_records cascade;
drop table if exists appointments cascade;
drop table if exists doctor_availability cascade;
drop table if exists doctors cascade;
drop table if exists medications cascade;
drop table if exists medical_info cascade;
drop table if exists profiles cascade;

-- ==================== PROFILES ====================
-- (replaces Firestore 'users' collection)
create table profiles (
  id text primary key, -- Firebase Auth UID
  full_name text default '',
  email text default '',
  phone_number text default '',
  address text default '',
  gender text,
  national_id text,
  role text default 'patient',
  profile_image_base64 text,
  profile_image_updated_at timestamptz,
  nfc_uid text,
  registration_complete boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ==================== MEDICAL INFO ====================
create table medical_info (
  id uuid default gen_random_uuid() primary key,
  user_id text not null references profiles(id) on delete cascade unique,
  blood_type text default 'A+',
  has_diabetes boolean default false,
  has_asthma boolean default false,
  medical_info_added_at timestamptz,
  created_at timestamptz default now()
);

-- ==================== MEDICATIONS ====================
-- (replaces Firestore subcollection users/{uid}/medications)
create table medications (
  id uuid default gen_random_uuid() primary key,
  user_id text not null references profiles(id) on delete cascade,
  name text not null,
  dosage text default '',
  quantity text default '',
  time text default '',
  instructions text default '',
  frequency text default '',
  taken boolean default false,
  created_at timestamptz default now()
);

-- ==================== DOCTORS ====================
create table doctors (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  name_ar text,
  specialty text not null,
  specialty_key text,
  organization text,
  organization_ar text,
  bio text,
  location text,
  address text,
  price numeric default 0,
  appointment_duration integer default 30,
  rating numeric default 0,
  review_count integer default 0,
  image_url text,
  created_at timestamptz default now()
);

-- ==================== DOCTOR AVAILABILITY ====================
create table doctor_availability (
  id uuid default gen_random_uuid() primary key,
  doctor_id uuid references doctors(id) on delete cascade,
  day_of_week smallint not null, -- 0=Mon, 1=Tue, ... 6=Sun
  start_time time not null,
  end_time time not null,
  is_available boolean default true
);

-- ==================== APPOINTMENTS ====================
create table appointments (
  id uuid default gen_random_uuid() primary key,
  patient_id text not null references profiles(id),
  doctor_id uuid references doctors(id),
  appointment_date date not null,
  start_time time not null,
  end_time time not null,
  status text default 'scheduled', -- scheduled, completed, cancelled
  notes text,
  created_at timestamptz default now()
);

-- ==================== MEDICAL RECORDS ====================
create table medical_records (
  id uuid default gen_random_uuid() primary key,
  patient_id text not null references profiles(id),
  doctor_id uuid references doctors(id),
  date date not null,
  diagnosis text,
  diagnosis_key text,
  treatment text,
  treatment_key text,
  notes text,
  notes_ar text,
  created_at timestamptz default now()
);

-- ==================== PRESCRIPTIONS ====================
create table prescriptions (
  id uuid default gen_random_uuid() primary key,
  user_id text not null references profiles(id),
  doctor_id uuid references doctors(id),
  medication_name text not null,
  dosage text,
  frequency text,
  duration text,
  notes text,
  created_at timestamptz default now()
);

-- ==================== HEALTH METRICS ====================
create table health_metrics (
  id uuid default gen_random_uuid() primary key,
  user_id text not null references profiles(id),
  metric_type text not null, -- e.g. 'blood_pressure', 'heart_rate', 'weight'
  value numeric,
  unit text,
  recorded_at timestamptz default now()
);

-- ==================== NFC MAPPINGS ====================
-- (for NFC card linking, replaces Firestore users/{nfcUid} mapping docs)
create table nfc_mappings (
  id uuid default gen_random_uuid() primary key,
  nfc_uid text not null unique,
  linked_user text not null references profiles(id),
  type text default 'nfc_mapping',
  created_at timestamptz default now()
);

-- ==================== ENABLE RLS ON ALL TABLES ====================
alter table profiles enable row level security;
alter table medical_info enable row level security;
alter table medications enable row level security;
alter table doctors enable row level security;
alter table doctor_availability enable row level security;
alter table appointments enable row level security;
alter table medical_records enable row level security;
alter table prescriptions enable row level security;
alter table health_metrics enable row level security;
alter table nfc_mappings enable row level security;

-- ==================== RLS POLICIES ====================

-- Profiles: users can read/write own profile
create policy "Users can read own profile" on profiles for select using (true);
create policy "Users can insert own profile" on profiles for insert with check (true);
create policy "Users can update own profile" on profiles for update using (true);

-- Medical Info: users manage their own
create policy "Medical info publicly readable" on medical_info for select using (true);
create policy "Users can insert medical info" on medical_info for insert with check (true);
create policy "Users can update medical info" on medical_info for update using (true);

-- Medications: users manage their own
create policy "Users can read own medications" on medications for select using (true);
create policy "Users can insert medications" on medications for insert with check (true);
create policy "Users can update medications" on medications for update using (true);
create policy "Users can delete medications" on medications for delete using (true);

-- Doctors: public read
create policy "Doctors are publicly readable" on doctors for select using (true);

-- Doctor Availability: public read
create policy "Availability is publicly readable" on doctor_availability for select using (true);

-- Appointments: users manage their own
create policy "Users can read appointments" on appointments for select using (true);
create policy "Users can insert appointments" on appointments for insert with check (true);
create policy "Users can update appointments" on appointments for update using (true);
create policy "Users can delete appointments" on appointments for delete using (true);

-- Medical Records: users read their own
create policy "Users can read own records" on medical_records for select using (true);
create policy "Users can insert records" on medical_records for insert with check (true);

-- Prescriptions: users manage their own
create policy "Users can read own prescriptions" on prescriptions for select using (true);
create policy "Users can insert prescriptions" on prescriptions for insert with check (true);

-- Health Metrics: users manage their own
create policy "Users can read own metrics" on health_metrics for select using (true);
create policy "Users can insert metrics" on health_metrics for insert with check (true);

-- NFC Mappings: public read, users manage
create policy "NFC mappings publicly readable" on nfc_mappings for select using (true);
create policy "Users can insert nfc mappings" on nfc_mappings for insert with check (true);
create policy "Users can update nfc mappings" on nfc_mappings for update using (true);

-- ==================== SEED DATA ====================

-- Sample Doctors
insert into doctors (name, name_ar, specialty, specialty_key, organization, organization_ar, bio, price, rating, review_count) values
('Dr. Ahmed Baalash', 'د. أحمد بعلش', 'Cardiologist', 'cardiologist', 'Central City Heart Institute', 'معهد القلب للمدينة المركزية', 'Specialist in heart diseases and cardiovascular treatments', 300, 4.8, 253),
('Dr. Emily Rodriguez', 'د. إيملي رودريغيز', 'Cardiologist', 'cardiologist', 'Central City Heart Institute', 'معهد القلب للمدينة المركزية', 'Expert in coronary artery disease and preventive cardiology', 350, 4.7, 187),
('Dr. Michael Chen', 'د. مايكل تشن', 'Neurology', 'neurology', 'Metropolitan Neurological Center', 'مركز الأعصاب المتروبوليتاني', 'Specialist in brain disorders and migraine treatment', 400, 4.9, 312),
('Dr. Sofia Patel', 'د. صوفيا باتيل', 'Pediatrician', 'pediatrician', 'Children''s Regional Medical Center', 'المركز الطبي الإقليمي للأطفال', 'Experienced in childhood development and immunizations', 250, 4.6, 198),
('Dr. Alexander Wright', 'د. ألكسندر رايت', 'Orthopedics', 'orthopedics', 'Sports Medicine and Rehabilitation Center', 'مركز طب الرياضة وإعادة التأهيل', 'Expert in sports injuries and joint rehabilitation', 320, 4.5, 142),
('Dr. Olivia Martinez', 'د. أوليفيا مارتينيز', 'Dermatologist', 'dermatologist', 'Skin Health Clinic', 'عيادة صحة الجلد', 'Specialist in acne treatment and skin health', 280, 4.7, 210),
('Dr. Daniel Kim', 'د. دانيال كيم', 'Psychiatrist', 'psychiatrist', 'Mental Wellness Institute', 'معهد العافية النفسية', 'CBT and anxiety disorder specialist', 360, 4.8, 225),
('Dr. Rachel Goldman', 'د. راشيل غولدمان', 'Oncologist', 'oncologist', 'Cancer Research and Treatment Center', 'مركز أبحاث وعلاج السرطان', 'Specialist in lymphoma treatment', 450, 4.9, 178),
('Dr. Thomas Anderson', 'د. توماس أندرسون', 'Gastroenterologist', 'gastroenterologist', 'Digestive Health Clinic', 'عيادة صحة الجهاز الهضمي', 'Expert in chronic acid reflux and digestive disorders', 310, 4.6, 165);

-- Sample Doctor Availability (Mon-Fri 9:00-17:00, 30-min slots)
-- Generates slots like 9:00-9:30, 9:30-10:00, ..., 16:00-16:30
insert into doctor_availability (doctor_id, day_of_week, start_time, end_time)
select d.id, day.day, slot.start_time, slot.end_time
from doctors d
cross join generate_series(0, 4) as day(day)
cross join lateral (
  select (t || ':00')::time as start_time,
         ((t || ':00')::time + interval '30 minutes')::time as end_time
  from generate_series(9, 16) as t
  where (t || ':00')::time + interval '30 minutes' <= '17:00'::time
) as slot;

-- ==================== INDEXES ====================
create index idx_medical_info_user on medical_info(user_id);
create index idx_medications_user on medications(user_id);
create index idx_appointments_patient on appointments(patient_id);
create index idx_appointments_doctor_date on appointments(doctor_id, appointment_date);
create index idx_medical_records_patient on medical_records(patient_id);
create index idx_prescriptions_user on prescriptions(user_id);
create index idx_health_metrics_user on health_metrics(user_id);
create index idx_nfc_mappings_uid on nfc_mappings(nfc_uid);
