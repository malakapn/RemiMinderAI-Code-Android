# Visit Details — Missing “Next Steps” (1.3.1+56 investigation)

**Date:** 2026-05-04  
**Branch:** `fix/three-regressions` (post–`8d26664`)  
**Scope:** Visit Details → structured summary cards only.

## 1. Diff findings (Flutter)

Comparing `origin/main` and `origin/fix/three-regressions` for `apps/mobile/lib/features/patient/presentation/screens/visit_details_screen.dart`:

- The **only** change in the structured-summary stack is the **title string** of the third list: **`Next Steps` → `Questions for Your Next Visit`** (wrapped across extra lines).  
- **No widget was removed.** The third card is still emitted as  
  `if (_actions.isNotEmpty) _buildListSection(...)`  
  unchanged from `main`.
- Parsing is unchanged: `_actions` still comes **only** from  
  `final actions = _toStringList(data['actions']);`  
  (same as an older **1.3.1+54–era** tree, e.g. `f89fd5a`).

So the **absence** of the third card in +56 is not explained by “the section was deleted in Dart.” It means **`_actions` is empty at runtime** (or the API never returns a non-empty `actions` list that survives parsing).

## 2. API / JSON contract (backend, `8d26664`)

**`apps/backend/route/visit_summary.py`** (on `fix/three-regressions`) adds:

- **`_coerce_string_list`** — only treats `None`, non-empty `str`, or `list` (flattened via `str(x)` per element). **Dicts and other shapes yield `[]`.**
- **`_normalize_structured_summary_payload`** — before returning `GET /api/visits/{visit_id}/summary-structured`, maps stored JSON into the shape the app expects:
  - **`actions`**: from `actions`, else **`questions_next_visit`**, else **`action_items`**
  - **`decisions`**: from `decisions`, else **`key_diagnoses`**
  - **`medications`**: from **`medications`**
- **`summary`**: passed through as part of the same object (unchanged by normalization).

On **`main`**, the same route returned **`structured_data` raw** from `summaries_log.structured_data_json` with **no** merging.

**Pipeline / prompts (context):**

- **V1** prompt (`medical_summary.py`) uses **`action_items`**, **`questions_next_visit`**, **`key_diagnoses`**, **`medications`**, **`summary`**, etc. — not `actions` / `decisions` in the prompt text.
- **V2** prompt + **`normalize_v2_summary`** produce **`summary` / `decisions` / `medications` / `actions`** as string lists (normalizer uses **`_ensure_string_list`**, which **handles dict-shaped list items**).

## 3. Older working build (+53 / +54 baseline)

From **`f89fd5a`** (`1.3.1+54` bump), `visit_details_screen.dart` already:

- Parsed **`data['actions']`** only (no `action_items` fallback in the client).
- Rendered the third list when **`_actions.isNotEmpty`**, titled **`Next Steps`**.

So the **long-standing mobile contract** for the third block is **`actions`**. The **intended clinical content** for that card (per product copy and screenshots) is **doctor-directed imperatives** (“Gradually reduce…”, “Take 650 mg…”), which align with **V1 `action_items`** / **V2 `actions`**, not patient “questions to ask” copy.

## 4. Root cause (PM-readable)

**What users see:** Only **Visit Summary** and **Medications**; **nothing below Medications.**

**What the code does:** The third card is **still there in code**, but it only draws when the **`actions` list is non-empty** after the API response is parsed.

**Why `actions` can be empty after `8d26664`:** The new server-side normalizer is a **`list`/`str`-only coercer**. If the stored Gemini JSON has **action-like content under a key the app never reads** (`action_items` only on the wire with a **non-list shape** — e.g. a **single object** instead of an array — or another rare shape `_coerce_string_list` drops), then all three fallbacks can end up **empty**, so **`actions` becomes `[]`** and Flutter hides the section entirely.

Separately, **-merge order** today is **`actions` → `questions_next_visit` → `action_items`**. For older **V1-shaped rows** where **`actions` is missing** but **both** questions and action items exist, the API will **fill `actions` from questions first**. That would **still show a third card**, but with **question** text — not the reported “blank” case, unless questions are also empty.

The **UI label change** to **“Questions for Your Next Visit”** does **not** remove the card; it **misaligned copy** with the product expectation (**Next Steps** + **imperatives**).

**Classification:** Primarily **JSON shape / coercion + conditional UI** (with a secondary **wrong label / wrong merge priority** relative to product intent). **Not** “Flutter deleted the section.”

## 5. Proposed fix (after approval)

| Area | File | Change |
|------|------|--------|
| **Backend (recommended)** | `apps/backend/route/visit_summary.py` | Reuse or mirror **`_ensure_string_list`** from `apps/backend/services/ai/summary_normalizer_v2.py` when building `actions`, `decisions`, and `medications` so **dict / nested structures** from Gemini are flattened to strings instead of disappearing. **Optionally** set merge order to **`actions` → `action_items` → `questions_next_visit`** so **Next Steps** prefers **imperatives** over **questions** when filling `actions`. |
| **Mobile** | `apps/mobile/lib/features/patient/presentation/screens/visit_details_screen.dart` | Restore the third section title to **`Next Steps`**. Optional **defensive** parse: if `actions` is empty, merge **`action_items`** (only if you want a client-side safety net; backend fix is preferable). |

**Version bump (execution phase):** `pubspec.yaml` → **1.3.1+57** per release plan.  
**Commit message (execution phase):**  
`fix(summary): restore Next Steps section in Visit Details (regression from 8d26664)`

## 6. Mobile-only vs backend

- **Backend fix** addresses **all clients** and fixes **empty `actions`** at the source when shapes are richer than `_coerce_string_list` supports.
- **Mobile-only** (title + client-side fallback keys) can **partially** mask gaps but duplicates contract logic; **not ideal** if the API remains the canonical place for v1→v2 shape mapping.

## 7. Estimated scope

**Small:** One backend helper swap / merge-order tweak, one Flutter string (optional small client fallback). No changes to recording, home, router, splash, welcome, invites, or caregiver dashboard.

## 8. Open validation

If a production **sample JSON** body from `GET .../summary-structured` for an affected visit still shows **non-empty `action_items`** and **empty `actions`** after the proposed coercion fix, extend fallbacks (e.g. additional **legacy keys**) in the same normalizer.
