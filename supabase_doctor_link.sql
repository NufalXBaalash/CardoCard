-- Run this in Supabase SQL Editor to add doctor-user link
alter table doctors add column if not exists supabase_user_id text;
create index if not exists idx_doctors_user_id on doctors(supabase_user_id);
