# RemiVox v2 Architecture

**Status:** Stage D production hardening (cache state, test-mode, PHI-safe logs)  
**Source of truth branch:** `feature/android-v1.4.0-full-port`  
**Working branch:** `cursor/remivox-v2-stage-d-96fc`

## Principles

1. **Backend-controlled, deterministic care assistant** for medication/reminder workflows.
2. **Keep SmallestAI:** Pulse (STT) + Lightning (TTS).
3. **Hydra is optional conversational only** — never the decision maker for protected care actions.
4. **Do not delete** existing Pulse/Lightning/Hydra/`remivox_intents` until Stages B–E are tested and approved.
5. **Do not merge to `main`** until full Vox v2 passes tests.

## Target pipeline

```
Audio
  → Smallest Pulse STT
  → Language Detection
  → Intent Router          (structured IntentResult)
  → Action Executor        (reminder_service / DB)
  → Response Builder       (session language; conditional disclaimer)
  → Smallest Lightning TTS
```

## Package layout (`apps/backend/services/remivox/`)

| Module | Layer | Stage C status |
|--------|-------|----------------|
| `voice.py` | Voice (Pulse / Lightning) | Live (Stage B) |
| `languages.py` | Locales | Re-exports `remivox_languages` (10 langs) |
| `intents/models.py` | Intent contracts | Live Pydantic models |
| `intents/router.py` | Intent Router | Live deterministic router |
| `intents/extractors.py` | Entity extraction | Live (time/freq/title/match) |
| `actions/executor.py` | Action Layer | Live → reminder_service |
| `actions/types.py` | ActionResult | Live |
| `response/builder.py` | Response Layer | Live neighbor tone + conditional disclaimer |
| `state/conversation.py` | Pending slots | `cache_service` + 5 min TTL |
| `observability.py` | Logging | PHI-safe voice / intent / action logs |
| `pipeline.py` | Orchestration | `run_care_turn` wired from `/ask` |

## Existing foundation (must preserve)

| File | Role |
|------|------|
| `apps/backend/route/remivox.py` | `/today`, `/ask`, `/translate-turn`, `/live`; Pulse; Lightning |
| `apps/backend/services/remivox_intents.py` | Current deterministic intents + Hydra tool schemas |
| `apps/backend/services/remivox_languages.py` | 10-language helpers |
| `apps/backend/services/hydra_live_service.py` | Hydra WS proxy |
| `apps/backend/services/reminder_service.py` | Create / complete / snooze / skip |
| Mobile audio `askVox` + `vox_live_session.dart` | audio_base64 flow |

## Hydra role (v2)

**Allowed (future conversational):** explain lab results, retell appointment to family, prepare doctor questions, general caregiver chat.

**Forbidden:** Hydra must **not** directly execute:

- `CREATE_REMINDER`
- `UPDATE_REMINDER`
- `COMPLETE_REMINDER`
- `SNOOZE_REMINDER`
- `SKIP_REMINDER`
- `DELETE_REMINDER`

Those always require: STT → Intent Router → Action Executor → Backend → Database.

Stage A keeps Hydra infrastructure intact. Stage C will gate/no-op Hydra care tool side-effects.

## Intent catalog

| Intent | Purpose |
|--------|---------|
| `CREATE_REMINDER` | New reminder from speech |
| `UPDATE_REMINDER` | Change time/title/frequency |
| `COMPLETE_REMINDER` | Mark taken |
| `SNOOZE_REMINDER` | Snooze |
| `SKIP_REMINDER` | Skip |
| `DELETE_REMINDER` | Delete (prefer `CONFIRM_ACTION` before execute) |
| `CANCEL_ACTION` | Cancel pending clarify/confirm ("No, cancel that") |
| `CONFIRM_ACTION` | Confirm sensitive pending action |
| `READ_TODAY_MEDICATIONS` | List today's meds |
| `READ_APPOINTMENTS` | Appointments / visits |
| `READ_DOCTOR_SUMMARY` | Latest visit summary |
| `CAREGIVER_BRIEF` | Caregiver patient status |
| `HELP` | Capabilities |
| `CLARIFY` | Ask only for missing slots |
| `MEDICAL_ADVICE_REFUSAL` | Diagnosis / dose / stop / treatment — **only** disclaimer path |
| `UNKNOWN` | Fallback |

### Example structured intent

User: `Set a reminder for Metoprolol at 8 PM every day`

```json
{
  "intent": "CREATE_REMINDER",
  "language": "en",
  "entities": {
    "medication": "Metoprolol",
    "time": "20:00",
    "frequency": "daily"
  }
}
```

## Languages

`en`, `hi`, `gu`, `ta`, `pa`, `bn`, `fr`, `pt`, `es`, `de`

Session language should stick for the Vox conversation (Stage D). Stage B fixes Pulse auto-detect (`multi`, not forced `en`).

## Disclaimer policy

**No disclaimer** for create/read reminders, appointments, summaries, caregiver brief, check-ins.

**Disclaimer only** for `MEDICAL_ADVICE_REFUSAL` (diagnosis, dosage changes, stopping medication, treatment advice).

Tone: *friendly neighbor helping organize care*.

## Stage D (hardening) — current

**Status:** Complete on `cursor/remivox-v2-stage-d-96fc`

- Conversation state stored via `cache_service` (`remivox:state:{user}:{session}`, TTL 5m)
- Missing/expired/corrupt state handled gracefully (re-clarify, no crash)
- `REMIVOX_TEST_MODE` defaults OFF; ignored in production unless `REMIVOX_TEST_MODE_ALLOW_IN_PROD=true`; optional UID allowlist
- Language: detected locale preserved for all 10 supported languages (EN only when detected/preferred)
- Observability is PHI-safe (no transcripts / medication entities in logs)
- Hydra still cannot execute protected care actions
- Legacy `remivox_intents.handle_prompt` retained until Stage E

### State architecture

```
run_care_turn
  → get_state(user, session)
       cache_service.get("remivox:state:{user}:{session}")
  → route_intent(+ pending)
  → execute_intent
  → upsert_pending / clear_state
       cache_service.set(..., ttl=300) / invalidate
```

Note: `cache_service` is process-local today. Multi-instance deploys rely on graceful empty-state behavior (user may need to re-state a slot if sticky routing is absent). No Redis / SQL introduced in Stage D.

## Stage C (Intent + Action)

**Status:** Complete on `cursor/remivox-v2-stage-c-96fc`

Deterministic care flow:

```
Pulse STT → Intent Router → Action Executor → reminder_service/DB
         → Response Builder → Lightning TTS
```

- `POST /api/remivox/ask` calls `run_care_turn` (not Hydra) for care actions
- Hydra schemas/tools are read-only; protected mutations blocked in `execute_hydra_tool`
- Conversation state key shape introduced (`remivox:state:{user}:{session}`, TTL 5m; moved to `cache_service` in Stage D)
- `REMIVOX_TEST_MODE=true` bypasses trial gate for QA only (hardened in Stage D)
- Disclaimer only for `MEDICAL_ADVICE_REFUSAL`

## Stage B (Voice Layer extraction)

**Status:** Complete on `cursor/remivox-v2-stage-b-96fc`

- Pulse STT + Lightning TTS live in `services/remivox/voice.py`
- `route/remivox.py` keeps `/ask` contract; thin wrappers call Voice Layer
- Bug fix: `auto_detect_language=true` → Pulse `language=multi` (via `resolve_stt_language`)
- TTS uses reply language (hi/bn/gu/…); English fallback only if locale TTS fails

### Old vs new care flow

```
OLD: audio → Pulse → handle_prompt (legacy) → Lightning
     Hydra tools could create/complete/snooze/skip reminders

NEW (Stage C):
  audio → Pulse (multi)
       → translate to EN for router (if needed)
       → remivox.intents.router.route_intent
       → remivox.actions.executor.execute_intent → reminder_service
       → remivox.response.builder.build_response
       → Lightning TTS (reply language)
  Hydra: conversational/read-only only
```

## Migration stages

| Stage | Scope | Prod behavior change? |
|-------|--------|------------------------|
| A | Package, models, stubs, docs, test skeleton | No |
| B | Move Pulse/Lightning into `voice.py`; fix language detect | Voice only |
| C | Intent Router + Action Executor; Hydra care gating | Care path live |
| **D (this)** | cache_service state, test-mode harden, PHI logs, language validation | Hardening |
| E | Deprecate legacy `handle_prompt` shim | Yes (not started) |
