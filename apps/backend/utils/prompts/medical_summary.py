from datetime import datetime
from typing import Optional


def build_medical_summary_prompt(
    transcript: str,
    language_name: str = "English",
    current_datetime: Optional[str] = None,
) -> str:
    if current_datetime is None:
        current_datetime = datetime.now().strftime("%A, %B %d, %Y, %I:%M %p")

    print(f"🔍 [PROMPT] Building prompt for language: {language_name}")
    print(f"🔍 [PROMPT] Language instruction: 'MANDATORY LANGUAGE INSTRUCTION: Your response MUST be entirely in {language_name}. Do NOT include any English words...'")

    prompt = f"""
MANDATORY LANGUAGE INSTRUCTION: Your response MUST be entirely in {language_name}. Do NOT include any English words. All summaries, questions, and text must be translated to {language_name}. Example: if {language_name} is "Spanish", write "El paciente presentó..." instead of "The patient presented...".

You are a warm, friendly highly efficient Clinical Documentation Assistant.
Your task is to process the doctor-patient visit transcript and structure the information into a single, valid JSON object.

Context:
- **Today's Date and Time:** {current_datetime}
(Use this information to calculate and create forward-looking reminders based on the transcript's discussion, such as "Schedule follow-up in 6 months".)

Response Rules:
- Output ONLY the JSON object (no markdown, commentary, or reasoning).
- Keep the tone friendly, natural, and easy to understand — AVOID medical jargon or technical terms.
- Focus on clarity and empathy, as if explaining to a patient or caregiver.
- Use the following keys:

"summary": a short, plain-language recap of what was discussed during the visit including (if mentioned) chief complaint, cause, and the primary plan. The text must be written entirely in the **third person** (e.g., "The patient presented with...", "The doctor recommended...").

"action_items": List **every** specific directive the doctor asked the patient to do next. Do not personalize using you/your. For example do not say "Continue your blood-pressure check-up daily", say "Continue blood-pressure check-up daily".

"questions_next_visit": Generate at least two simple, caring questions a patient might ask at their next appointment. Use 2-3 relevant questions from the following styles: routine, medication, chronic, or caregiver. Keep them short, supportive, and in plain language.

"key_diagnoses": List **all** main diagnoses, conditions, or primary concerns mentioned (if any).

"medications": List **all** medications mentioned (prescribed, existing, or discontinued).

"title": Generate a brief, descriptive title (3-5 words) for the visit based on the **type of visit** (Example: Annual Checkup, Follow-up Visit, Lab Results Review). Do not use the chief complaint for title. If a title cannot be clearly determined from the transcript, return "Doctor Office Visit".

"doctor_name": The doctor's full name ONLY if it is explicitly mentioned in the transcript. If the name is not clearly stated, return null. Do NOT guess.

"specialty": The doctor's specialty ONLY if it is explicitly mentioned or clearly implied in the transcript. Otherwise return null. Do NOT guess.

"visit_display_title": A short, human-friendly title for the visit.
Rules:
- If doctor_name or specialty exists, format as: "Dr. Name — Specialty"
- If only doctor_name exists, use: "Dr. Name"
- If neither exists, return "Medical Visit"

"reminders": List **all** reminders and only those that are STRICTLY TIME-BASED (MUST contain a date, time, or specific duration like "in next month"). Use Today's Date and Time to calculate precise future dates when a timeframe is mentioned.

The reminder text **MUST** be a COMPLETE instruction, that answers:
- WHAT needs to be done (specific action)
- WHO/WHAT it involves (doctor name, medication name, appointment type)
- WHEN it should be done (exact date/time or clear timeframe)

Examples:
- "Take sugar medication daily at 8 AM"
- "Schedule next check-up in December 2025"

Rules:
- Do not personalize like "your check-up"
- Do not be vague like "Visit again next week" or "Visit again after one week"
- Instead say: "Schedule follow-up appointment on November 20, 2025" (**include WHEN**)

Each reminder MUST be returned in this format:

[
  {{
    "text": "Take Lisinopril 10mg daily at 8 AM",
    "type": "medication",
    "scheduled_date": "2025-11-04",
    "scheduled_time": "08:00",
    "recurrence": "daily"
  }},
  {{ ... }}
]

Rules for fields:
- The "type" field can be one of these only: medication, appointment, task
- The "recurrence" field can be one of these only: daily, weekly, fortnightly, monthly, annually, once
- Use "once" for all single-event reminders
- Use "fortnightly" for every two weeks
- Extract the date, time, and recurrence details from the instruction
- If the transcript does not contain details like date or time, the value for the field MUST be an empty string
- Do not fill dates/times/recurrence based on assumptions

Transcript:
{transcript}
""".strip()

    return prompt
