# RemiVox v2 Architecture

**Status:** Stage A scaffold only (no production behavior change)  
**Source of truth branch:** `feature/android-v1.4.0-full-port`  
**Working branch:** `cursor/remivox-v2-stage-a-96fc`

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

| Module | Layer | Stage A |
|--------|-------|---------|
| `voice.py` | Voice (Pulse / Lightning) | Stub — prod STT/TTS stay in `route/remivox.py` |
| `languages.py` | Locales | Re-exports `remivox_languages` (10 langs) |
| `intents/models.py` | Intent contracts | **Live** Pydantic models |
| `intents/router.py` | Intent Router | Stub → `UNKNOWN` |
| `intents/extractors.py` | Entity extraction | Stub |
| `actions/executor.py` | Action Layer | Stub (no DB writes) |
| `response/builder.py` | Response Layer | Stub + disclaimer policy constants |
| `state/conversation.py` | Pending slots | In-memory stub + 5 min TTL |
| `observability.py` | Logging | Structured log helper |
| `pipeline.py` | Orchestration | Raises `NotImplementedError` |

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

## Migration stages

| Stage | Scope | Prod behavior change? |
|-------|--------|------------------------|
| **A (this)** | Package, models, stubs, docs, test skeleton | **No** |
| B | Move Pulse/Lightning into `voice.py`; fix language detect | Yes (Voice) |
| C | Intent router + Action Executor; gate Hydra care tools | Yes |
| D | Conversation state + sticky language | Yes |
| E | Cutover `/ask` to `pipeline.run`; deprecate shim | Yes |

## Stage A explicit non-goals

- No edits to production routing logic in `route/remivox.py`
- No changes to `hydra_live_service.py` behavior
- No removal of `remivox_intents.py`
- No mobile client changes
- No merge to `main`
