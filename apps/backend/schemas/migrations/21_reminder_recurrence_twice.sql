-- Allow "twice" (e.g. twice-daily) in reminders.recurrence CHECK constraint.
ALTER TABLE public.reminders
DROP CONSTRAINT IF EXISTS reminders_recurrence_check;

ALTER TABLE public.reminders
ADD CONSTRAINT reminders_recurrence_check CHECK (
  recurrence IS NULL OR recurrence IN (
    'daily',
    'weekly',
    'fortnightly',
    'monthly',
    'annually',
    'once',
    'twice'
  )
);
