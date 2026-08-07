-- Monetization / subscription columns used by subscription_service.py.
-- These existed in production Cloud SQL but were never captured in earlier migrations.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS plan text NOT NULL DEFAULT 'TRIAL',
  ADD COLUMN IF NOT EXISTS trial_start_date timestamptz NULL,
  ADD COLUMN IF NOT EXISTS trial_end_date timestamptz NULL,
  ADD COLUMN IF NOT EXISTS summary_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS remivox_interaction_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS subscription_source text NULL,
  ADD COLUMN IF NOT EXISTS revenuecat_entitlement_active boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS subscription_updated_at timestamptz NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'users_plan_check'
      AND conrelid = 'public.users'::regclass
  ) THEN
    ALTER TABLE public.users
      ADD CONSTRAINT users_plan_check
      CHECK (plan IN ('TRIAL', 'FREE', 'PREMIUM', 'EXPIRED'));
  END IF;
END $$;

COMMENT ON COLUMN public.users.plan IS
  'Subscription plan: TRIAL | FREE | PREMIUM | EXPIRED';
