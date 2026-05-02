-- Idempotent log for server-triggered "reminder due" FCM (cron).
CREATE TABLE IF NOT EXISTS public.reminder_due_push_log (
  reminder_id UUID NOT NULL REFERENCES public.reminders (id) ON DELETE CASCADE,
  scheduled_time TIMESTAMPTZ NOT NULL,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (reminder_id, scheduled_time)
);

CREATE INDEX IF NOT EXISTS idx_reminder_due_push_log_sent_at
  ON public.reminder_due_push_log (sent_at);
