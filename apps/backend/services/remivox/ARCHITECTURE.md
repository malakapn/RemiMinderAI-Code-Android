# RemiVox v2 Architecture

**Status:** Stage E — legacy care path retired from production routes  
**Source of truth branch:** `feature/android-v1.4.0-full-port`  
**Working branch:** `cursor/remivox-v2-stage-e-96fc`

## Principles

1. **Backend-controlled, deterministic care assistant** for medication/reminder workflows.
2. **Keep SmallestAI:** Pulse (STT) + Lightning (TTS).
3. **Hydra is optional conversational only** — never the decision maker for protected care actions.
4. **Do not merge Hydra into the care pipeline** — voice / care / conversation stay separate.
5. **Do not merge to `main`** until Stage E review + QA on `feature/android-v1.4.0-full-port`.

## Final production pipeline

```
Audio / text
  → Smallest Pulse STT
  → Language Detection (preserve locale)
  → translate → EN (router keyed on English)
  → Intent Router          (structured IntentResult)
  → Action Executor        (reminder_service / DB)
  → Response Builder       (session language; conditional disclaimer)
  → translate ← user language
  → Smallest Lightning TTS
```

```
Hydra (live WS) — conversational ONLY
  ├── explanation / visit summaries
  ├── caregiver conversations
  └── read-only tools (briefing, caregiver brief, last summary)
  ✗ NO reminder mutations
```

```
Smallest.ai = ears + voice
RemiVox     = care workflow brain
Hydra       = optional conversation layer
```

## Package layout (`apps/backend/services/remivox/`)

| Module | Layer | Status |
|--------|-------|--------|
| `voice.py` | Voice (Pulse / Lightning) | Live |
| `languages.py` | Locales + session language | Live |
| `intents/models.py` | Intent contracts | Live |
| `intents/router.py` | Intent Router | Live |
| `intents/extractors.py` | Entity extraction | Live |
| `actions/executor.py` | Action Layer | Live → reminder_service |
| `actions/types.py` | ActionResult | Live |
| `response/builder.py` | Response Layer | Live |
| `state/conversation.py` | Pending slots via `cache_service` | Live (TTL 5m) |
| `observability.py` | PHI-safe logging | Live |
| `pipeline.py` | `run_care_turn` | Live — **production `/ask` path** |
| `config_audit.py` | Startup test-mode warnings | Live (Stage E) |
| `legacy/handle_prompt.py` | Pre-v2 monolithic handler | **Retired from routes** (rollback only) |

## Production route

`POST /api/remivox/ask` (`route/remivox.py`):

```
enforce_remivox_access
  → Pulse STT (if audio_base64)
  → resolve_session_language
  → run_care_turn(...)   # never handle_prompt
  → Lightning TTS
```

Mobile contract unchanged:

```json
{
  "audio_base64": "...",
  "prompt": "...",
  "timezone": "UTC",
  "auto_detect_language": true,
  "session_id": "optional"
}
```

Also: `reply_language`, `content_type` (existing client fields).

## RemiVox v3 — Pipecat Streaming Pipeline

### Architecture

```
Mobile
  → WS /api/remivox/stream
    → Pipecat Pipeline
      → SmallestSTTService
        (Pulse streaming, eou_timeout_ms=2000)
      → SileroVADAnalyzer
        (interruption handling)
      → RemiVoxProcessor
        (calls run_care_turn)
      → SmallestTTSService
        (Lightning v3.1, speed=0.85)
    → WebSocket audio back to mobile
```

`RemiVoxProcessor` is the bridge between Pipecat and the existing care engine.
It receives finalized STT transcripts, calls `run_care_turn(...)`, and emits
response text downstream for TTS.

### Languages

The v3 streaming path supports **English + Hindi only** (`en`, `hi`). The
language query parameter controls both STT and TTS for the session. Other
languages are rejected before pipeline startup.

### Elderly UX

- `eou_timeout_ms=2000` prevents the STT service from cutting off speakers who
  pause while forming a thought.
- Lightning TTS uses `speed=0.85` for slower, clearer responses.
- Active reminder and medication names are loaded for per-user STT keyword
  boosting.
- SileroVAD supports interruption handling so TTS stops when the user begins
  speaking.

### Legacy path

- `POST /api/remivox/ask` remains available for backward compatibility with
  existing text, audio, and mobile clients.
- `REMIVOX_PIPELINE` controls the active voice path and accepts `pipecat` or
  `legacy`.
- `pipecat` enables `WS /api/remivox/stream` as the primary real-time voice
  path; `legacy` preserves the v2 behavior.

### Care engine unchanged

The deterministic v2 care workflow remains unchanged:

```
Intent Router
  → Action Executor
  → Response Builder
```

All reminder mutations continue through this deterministic care workflow.
Pipecat changes only the streaming voice transport around `run_care_turn`.

Hydra remains limited to knowledge and caregiver conversations, including
explanations, appointment retelling, and read-only caregiver support. Hydra
must not mutate reminders.

### Definition of Done

The following full conversation flows must work in both English and Hindi with
natural pauses and user interruptions:

1. "Remind me to take Metoprolol every morning at 8"
2. "Actually change that to 9"
3. "No, cancel that"
4. "What medicines do I have today?"
5. "Explain my lab results"
6. "Tell my daughter what happened at my appointment"

## Shared helpers still in `remivox_intents.py`

| Symbol | Role |
|--------|------|
| `build_briefing` | Empty-prompt / today briefing + Hydra read tool |
| `build_caregiver_brief` | Caregiver status (executor + Hydra) |
| `hydra_tool_schemas` / `execute_hydra_tool` / `build_hydra_instructions` | Hydra conversational gate |
| `handle_prompt` | **Deprecated shim** → `remivox.legacy` (DeprecationWarning) |

## Hydra role (v2)

**Allowed:** explain lab results, retell appointment to family, prepare doctor questions, general caregiver chat (read-only tools).

**Forbidden — never execute:**

- `CREATE_REMINDER` / `create_reminder`
- `UPDATE_REMINDER` / `update_reminder`
- `COMPLETE_REMINDER` / `complete_reminder`
- `SNOOZE_REMINDER` / `snooze_reminder`
- `SKIP_REMINDER` / `skip_reminder`
- `DELETE_REMINDER` / `delete_reminder`

Path for those: Intent → Validation → Action Executor → Reminder Service → Database.

## Languages

`en`, `hi`, `gu`, `ta`, `pa`, `bn`, `fr`, `pt`, `es`, `de`

Detected language preserved; English forced only when detected/preferred.

## Disclaimer policy

**No disclaimer** for create/read reminders, appointments, summaries, caregiver brief, check-ins.

**Disclaimer only** for `MEDICAL_ADVICE_REFUSAL`.

Tone: *friendly neighbor helping organize care*.

## Conversation state (cache decision)

**Current (Stage D/E):** `cache_service`

- Key: `remivox:state:{user_uuid}:{session_id}`
- TTL: 5 minutes
- Fields: `pending_intent`, `pending_entities`, `missing_slots`, `detected_language`, `updated_at`
- Missing/expired/corrupt → graceful empty (re-clarify)

**Not in Stage E:** Redis / Cloud SQL schema for state.

**Future:** Redis (or equivalent shared cache) for true multi-instance pending-slot continuity. Process-local `cache_service` may drop pending slots across Cloud Run instances without sticky routing — acceptable degrade for now; does not block migration.

## Production configuration checklist

| Flag | Required production value |
|------|---------------------------|
| `REMIVOX_TEST_MODE` | `false` (default) |
| `REMIVOX_TEST_MODE_ALLOW_IN_PROD` | `false` / unset |
| `REMIVOX_TEST_MODE_UIDS` | unset (or QA-only allowlist in non-prod) |

Startup (`main.py` lifespan) calls `audit_remivox_production_config()` and logs **ERROR** if test mode is accidentally enabled in production.

## Stage E (this)

**Status:** Complete on `cursor/remivox-v2-stage-e-96fc`

- Production `/ask` verified → `run_care_turn` only
- `handle_prompt` moved to `services/remivox/legacy/`
- Deprecated shim retained on `remivox_intents.handle_prompt`
- Hydra final safety regression
- Config audit on startup
- Cache/Redis decision documented (no Redis in E)
- Mobile contract unchanged

## Migration stages

| Stage | Scope | Status |
|-------|--------|--------|
| A | Package, models, stubs, docs | Done |
| B | Voice Layer extraction | Done |
| C | Intent Router + Action Executor; Hydra gating | Done |
| D | cache_service state, test-mode, PHI logs, language | Done |
| **E (this)** | Legacy retirement from production routes | **Done — awaiting review** |

## Rollback plan

1. Keep draft PR; do not merge to `main` until QA.
2. If care regressions appear after merge to `feature/android-v1.4.0-full-port`, revert the Stage E commit(s) or temporarily re-wire `_remivox_response` to call `services.remivox.legacy.handle_prompt` (emergency only).
3. Legacy module + deprecated shim remain available until a later cleanup after production confidence.
4. State continues on `cache_service`; no schema rollback required.
