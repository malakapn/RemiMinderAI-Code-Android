-- Shadow care_team_members row at invite time (pending, NULL member until accept).
-- Aligns with email deep-link accept flow.

ALTER TABLE public.care_team_members
  ALTER COLUMN member_user_id DROP NOT NULL;

ALTER TABLE public.care_team_members
  ADD COLUMN IF NOT EXISTS invitee_email citext NULL;

CREATE INDEX IF NOT EXISTS care_team_members_invitee_pending_idx
  ON public.care_team_members (patient_id, invitee_email)
  WHERE status = 'pending';
