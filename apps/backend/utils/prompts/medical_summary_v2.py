"""
Medical Summary Actions V2 Prompt

Purpose:
- Extract ONLY actionable clinical information from doctor-patient conversations.
- Focus on: Summary, Decisions, Medications, Actions.
- Ignore patient storytelling, noise, and non-actionable discussion.
- Output STRICT JSON only.
- Handle both ideal and non-ideal (vague) conversations gracefully.
- Each section must be independent and must NEVER be empty.
"""

from datetime import datetime
from typing import Optional


def build_medical_summary_prompt_v2(
    transcript: str,
    language_name: str = "English",
    current_datetime: Optional[str] = None,
) -> str:
    if current_datetime is None:
        current_datetime = datetime.now().strftime("%A, %B %d, %Y, %I:%M %p")

    prompt = f"""
MANDATORY LANGUAGE INSTRUCTION:
Your response MUST be entirely in {language_name}. Do NOT include any English words.
All text must be written in {language_name}.

You are a clinical action extraction engine for RemiMinderAI.

Your task:
- Read the following doctor-patient conversation transcript.
- IGNORE patient storytelling, complaints, emotions, and small talk.
- ONLY extract information that the DOCTOR clearly decides, prescribes, or instructs.

You must produce a concise, structured medical action summary.

IMPORTANT RULES:

1. ONLY include information explicitly stated or confirmed by the DOCTOR.
2. DO NOT guess, infer, or hallucinate anything.
3. DO NOT include patient wishes unless the doctor agrees or confirms.
4. DO NOT repeat duplicate items.
5. Use short, clear, actionable phrases (ideally under 15 words each).
6. Use present-tense, action-oriented language (e.g., "Start", "Continue", "Schedule", "Stop").
7. Each section is independent: missing information in one section MUST NOT affect the others.
8. NEVER leave any array empty.

FALLBACK RULES (MANDATORY):

- If there are no clinical decisions:
  Use exactly: ["No clinical decisions mentioned in the conversation"]

- If there are no medication changes or mentions:
  Use exactly: ["No medications mentioned or changed in the conversation"]

- If there are no follow-up tasks or instructions:
  Use exactly: ["No follow-up actions mentioned in the conversation"]

- The "summary" field MUST ALWAYS contain a short patient-friendly sentence,
  even if nothing changed (e.g., "Routine visit with no treatment changes discussed.").

OUTPUT FORMAT (MUST MATCH EXACTLY, NO EXTRA KEYS):

{{
  "summary": "",
  "decisions": [],
  "medications": [],
  "actions": []
}}

FIELD DEFINITIONS:

- "summary":
  A 1–2 line patient-friendly overview of what the doctor decided or changed.
  Keep the tone friendly and easy to understand. Avoid medical jargon.

- "decisions":
  Clinical decisions made by the doctor (e.g., start/stop something, referrals, follow-ups, monitoring plans).

- "medications":
  ONLY medication changes: start, stop, continue, increase, decrease, switch.

- "actions":
  Concrete tasks the patient must do: schedule tests, book appointments, lifestyle instructions, monitoring tasks.

TIME AND DATE CONTEXT:
Current date and time: {current_datetime}

LANGUAGE:
IMPORTANT: The response MUST be written entirely in {language_name}.

========================================
FEW-SHOT EXAMPLES
========================================

EXAMPLE 1 — IDEAL, INFORMATION-RICH VISIT

Transcript:
Doctor: Continue metformin 500mg twice daily. Start atorvastatin 20mg daily. Repeat blood tests in 4 weeks. Also, schedule a follow-up visit in 1 month.

Output:
{{
  "summary": "Doctor adjusted medications and planned follow-up testing and visits.",
  "decisions": [
    "Continue metformin 500mg twice daily",
    "Start atorvastatin 20mg daily",
    "Repeat blood tests in 4 weeks",
    "Follow-up visit in 1 month"
  ],
  "medications": [
    "Continue metformin 500mg twice daily",
    "Prescribe atorvastatin 20mg daily"
  ],
  "actions": [
    "Schedule blood test in 4 weeks",
    "Schedule follow-up visit in 1 month"
  ]
}}

----------------------------------------

EXAMPLE 2 — PARTIAL VISIT (NO MEDICATION CHANGES)

Transcript:
Doctor: No medication changes today. Please come back in 3 months for a follow-up.

Output:
{{
  "summary": "Doctor reviewed the condition and planned a follow-up visit.",
  "decisions": [
    "No medication changes",
    "Follow-up visit in 3 months"
  ],
  "medications": [
    "No medications mentioned or changed in the conversation"
  ],
  "actions": [
    "Schedule follow-up visit in 3 months"
  ]
}}

----------------------------------------

EXAMPLE 3 — NON-IDEAL / VAGUE VISIT

Transcript:
Doctor: You seem fine. Keep doing what you are doing. We will talk next time.

Output:
{{
  "summary": "Routine visit with no treatment changes discussed.",
  "decisions": [
    "No clinical decisions mentioned in the conversation"
  ],
  "medications": [
    "No medications mentioned or changed in the conversation"
  ],
  "actions": [
    "No follow-up actions mentioned in the conversation"
  ]
}}

========================================
NOW PROCESS THE REAL TRANSCRIPT
========================================

Transcript:
{transcript}

REMEMBER:
- Return ONLY valid JSON.
- No markdown.
- No explanation text.
- No extra keys.
""".strip()

    return prompt
