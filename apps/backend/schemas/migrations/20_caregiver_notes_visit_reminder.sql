-- Optional linkage: private caregiver notes tied to a visit or reminder (same patient).
ALTER TABLE public.caregiver_notes
  ADD COLUMN IF NOT EXISTS visit_id TEXT NULL,
  ADD COLUMN IF NOT EXISTS reminder_id TEXT NULL;

CREATE INDEX IF NOT EXISTS idx_caregiver_notes_patient_visit
  ON public.caregiver_notes (patient_id, visit_id)
  WHERE visit_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_caregiver_notes_patient_reminder
  ON public.caregiver_notes (patient_id, reminder_id)
  WHERE reminder_id IS NOT NULL;
