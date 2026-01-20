-- ValESCO Supabase Database Setup
-- Run this SQL in your Supabase SQL Editor (https://supabase.com/dashboard)

-- ============================================
-- 1. USERS TABLE (extends Supabase auth.users)
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  phone_number TEXT,
  date_of_birth DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. HEALTH PROFILES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS health_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  age INTEGER,
  gender TEXT,
  blood_group TEXT,
  height DOUBLE PRECISION,
  weight DOUBLE PRECISION,
  chronic_conditions JSONB DEFAULT '[]',
  past_surgeries JSONB DEFAULT '[]',
  current_medications JSONB DEFAULT '[]',
  drug_allergies JSONB DEFAULT '[]',
  food_allergies JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)  -- One profile per user
);

-- ============================================
-- 3. EMERGENCY CONTACTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  relationship TEXT,
  phone_number TEXT NOT NULL,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. MEDICATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS medications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  dosage TEXT,
  frequency TEXT,
  reminder_times JSONB DEFAULT '[]',
  start_date DATE NOT NULL,
  end_date DATE,
  notes TEXT,
  total_pills INTEGER DEFAULT 30,
  pills_remaining INTEGER DEFAULT 30,
  refill_reminder_threshold INTEGER DEFAULT 5,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 5. MEDICATION INTAKES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS medication_intakes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medication_id UUID REFERENCES medications(id) ON DELETE CASCADE,
  scheduled_time TIMESTAMPTZ NOT NULL,
  actual_time TIMESTAMPTZ,
  status TEXT DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 6. HEALTH READINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS health_readings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  value DOUBLE PRECISION NOT NULL,
  secondary_value DOUBLE PRECISION,
  timestamp TIMESTAMPTZ NOT NULL,
  context TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 7. EMERGENCY ALERTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS emergency_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  address TEXT,
  status TEXT DEFAULT 'initiated',
  contacts_notified JSONB DEFAULT '[]',
  ambulance_id UUID,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- ============================================
-- 8. HOSPITALS TABLE (static data)
-- ============================================
CREATE TABLE IF NOT EXISTS hospitals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  phone TEXT,
  emergency_phone TEXT,
  specialties JSONB DEFAULT '[]',
  rating DOUBLE PRECISION,
  is_open_24h BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 9. AMBULANCES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS ambulances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hospital_id UUID REFERENCES hospitals(id) ON DELETE SET NULL,
  name TEXT,
  phone TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_available BOOLEAN DEFAULT true,
  eta_minutes INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_intakes ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE ambulances ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES - Users can only access their own data
-- ============================================

-- Users table policies
DROP POLICY IF EXISTS "Users can view own data" ON users;
CREATE POLICY "Users can view own data" ON users 
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own data" ON users;
CREATE POLICY "Users can update own data" ON users 
  FOR UPDATE USING (auth.uid() = id);

-- Note: INSERT is handled by the trigger function which uses SECURITY DEFINER
-- This policy is a fallback for any manual inserts (should match the user's own ID)
DROP POLICY IF EXISTS "Users can insert own data" ON users;
CREATE POLICY "Users can insert own data" ON users 
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow the trigger function to bypass RLS (SECURITY DEFINER handles this)
-- Service role can also insert for new users during registration
DROP POLICY IF EXISTS "Service role can insert users" ON users;
CREATE POLICY "Service role can insert users" ON users
  FOR INSERT TO service_role WITH CHECK (true);

-- Health profiles policies
DROP POLICY IF EXISTS "Users can manage own health profiles" ON health_profiles;
CREATE POLICY "Users can manage own health profiles" ON health_profiles 
  FOR ALL USING (auth.uid() = user_id);

-- Emergency contacts policies
DROP POLICY IF EXISTS "Users can manage own emergency contacts" ON emergency_contacts;
CREATE POLICY "Users can manage own emergency contacts" ON emergency_contacts 
  FOR ALL USING (auth.uid() = user_id);

-- Medications policies
DROP POLICY IF EXISTS "Users can manage own medications" ON medications;
CREATE POLICY "Users can manage own medications" ON medications 
  FOR ALL USING (auth.uid() = user_id);

-- Medication intakes policies
DROP POLICY IF EXISTS "Users can manage own medication intakes" ON medication_intakes;
CREATE POLICY "Users can manage own medication intakes" ON medication_intakes 
  FOR ALL USING (auth.uid() = user_id);

-- Health readings policies
DROP POLICY IF EXISTS "Users can manage own health readings" ON health_readings;
CREATE POLICY "Users can manage own health readings" ON health_readings 
  FOR ALL USING (auth.uid() = user_id);

-- Emergency alerts policies
DROP POLICY IF EXISTS "Users can manage own emergency alerts" ON emergency_alerts;
CREATE POLICY "Users can manage own emergency alerts" ON emergency_alerts 
  FOR ALL USING (auth.uid() = user_id);

-- Hospitals - public read for authenticated users
DROP POLICY IF EXISTS "Anyone can view hospitals" ON hospitals;
CREATE POLICY "Anyone can view hospitals" ON hospitals 
  FOR SELECT TO authenticated USING (true);

-- Ambulances - public read for authenticated users  
DROP POLICY IF EXISTS "Anyone can view ambulances" ON ambulances;
CREATE POLICY "Anyone can view ambulances" ON ambulances 
  FOR SELECT TO authenticated USING (true);

-- ============================================
-- CREATE INDEXES FOR BETTER PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_health_profiles_user_id ON health_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user_id ON emergency_contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_medications_user_id ON medications(user_id);
CREATE INDEX IF NOT EXISTS idx_medication_intakes_user_id ON medication_intakes(user_id);
CREATE INDEX IF NOT EXISTS idx_medication_intakes_medication_id ON medication_intakes(medication_id);
CREATE INDEX IF NOT EXISTS idx_health_readings_user_id ON health_readings(user_id);
CREATE INDEX IF NOT EXISTS idx_health_readings_type ON health_readings(type);
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_user_id ON emergency_alerts(user_id);

-- ============================================
-- TRIGGER: Auto-create user record on signup
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, phone_number, date_of_birth)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone_number', ''),
    (NEW.raw_user_meta_data->>'date_of_birth')::DATE
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
  RAISE NOTICE 'ValESCO database setup completed successfully!';
END $$;
