-- Per-user opt-out for caregiver alert emails (SES). In-app mobile toggles sync to this column.
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS caregiver_alert_email_enabled boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.users.caregiver_alert_email_enabled IS
  'When false, caregiver alert emails (missed reminders, skips, symptom summaries) are not sent to this user''s email.';
