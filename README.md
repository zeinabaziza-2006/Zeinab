# Khatwa · خطوة

A phone app that helps a person with diabetes check their feet every day, and lets a doctor review what the app found.

Built for the **Future Health Connectathon 2026**, Défi 3.1: *Repérer plus tôt les signes d'alerte du pied diabétique*.

---

## Why this matters

When you have diabetes, two things go wrong in the foot. You stop feeling pain, so you do not notice an injury. And blood flows badly, so injuries do not heal. A small crack or a callus can turn into an ulcer, then an infection, then an amputation.

The moment to catch it is early, when there is only redness, dry skin, a callus or a crack. Nobody catches it because nobody looks at the bottom of their own feet every day, and many patients cannot even see them.

In one Tunisian study (Mahdia, 220 diabetic patients), around 27% were already at risk of a foot ulcer.

---

## What the app does

### For the patient

1. **Set your risk level** once: 4 questions give your IWGDF category (0 to 3) and how often your feet should be examined
2. **Take photos**, guided by a foot outline on the camera that turns green when the shot is taken, one position at a time
3. **Answer 8 quick yes/no questions** (pain, wound, swelling, fever...)
4. **Get a result** in your language: green, orange or red, with what to do
5. **See the change** since your last check, the same foot side by side
6. **Send it to a health professional**, after ticking consent

### For the doctor

1. See a list of cases, most serious first, with how many are waiting and the median review delay
2. Open a case: photos, what the AI found, what the patient answered, their risk category
3. Confirm or change the level, choose where the patient should go (home follow-up, SSB, regional hospital), add a note
4. Export the case as a FHIR file for the hospital system

Identity stays hidden unless the patient agreed to share it, and revealing it is recorded in the access trail.

### The rule that never breaks

**The app never gives a diagnosis.** It helps spot things and sort cases. A health professional decides. The app also never tells a patient their foot is fine, only that nothing was detected in these photos.

---

## The details that make it usable

- **Guided camera**: the screen dims everything except a foot-shaped outline, the outline breathes while you frame and locks green when the photo lands, and a ring around the shutter fills one segment per position. Four positions: both soles, both insteps.
- **Sensation test**: tap the 10 classic test points on two foot maps, once for felt, twice for not felt. Losing sensation is the biggest ulcer risk factor and it is invisible, so we made it visual.
- **Glucose log**: a line chart with your target range drawn behind it, out-of-range points marked by colour and a ring.
- **Text size**: three sizes in Settings, for people with retinopathy.
- **4 languages**: Tunisian derja by default, plus Arabic, French and English, with the layout flipping for Arabic.
- **Works offline**: without network or key, the clinical rules still run and the report says so.

## How to run it

```bash
flutter pub get
flutter run -d chrome     # on a computer
flutter run               # on an Android phone
```

That is it. It works on both.

---

## The Gemini API key (each person needs their own)

The key is **not** in this repository, and it should never be. Everyone uses their own.

### Getting your key (1 minute, free)

1. Go to <https://aistudio.google.com/apikey>
2. Sign in with any Google account
3. Click "Create API key" and copy it

### Putting it in the app (easiest way)

1. Run the app and create an account
2. On the home screen, tap the **gear icon** at the top right
3. Paste your key in the "Gemini API key" field
4. Tap **Save**, then **Test connection**

If it says "Connection works", you are done. The key stays on your own device and is never sent to the repository or to anyone else.

### Or pass it when you run (for the demo machine)

```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=your_key_here
```

### If you have no key

The app still works. It uses the clinical rules instead of the AI, and the report says so honestly. Nothing crashes.

---

## What is inside

Two layers decide the result, and this is the most important part to understand.

**1. The clinical rules** (`lib/data/rule_engine.dart`)
Fixed medical rules written in code. Open wound, signs of infection, a wound on a foot the person cannot feel, dangerous glucose. These always run, even with no internet.

**2. The AI** (`lib/data/ai_gateway.dart`)
The photos and the answers go to Gemini in one call. It looks at the images and returns what it sees, a level, advice and a confidence score.

**How they combine:** the rules can make the alert *more* serious, never less. If the patient says there is an open wound, the case is red even if the AI saw nothing. The safety never depends on the AI.

### Sending the case to a hospital system (FHIR)

Every case can be exported as an HL7 FHIR R4 bundle, the standard hospitals use:

| Piece | What it holds |
|---|---|
| Patient | who the patient is |
| QuestionnaireResponse | the 8 answers |
| Observation | one per thing found |
| Media | one per photo |
| RiskAssessment | the AI result and how confident it was |
| ServiceRequest | the referral, only after a doctor validated it |
| Provenance | who did what: the app, then the doctor |

### Security

- Passwords are hashed, never stored as text
- A PIN is required on top of the password
- Everything stored on the device is encrypted, and the key is locked by the PIN
- 5 wrong attempts locks the account for a minute
- Automatic sign out after 10 minutes without activity
- The patient must tick consent before anything is sent
- Without consent to be named, the doctor sees initials and a case number
- Every access to a case is recorded (who, what, when)

---

## Project structure

```
lib/
  data/
    auth_store.dart    accounts, PIN, lockout
    crypto_box.dart    encryption
    case_store.dart    cases, consent, access trail
    rule_engine.dart   the clinical rules
    ai_gateway.dart    the Gemini calls
    triage.dart        the shared result model
    fhir_export.dart   the FHIR bundle
    khatwa_store.dart  daily follow-up data
    risk_profile.dart  IWGDF risk categories
  screens/
    auth_pages.dart      language, role, login and signup
    patient_home.dart    patient home screen
    foot_check.dart      photos, questions, analysis
    capture_guide.dart   the guided camera
    sensory_check.dart   the 10 point sensation test
    risk_profile_page.dart  the 4 risk questions
    report_view.dart     result, comparison, consent, sending
    doctor_home.dart     case list, review, decision, FHIR
    settings_page.dart   API key, text size
  ui/
    app_theme.dart     colors, text styles, shared widgets
    foot_shapes.dart   the foot outline drawn in code
    strings.dart       the 4 languages
```

Languages: Tunisian derja (default), Arabic, French, English. Arabic screens flip right to left automatically.

---

## What is real and what is not

**Real:** the accounts, the encryption, the AI call, the clinical rules, the full path from photo to doctor decision, the FHIR export, the 4 languages.

**Not yet, and we say it openly:**

- The AI is a general vision model with a good prompt. It is **not** a model trained on diabetic foot images, and we have not measured its accuracy on a labelled dataset.
- Data is stored on the device only. A real deployment needs a server, INPDP authorisation and the national health identifier.
- The medical codes in the FHIR export are indicative until SNOMED licensing for Tunisia is confirmed.

Being honest about this is not a weakness in this competition. The rules ask for proof and limits, not for big claims.

---

Read `EXPLANATION&TIPS.md` for how to present the project and what to do next.
