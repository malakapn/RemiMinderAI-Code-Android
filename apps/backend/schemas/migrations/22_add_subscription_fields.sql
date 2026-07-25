-- =========================================
-- Subscription / Trial / Monetization Fields
-- =========================================

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS plan text NOT NULL DEFAULT 'TRIAL',
  ADD COLUMN IF NOT EXISTS trial_start_date timestamptz NULL,
  ADD COLUMN IF NOT EXISTS trial_end_date timestamptz NULL,
  ADD COLUMN IF NOT EXISTS summary_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS remivox_interaction_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS subscription_source text NULL,
  ADD COLUMN IF NOT EXISTS revenuecat_app_user_id text NULL,
  ADD COLUMN IF NOT EXISTS revenuecat_entitlement_active boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS subscription_updated_at timestamptz NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'users_plan_allowed'
  ) THEN
    ALTER TABLE public.users
      ADD CONSTRAINT users_plan_allowed
      CHECK (plan IN ('TRIAL', 'FREE', 'PREMIUM', 'EXPIRED'));
  END IF;
END $$;

UPDATE public.users
SET
  trial_start_date = COALESCE(trial_start_date, created_at, now()),
  trial_end_date = COALESCE(trial_end_date, COALESCE(created_at, now()) + interval '14 days')
WHERE plan = 'TRIAL'
  AND (trial_start_date IS NULL OR trial_end_date IS NULL);
