-- =========================================
-- ai_usage table
-- =========================================
CREATE TABLE public.ai_usage (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  input_tokens integer NULL,
  output_tokens integer NULL,
  total_cost numeric(10, 6) NULL,
  visit_id uuid NULL,
  transcript_id uuid NULL,
  user_id uuid NULL,
  CONSTRAINT ai_usage_pkey PRIMARY KEY (id)
);

-- =========================================
-- ai_usage indexes
-- =========================================
CREATE INDEX IF NOT EXISTS idx_ai_usage_visit_id
  ON public.ai_usage (visit_id);

CREATE INDEX IF NOT EXISTS idx_ai_usage_created_at
  ON public.ai_usage (created_at);

-- =========================================
-- prompt_bank table
-- =========================================
CREATE TABLE public.prompt_bank (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  prompt_category text NOT NULL,
  prompt_text text NOT NULL,
  tone text NULL,
  example_input text NULL,
  example_output text NULL,
  source text NOT NULL DEFAULT 'Seed Prompt',
  rating integer NOT NULL DEFAULT 5,
  version text NOT NULL DEFAULT 'v1.0',
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT prompt_bank_pkey PRIMARY KEY (id),
  CONSTRAINT prompt_bank_rating_check CHECK (
    rating BETWEEN 1 AND 5
  )
);

-- =========================================
-- prompt_bank indexes
-- =========================================
CREATE INDEX IF NOT EXISTS idx_prompt_bank_category
  ON public.prompt_bank (prompt_category);

CREATE INDEX IF NOT EXISTS idx_prompt_bank_rating
  ON public.prompt_bank (rating DESC);

CREATE INDEX IF NOT EXISTS idx_prompt_bank_category_rating
  ON public.prompt_bank (prompt_category, rating DESC);

-- =========================================
-- best_examples table
-- =========================================
CREATE TABLE public.best_examples (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  example_input text NOT NULL,
  example_output text NOT NULL,
  tone text NULL,
  category text NULL,
  approved_by text NULL,
  source_summary_id uuid NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT best_examples_pkey PRIMARY KEY (id)
);

-- =========================================
-- best_examples indexes
-- =========================================
CREATE INDEX IF NOT EXISTS idx_best_examples_category
  ON public.best_examples (category);

-- =========================================
-- summaries_log table
-- =========================================
CREATE TABLE public.summaries_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  transcript_id uuid NOT NULL,
  visit_id uuid NULL,
  user_id uuid NULL,
  model_name text NOT NULL,
  summary_text text NOT NULL,
  latency_ms integer NULL,
  tokens_in integer NULL,
  tokens_out integer NULL,
  cost_usd numeric(10, 6) NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT summaries_log_pkey PRIMARY KEY (id)
);

-- =========================================
-- summaries_log indexes
-- =========================================
CREATE INDEX IF NOT EXISTS idx_summaries_log_transcript_id
  ON public.summaries_log (transcript_id);

CREATE INDEX IF NOT EXISTS idx_summaries_log_created_at
  ON public.summaries_log (created_at DESC);

-- =========================================
-- feedback_log table
-- =========================================
CREATE TABLE public.feedback_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  summary_id uuid NOT NULL,
  user_id uuid NULL,
  feedback_score integer NOT NULL,
  comments text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT feedback_log_pkey PRIMARY KEY (id),
  CONSTRAINT feedback_log_feedback_score_check CHECK (
    feedback_score IN (-1, 1)
  )
);

-- =========================================
-- feedback_log indexes
-- =========================================
CREATE INDEX IF NOT EXISTS idx_feedback_log_summary_id
  ON public.feedback_log (summary_id);

CREATE INDEX IF NOT EXISTS idx_feedback_log_score
  ON public.feedback_log (feedback_score);


-- =========================================
-- audit_log table
-- =========================================
CREATE TABLE public.audit_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  actor_user_id uuid NULL,
  action text NOT NULL,
  entity text NULL,
  entity_id uuid NULL,
  metadata jsonb NULL,
  ip_address inet NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT audit_log_pkey PRIMARY KEY (id)
);

-- =========================================
-- audit_log indexes
-- =========================================
CREATE INDEX IF NOT EXISTS idx_audit_created
  ON public.audit_log (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_actor
  ON public.audit_log (actor_user_id);
