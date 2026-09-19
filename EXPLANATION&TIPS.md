# Khatwa · how to explain it, and what to do next

Written for the team. Read it once tonight, once before the pitch.

---

# PART 1 · How to talk about your project

## The one sentence

> "Khatwa lets a diabetic patient check their feet every day with their phone, and puts a real doctor at the end of every case."

Say that first. Everything else is detail.

## The 30 second version

> "In diabetes, you lose feeling in your feet, so a small crack becomes an ulcer, then an infection, then an amputation. Nobody sees it coming because nobody looks at the bottom of their own feet. Khatwa guides the patient to photograph their feet and answer a few questions. The app sorts the case into green, orange or red, and sends it to a health professional who confirms and decides where the patient goes. We never diagnose. We spot and we sort, the doctor decides."

## The 2 minute version, in this order

1. **The problem, with a face.** A person with diabetes in a rural area, who walks on a wound for three weeks without feeling it. In a Tunisian study in Mahdia, 27% of diabetic patients were already at risk of a foot ulcer.
2. **Where the app fits.** Between the home and the SSB. Daily at home, reviewed by a professional, referred when needed.
3. **What the patient does.** Photos guided step by step, 8 questions, a result in derja.
4. **What the professional does.** A queue of cases, red first, with the photos and the AI's proposal. They confirm or change it, and choose the orientation.
5. **The safety design.** Two layers: fixed clinical rules, plus the AI. The rules can only make an alert more serious, never less. If the patient says there is a wound, the case is red whatever the AI says.
6. **The system fit.** Every case exports as a FHIR bundle, the standard the hospital system speaks. We are not building another island.
7. **What is next.** A real dataset with a clinical partner, and a measurement of how often the app agrees with the doctor.

## The sentence that wins points

> "The AI can be wrong, so we designed as if it will be. The clinical rules run with or without the AI, and they can only raise the alert level. Nothing in the safety path depends on the model or on the network."

Juries remember the team that knows where their own weakness is.

## What to say about the AI, exactly

Say this:

> "We use a multimodal model that reads the photos and the answers and returns a structured result. We did not train it ourselves, and we have not yet measured it against a labelled dataset. That is our next step, with a clinical partner."

Do **not** say "our AI detects ulcers with high accuracy". You have not measured it. One question from a jury member and the whole pitch loses credibility.

## What to say about interoperability, in simple words

> "A case leaves the app as a FHIR bundle. FHIR is the language hospital systems use to exchange patient data. So the photos, the questions, the AI result and the doctor's referral arrive in a format the Ministry's system can read directly."

If they push further: Patient, QuestionnaireResponse, Observation, Media, RiskAssessment, ServiceRequest, Provenance. Open the export in the app and show it. That moment is worth more than any slide.

## What to say about security

> "Passwords are hashed. There is a PIN on top. Everything stored on the device is encrypted and the key is locked by that PIN, so signing out leaves unreadable data behind. The patient ticks consent before anything is sent, and without consent to be named the doctor sees only initials. Every access to a case is recorded."

Then add the honest half:

> "For a real deployment we need a server, INPDP authorisation, and the national health identifier. We know that."

---

# PART 2 · Questions the jury will ask

**"Did you train your own model?"**
No. We use a general vision model with a clinical prompt. Training one needs a labelled dataset of real diabetic feet, which does not exist publicly for early signs, only for existing ulcers. Building that dataset with a clinical partner is our next step.

**"What if the AI is wrong?"**
Two answers. First, the clinical rules run independently and can only raise the level, so the dangerous case is never downgraded by the model. Second, no case reaches a patient as a decision. A professional validates every one.

**"How is this different from sending a photo on WhatsApp?"**
Four things. The capture is guided, so the photo is usable. The questions are structured, so the doctor gets the context. The case arrives sorted by severity in a queue instead of lost in a chat. And it exports to the hospital system in FHIR, with a traceable record of who saw what.

**"Why not a thermal camera or pressure sensors?"**
The evidence is real for temperature: IWGDF recommends daily foot temperature checks for high risk patients. But no household in Tunisia owns a thermal camera. Our choice is a phone that everyone already has. Temperature belongs at the SSB, shared between patients, and it is on our roadmap.

**"Where does your data come from?"**
Right now, our own test photos. We have not used any patient data without authorisation, and we have not generated fake data, which the rules forbid. The next step is a small real set collected with a diabetology department, with consent and ethics approval.

**"Is this only for diabetics?"**
Yes. Diabetic foot is a complication of diabetes. Within that, the priority is people already at risk: neuropathy, poor circulation, foot deformity, or a previous ulcer.

**"Who is responsible if something is missed?"**
The health professional who validates the case, exactly as in any triage tool. The app is documented as a detection and triage aid, never as a diagnosis, and it never tells a patient their foot is healthy.

**"Can it work offline?"**
Yes. The clinical rules run with no network, and the report says clearly that it ran without the AI layer.

---

# PART 3 · What to do tomorrow

In priority order. Do 1 to 4 even if you do nothing else.

### 1. Find your clinical validator (most important)
The rules require a health professional to validate the need, the pathway and the thresholds. Get a diabetologist, a general practitioner or a nurse to look at the app for 20 minutes. Write down their name, their role, and two or three sentences of what they said. Put that on a slide. Without this, you lose points on the first criterion.

### 2. Get a few real photos, properly
Ask your clinical contact for permission to photograph feet in consultation, with patient consent. Even five real photos with a written consent note beats a hundred from the internet. Write a one page provenance sheet: where the photos come from, who consented, what the limits are. The rules ask for exactly this document.

### 3. Rehearse the demo three times, out loud
Not in your head. Time it. The order is in `RUN_AND_DEMO.md`. Whoever speaks should not be the one clicking.

### 4. Prepare the backup
Record a screen video of the full demo and take screenshots of each screen. If the wifi dies, or the key rate-limits, you show the video and keep talking. A team that keeps its calm when the demo breaks looks better than one that panics.

### 5. Check the technical submission
Repository pushed, README readable, no API key anywhere (`git grep -n "AIza"`), everyone can run it after `flutter pub get`.

### 6. Prepare one number
Something concrete you can say: how long a check takes (time yourself doing it), or how many seconds from photo to result. Small measured facts sound better than adjectives.

---

# PART 4 · How to raise the level for pitch day

Ordered by value for effort. Pick the top two, not all of them.

### Cheap and high value

**A clinical validation slide.** Photo of the professional, their name and role, and their quote. Five minutes of work, first jury criterion covered.

**A data provenance sheet.** One page: source, consent, quality, limits. The rules explicitly ask for it. Most teams will forget.

**Name the care pathway.** Do not say "the app alerts". Say "the SSB nurse sees the case in the queue, validates or corrects it, and refers to the regional hospital if it is red". Show that you know how the Tunisian system actually works.

**Show the FHIR export live.** Open it on screen for five seconds. Almost no team will have this running.

### Medium effort, strong effect

**One real case, end to end.** A real photo, a real check, a real professional decision, the FHIR export. One complete story beats five features.

**A simple measurement.** Take 10 photos, have your clinical contact classify them green, orange, red, then run the app on them and compare. Even "the app agreed with the clinician on 7 out of 10, and the 3 disagreements were the app being more cautious" is a real result. That is a measurement, and it will make you the only team with one.

**Design consistency.** The main screens are polished, but some follow-up screens still use the old style. Either avoid them in the demo, or finish them.

### If you have extra time

**The roadmap slide, credible and short.** Phase 1, a real dataset and a measured agreement study. Phase 2, a server with INPDP authorisation and the national health identifier. Phase 3, a pilot in one or two SSBs with a set number of patients. Give phases, not dreams.

**The cost question.** Prepare an answer for "what does this cost to run per patient". Even a rough number shows you thought about deployment.

---

# PART 5 · Things to avoid

- Do not say "our AI detects ulcers with 95% accuracy". You have not measured it.
- Do not say the app diagnoses. Ever. It spots and sorts. The doctor decides.
- Do not hide the limits and wait for the jury to find them. Say them yourself, in your own words. It reads as maturity.
- Do not demo a screen you have not opened in the last hour.
- Do not put the API key in the repository or on a slide.
- Do not use generated or fake patient data. The competition rules forbid it outright, and it is disqualifying.

---

# PART 6 · Reminders

**The API key.** Each person uses their own. Get it free at <https://aistudio.google.com/apikey>. In the app: home screen, gear icon at the top right, paste it, Save, then Test connection. It stays on that device only. Without a key the app still works, using the clinical rules, and the report says so.

**The demo order.** Landing and language, create a patient account, do a check with photos, questions, result, consent and send, sign out, doctor account, open the case, decide, FHIR export. Full script in `RUN_AND_DEMO.md`.

**Who speaks.** One person tells the story, one drives the app, one answers technical questions. Decide this tonight, not on stage.

Good luck. You have something that actually works end to end, which is more than most teams will have. Now make sure the jury understands it in the first thirty seconds.
