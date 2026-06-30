-- ============================================================================
-- TransformFit — Canonical Schema (M1, ported subset)
-- Project: zuwtgdqsxmtiqojckpus
-- Ports the canonical Supabase schema subset in play: profiles, readiness,
-- sessions/set_logs, recovery, exercise/muscle_groups/equipment reference,
-- programs/program_*/progression_records, user_subscriptions (tier enum),
-- ai_adaptations/ai_coach_messages/coach_memory, coach_alerts/streaks.
-- Owner-scoped RLS on every user table; public read (no write) on reference.
-- Recreates handle_new_user() SECURITY DEFINER verbatim (+ free-tier seeding).
-- Idempotent: safe to re-run.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SECTION 0: ENUMS
-- ----------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE public.subscription_tier AS ENUM ('free', 'pro', 'coach');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ----------------------------------------------------------------------------
-- SECTION 1: profiles  (PK = auth.users.id, auto-created by handle_new_user)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text,
  goal text,
  experience_level text,
  equipment text[] DEFAULT '{}',
  training_days_per_week integer,
  sport text,
  season_phase text,
  limitations text[] DEFAULT '{}',
  coach_persona text,
  streak_current integer NOT NULL DEFAULT 0,
  streak_longest integer NOT NULL DEFAULT 0,
  last_workout_date date,
  subscription_status text NOT NULL DEFAULT 'free',
  onboarding_completed boolean NOT NULL DEFAULT false,
  age integer,
  biological_sex text,
  height_cm numeric,
  weight_kg numeric,
  weight_unit text DEFAULT 'kg',
  daily_calories_target integer,
  daily_protein_target integer,
  daily_carbs_target integer,
  daily_fat_target integer,
  fatigue_debt numeric DEFAULT 0,
  movement_screen_scores jsonb,
  next_game_date date,
  referral_code text,
  referred_by text,
  referrals_count integer NOT NULL DEFAULT 0,
  response_profile text,
  stripe_customer_id text,
  stripe_subscription_id text,
  payment_failed boolean NOT NULL DEFAULT false,
  cycle_tracking_enabled boolean NOT NULL DEFAULT false,
  glp1_enabled boolean NOT NULL DEFAULT false,
  glp1_medication text,
  glp1_dose text,
  glp1_start_date date,
  glp1_injection_days text[] DEFAULT '{}',
  glp1_side_effects text[] DEFAULT '{}',
  -- V10 / onboarding extension columns
  identity_anchor text,
  barriers text[] DEFAULT '{}',
  schedule jsonb DEFAULT '{}'::jsonb,
  fitness_level text CHECK (fitness_level IN ('beginner', 'intermediate', 'advanced')),
  coach_day_number integer NOT NULL DEFAULT 0,
  last_active_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
-- profiles policies (owner = id = auth.uid())
DO $$ BEGIN
  CREATE POLICY profiles_owner_select ON public.profiles
    FOR SELECT USING (auth.uid() = id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY profiles_owner_insert ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY profiles_owner_update ON public.profiles
    FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY profiles_owner_delete ON public.profiles
    FOR DELETE USING (auth.uid() = id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON public.profiles (created_at DESC);

-- ----------------------------------------------------------------------------
-- SECTION 2: user_subscriptions  (tier enum free|pro|coach; client read-only)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  tier public.subscription_tier NOT NULL DEFAULT 'free',
  status text NOT NULL DEFAULT 'active',
  started_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  trial_ends_at timestamptz,
  stripe_customer_id text,
  stripe_subscription_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
-- Client may READ own subscription only; NO client write (prevents self-escalation).
DO $$ BEGIN
  CREATE POLICY user_subscriptions_owner_select ON public.user_subscriptions
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user ON public.user_subscriptions (user_id);

-- ----------------------------------------------------------------------------
-- SECTION 3: reference tables — muscle_groups, equipment, exercises
-- Public read, NO client write.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.muscle_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category text NOT NULL DEFAULT 'general',
  icon text NOT NULL DEFAULT 'dumbbell',
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.muscle_groups ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY muscle_groups_public_read ON public.muscle_groups
    FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.equipment (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  icon text NOT NULL DEFAULT 'dumbbell',
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.equipment ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY equipment_public_read ON public.equipment
    FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.exercises (
  id text PRIMARY KEY,
  name text NOT NULL,
  muscle_group text NOT NULL,
  muscle_group_id uuid REFERENCES public.muscle_groups(id) ON DELETE SET NULL,
  equipment text NOT NULL DEFAULT 'bodyweight',
  equipment_ids text[] DEFAULT '{}',
  equipment_type_id uuid REFERENCES public.equipment(id) ON DELETE SET NULL,
  difficulty text NOT NULL DEFAULT 'intermediate',
  is_compound boolean NOT NULL DEFAULT false,
  popular boolean NOT NULL DEFAULT false,
  movement_pattern text,
  instructions text,
  video_url text,
  default_sets integer,
  default_reps integer,
  default_rpe_target numeric,
  default_rest_seconds integer,
  cue_1 text,
  cue_2 text,
  cue_3 text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY exercises_public_read ON public.exercises
    FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_exercises_muscle_group ON public.exercises (muscle_group);
CREATE INDEX IF NOT EXISTS idx_exercises_equipment ON public.exercises (equipment);

-- ----------------------------------------------------------------------------
-- SECTION 4: daily_readiness_logs
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.daily_readiness_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  energy_level integer NOT NULL DEFAULT 5,
  hrv numeric,
  sleep_quality integer NOT NULL DEFAULT 7,
  soreness_map text[] NOT NULL DEFAULT '{}',
  strain numeric NOT NULL DEFAULT 0,
  readiness_score numeric(5,2),
  mood text CHECK (mood IN ('fired_up', 'focused', 'neutral', 'stressed', 'low')),
  soreness_level integer CHECK (soreness_level >= 1 AND soreness_level <= 10),
  stress_level integer CHECK (stress_level >= 1 AND stress_level <= 10),
  source text NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'apple_health', 'garmin', 'whoop', 'oura', 'fitbit', 'calculated')),
  date date,
  logged_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.daily_readiness_logs ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY daily_readiness_logs_owner_select ON public.daily_readiness_logs
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY daily_readiness_logs_owner_insert ON public.daily_readiness_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY daily_readiness_logs_owner_update ON public.daily_readiness_logs
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY daily_readiness_logs_owner_delete ON public.daily_readiness_logs
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_daily_readiness_user_date ON public.daily_readiness_logs (user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_readiness_user_logged ON public.daily_readiness_logs (user_id, logged_at DESC);

-- ----------------------------------------------------------------------------
-- SECTION 5: ai_readiness_results  (DAI plan audit)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ai_readiness_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  plan_date date NOT NULL DEFAULT CURRENT_DATE,
  readiness_log_id uuid REFERENCES public.daily_readiness_logs(id) ON DELETE SET NULL,
  verdict text,
  suggested_session_type text,
  coaching_cue text,
  explanation text,
  mobility_flow text[] DEFAULT '{}',
  full_result jsonb,
  status text NOT NULL DEFAULT 'pending',
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.ai_readiness_results ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY ai_readiness_results_owner_select ON public.ai_readiness_results
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY ai_readiness_results_owner_insert ON public.ai_readiness_results
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY ai_readiness_results_owner_update ON public.ai_readiness_results
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY ai_readiness_results_owner_delete ON public.ai_readiness_results
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_ai_readiness_results_user_date ON public.ai_readiness_results (user_id, plan_date DESC);

-- ----------------------------------------------------------------------------
-- SECTION 6: sessions + set_logs
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'planned',
  session_type text,
  started_at timestamptz,
  completed_at timestamptz,
  readiness_score numeric,
  total_volume_kg numeric,
  adaptations_made integer DEFAULT 0,
  pre_energy integer,
  pre_hrv numeric,
  pre_sleep integer,
  pre_strain numeric,
  session_summary text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY sessions_owner_select ON public.sessions
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY sessions_owner_insert ON public.sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY sessions_owner_update ON public.sessions
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY sessions_owner_delete ON public.sessions
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_sessions_user_started ON public.sessions (user_id, started_at DESC);

CREATE TABLE IF NOT EXISTS public.set_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  exercise_name text NOT NULL,
  set_number integer,
  target_reps text,
  target_weight numeric,
  actual_reps integer,
  actual_weight numeric,
  rpe numeric,
  is_compound boolean,
  logged_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.set_logs ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY set_logs_owner_select ON public.set_logs
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY set_logs_owner_insert ON public.set_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY set_logs_owner_update ON public.set_logs
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY set_logs_owner_delete ON public.set_logs
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_set_logs_session ON public.set_logs (session_id, set_number ASC);
CREATE INDEX IF NOT EXISTS idx_set_logs_user ON public.set_logs (user_id, logged_at DESC);

-- ----------------------------------------------------------------------------
-- SECTION 7: recovery_logs + recovery_day_logs
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.recovery_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  logged_at timestamptz NOT NULL DEFAULT now(),
  hrv numeric NOT NULL DEFAULT 0,
  resting_hr numeric NOT NULL DEFAULT 0,
  sleep_hours numeric NOT NULL DEFAULT 0,
  sleep_score numeric NOT NULL DEFAULT 0,
  muscle_soreness numeric NOT NULL DEFAULT 0,
  stress_level numeric NOT NULL DEFAULT 0,
  nutrition_compliance numeric NOT NULL DEFAULT 0,
  readiness_score numeric,
  adjusted_volume numeric,
  recommendation text,
  recovery_tips text[] DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.recovery_logs ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY recovery_logs_owner_select ON public.recovery_logs
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY recovery_logs_owner_insert ON public.recovery_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY recovery_logs_owner_update ON public.recovery_logs
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY recovery_logs_owner_delete ON public.recovery_logs
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_recovery_logs_user_logged ON public.recovery_logs (user_id, logged_at DESC);

CREATE TABLE IF NOT EXISTS public.recovery_day_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  logged_at timestamptz NOT NULL DEFAULT now(),
  activities text[] NOT NULL DEFAULT '{}',
  readiness_score numeric,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.recovery_day_logs ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY recovery_day_logs_owner_select ON public.recovery_day_logs
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY recovery_day_logs_owner_insert ON public.recovery_day_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY recovery_day_logs_owner_update ON public.recovery_day_logs
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY recovery_day_logs_owner_delete ON public.recovery_day_logs
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_recovery_day_logs_user ON public.recovery_day_logs (user_id, logged_at DESC);

-- ----------------------------------------------------------------------------
-- SECTION 8: programs + program_weeks + program_days + program_exercises
--   programs: public read (is_public OR owned), no client write
--   program_weeks/days/exercises: public read (catalog detail), no client write
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.programs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  goal text,
  level text NOT NULL DEFAULT 'intermediate',
  duration_weeks integer NOT NULL DEFAULT 4,
  sessions_per_week integer NOT NULL DEFAULT 3,
  methodology text,
  methodology_notes text,
  phases jsonb,
  influences text[] DEFAULT '{}',
  is_public boolean NOT NULL DEFAULT false,
  is_featured boolean,
  brand_color text,
  deload_frequency_weeks integer,
  training_age_months_min integer,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY programs_read ON public.programs
    FOR SELECT USING (is_public = true OR created_by = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY programs_owner_insert ON public.programs
    FOR INSERT WITH CHECK (auth.uid() = created_by);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY programs_owner_update ON public.programs
    FOR UPDATE USING (auth.uid() = created_by) WITH CHECK (auth.uid() = created_by);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY programs_owner_delete ON public.programs
    FOR DELETE USING (auth.uid() = created_by);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_programs_public ON public.programs (is_public, created_at DESC);

CREATE TABLE IF NOT EXISTS public.program_weeks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id uuid NOT NULL REFERENCES public.programs(id) ON DELETE CASCADE,
  week_number integer NOT NULL,
  phase text NOT NULL DEFAULT 'base',
  volume_modifier numeric NOT NULL DEFAULT 1.0,
  intensity_modifier numeric NOT NULL DEFAULT 1.0,
  focus_note text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.program_weeks ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY program_weeks_read ON public.program_weeks
    FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.program_days (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id uuid NOT NULL REFERENCES public.programs(id) ON DELETE CASCADE,
  week_number integer NOT NULL,
  day_number integer NOT NULL,
  title text,
  focus text,
  description text,
  duration_minutes integer,
  muscle_groups text[] DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.program_days ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY program_days_read ON public.program_days
    FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.program_exercises (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  program_day_id uuid NOT NULL REFERENCES public.program_days(id) ON DELETE CASCADE,
  exercise_id text REFERENCES public.exercises(id) ON DELETE SET NULL,
  exercise_name text NOT NULL,
  sets integer NOT NULL DEFAULT 3,
  rep_range text NOT NULL DEFAULT '8-12',
  reps_min integer,
  reps_max integer,
  rpe_target numeric,
  rest_seconds integer,
  weight_increment_kg numeric,
  progression_type text,
  sort_order integer NOT NULL DEFAULT 0,
  notes text,
  rationale text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.program_exercises ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY program_exercises_read ON public.program_exercises
    FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ----------------------------------------------------------------------------
-- SECTION 9: user_programs + program_session_logs + progression_records
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_programs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  program_id uuid NOT NULL REFERENCES public.programs(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'active',
  current_week integer NOT NULL DEFAULT 1,
  current_day integer NOT NULL DEFAULT 1,
  current_phase text NOT NULL DEFAULT 'base',
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  settings jsonb,
  notes text,
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.user_programs ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY user_programs_owner_select ON public.user_programs
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY user_programs_owner_insert ON public.user_programs
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY user_programs_owner_update ON public.user_programs
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY user_programs_owner_delete ON public.user_programs
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_user_programs_user ON public.user_programs (user_id);

CREATE TABLE IF NOT EXISTS public.program_session_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_program_id uuid NOT NULL REFERENCES public.user_programs(id) ON DELETE CASCADE,
  program_day_id uuid NOT NULL REFERENCES public.program_days(id) ON DELETE CASCADE,
  completed_at timestamptz NOT NULL DEFAULT now(),
  readiness_score numeric,
  rating integer,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.program_session_logs ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY program_session_logs_owner_select ON public.program_session_logs
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY program_session_logs_owner_insert ON public.program_session_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY program_session_logs_owner_update ON public.program_session_logs
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY program_session_logs_owner_delete ON public.program_session_logs
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.progression_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  exercise_id text REFERENCES public.exercises(id) ON DELETE SET NULL,
  program_exercise_id uuid REFERENCES public.program_exercises(id) ON DELETE SET NULL,
  session_id uuid REFERENCES public.sessions(id) ON DELETE SET NULL,
  weight numeric NOT NULL DEFAULT 0,
  reps_completed integer[] NOT NULL DEFAULT '{}',
  rpe numeric,
  hit_all_reps boolean NOT NULL DEFAULT false,
  ready_to_progress boolean NOT NULL DEFAULT false,
  recorded_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.progression_records ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY progression_records_owner_select ON public.progression_records
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY progression_records_owner_insert ON public.progression_records
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY progression_records_owner_update ON public.progression_records
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY progression_records_owner_delete ON public.progression_records
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_progression_records_user ON public.progression_records (user_id, recorded_at DESC);

-- ----------------------------------------------------------------------------
-- SECTION 10: ai_adaptations  (DAI DecisionPacket audit)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ai_adaptations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  session_id uuid REFERENCES public.sessions(id) ON DELETE SET NULL,
  trigger_type text NOT NULL DEFAULT 'dai-adapt',
  status text NOT NULL DEFAULT 'success',
  readiness_score numeric,
  readiness_delta numeric,
  fatigue_index numeric,
  volume_adjustment text,
  volume_trend numeric,
  adapted_plan jsonb,
  narrative jsonb,
  coaching_cue text,
  model_used text,
  tokens_used integer,
  latency_ms integer,
  error_message text,
  estimated_duration_minutes integer,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.ai_adaptations ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY ai_adaptations_owner_select ON public.ai_adaptations
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY ai_adaptations_owner_insert ON public.ai_adaptations
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY ai_adaptations_owner_update ON public.ai_adaptations
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY ai_adaptations_owner_delete ON public.ai_adaptations
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_ai_adaptations_user ON public.ai_adaptations (user_id, created_at DESC);

-- ----------------------------------------------------------------------------
-- SECTION 11: ai_coach_messages  (owner = client_user_id)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ai_coach_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  coach_id uuid,
  message_type text NOT NULL DEFAULT 'coach',
  message_body text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'sent',
  sent_at timestamptz,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.ai_coach_messages ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY ai_coach_messages_owner_select ON public.ai_coach_messages
    FOR SELECT USING (auth.uid() = client_user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY ai_coach_messages_owner_insert ON public.ai_coach_messages
    FOR INSERT WITH CHECK (auth.uid() = client_user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY ai_coach_messages_owner_update ON public.ai_coach_messages
    FOR UPDATE USING (auth.uid() = client_user_id) WITH CHECK (auth.uid() = client_user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY ai_coach_messages_owner_delete ON public.ai_coach_messages
    FOR DELETE USING (auth.uid() = client_user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_ai_coach_messages_client ON public.ai_coach_messages (client_user_id, created_at DESC);

-- ----------------------------------------------------------------------------
-- SECTION 12: coach_memory  (4-layer memory; owner = user_id)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.coach_memory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  memory_type text NOT NULL,
  key text NOT NULL,
  value text NOT NULL,
  confidence numeric(3,2) NOT NULL DEFAULT 0.80 CHECK (confidence >= 0 AND confidence <= 1),
  source text NOT NULL DEFAULT 'conversation',
  source_message_id uuid,
  is_active boolean NOT NULL DEFAULT true,
  last_referenced_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, key)
);
ALTER TABLE public.coach_memory ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY coach_memory_owner_select ON public.coach_memory
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY coach_memory_owner_insert ON public.coach_memory
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY coach_memory_owner_update ON public.coach_memory
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY coach_memory_owner_delete ON public.coach_memory
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_coach_memory_user_type_active ON public.coach_memory (user_id, memory_type, is_active);

-- ----------------------------------------------------------------------------
-- SECTION 13: coach_alerts  (owner = client_id)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.coach_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid,
  client_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  alert_type text NOT NULL DEFAULT 'danger_zone',
  severity text NOT NULL DEFAULT 'medium',
  title text NOT NULL,
  description text NOT NULL DEFAULT '',
  action_suggestion text,
  is_read boolean NOT NULL DEFAULT false,
  is_resolved boolean NOT NULL DEFAULT false,
  resolved_at timestamptz,
  data jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.coach_alerts ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY coach_alerts_owner_select ON public.coach_alerts
    FOR SELECT USING (auth.uid() = client_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY coach_alerts_owner_update ON public.coach_alerts
    FOR UPDATE USING (auth.uid() = client_id) WITH CHECK (auth.uid() = client_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY coach_alerts_owner_delete ON public.coach_alerts
    FOR DELETE USING (auth.uid() = client_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_coach_alerts_client ON public.coach_alerts (client_id, created_at DESC);

-- ----------------------------------------------------------------------------
-- SECTION 14: streaks  (recovery-protected streak tracking; owner = user_id)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.streaks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  streak_type text NOT NULL CHECK (streak_type IN (
    'workout', 'check_in', 'nutrition_log', 'recovery', 'app_open'
  )),
  current_count integer NOT NULL DEFAULT 0,
  longest_count integer NOT NULL DEFAULT 0,
  last_activity_date date,
  last_date date,
  freeze_count integer NOT NULL DEFAULT 0,
  freezes_used integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  started_at timestamptz,
  broken_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, streak_type)
);
ALTER TABLE public.streaks ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY streaks_owner_select ON public.streaks
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY streaks_owner_insert ON public.streaks
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY streaks_owner_update ON public.streaks
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE POLICY streaks_owner_delete ON public.streaks
    FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS idx_streaks_user ON public.streaks (user_id);

-- ----------------------------------------------------------------------------
-- SECTION 15: handle_new_user() SECURITY DEFINER trigger (verbatim)
--   Recreated verbatim from the canonical source (restore_handle_new_user).
--   Insertion is ON CONFLICT DO NOTHING (no duplicate). Adds a free-tier
--   user_subscriptions seed for the new entitlement model (new requirement;
--   profiles insert block preserved verbatim).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
begin
  -- verbatim profiles auto-create (display_name derived, safe defaults via column defaults)
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'display_name',
      new.raw_user_meta_data->>'full_name',
      split_part(coalesce(new.email, ''), '@', 1)
    )
  )
  on conflict (id) do nothing;

  -- seed a free-tier subscription for the new entitlement model (free|pro|coach)
  insert into public.user_subscriptions (user_id, tier, status, started_at)
  values (new.id, 'free', 'active', now())
  on conflict (user_id) do nothing;

  return new;
end;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Backfill any existing auth.users still missing a profile/subscription.
INSERT INTO public.profiles (id, display_name)
SELECT u.id, split_part(coalesce(u.email, ''), '@', 1)
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_subscriptions (user_id, tier, status, started_at)
SELECT p.id, 'free', 'active', now()
FROM public.profiles p
LEFT JOIN public.user_subscriptions s ON s.user_id = p.id
WHERE s.user_id IS NULL
ON CONFLICT (user_id) DO NOTHING;

-- ============================================================================
-- DONE
-- ============================================================================
