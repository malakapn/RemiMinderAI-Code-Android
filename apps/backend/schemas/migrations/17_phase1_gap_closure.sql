-- Phase 1 gap closure: alert types, dedupe context, PHI access log, notes audit, consent metadata

-- Caregiver alerts: allow new alert_type values; optional context_id for dedupe (visit summary, missed job, etc.)
ALTER TABLE public.caregiver_alerts
  DROP CONSTRAINT IF EXISTS caregiver_alerts_alert_type_check;

ALTER TABLE public.caregiver_alerts
  ADD COLUMN IF NOT EXISTS context_id text NULL;

CREATE INDEX IF NOT EXISTS idx_caregiver_alerts_user_type_context
  ON public.caregiver_alerts (user_id, alert_type, context_id)
  WHERE context_id IS NOT NULL;

-- PHI access log (Firebase UID text; no dependency on audit_log.uuid)
CREATE TABLE IF NOT EXISTS public.phi_access_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_firebase_uid text NOT NULL,
  patient_id text NULL,
  resource text NOT NULL,
  route text NULL,
  ip_address text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_phi_access_actor_created
  ON public.phi_access_log (actor_firebase_uid, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_phi_access_patient_created
  ON public.phi_access_log (patient_id, created_at DESC)
  WHERE patient_id IS NOT NULL;

-- Caregiver notes audit trail
CREATE TABLE IF NOT EXISTS public.caregiver_notes_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id uuid NOT NULL,
  caregiver_id text NOT NULL,
  patient_id text NOT NULL,
  action text NOT NULL,
  old_title text NULL,
  old_content text NULL,
  new_title text NULL,
  new_content text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_caregiver_notes_audit_note
  ON public.caregiver_notes_audit (note_id, created_at DESC);

-- Consent metadata when caregiver joins care team (invitation accept)
ALTER TABLE public.care_team_members
  ADD COLUMN IF NOT EXISTS consent_version text NULL,
  ADD COLUMN IF NOT EXISTS consent_accepted_at timestamptz NULL;
