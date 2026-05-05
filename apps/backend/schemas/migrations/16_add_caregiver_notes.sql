-- Migration 16: Add caregiver_notes table
CREATE TABLE IF NOT EXISTS public.caregiver_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caregiver_id TEXT NOT NULL,
    patient_id TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_caregiver_notes_caregiver_id ON public.caregiver_notes(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_caregiver_notes_patient_id ON public.caregiver_notes(patient_id);
