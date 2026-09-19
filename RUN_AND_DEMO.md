# Khatwa · run, demo, and API key setup

Défi 3.1 · Future Health Connectathon 2026 · repérage précoce des signes d alerte du pied diabétique.

---

## 1. First run (2 minutes)

```bash
flutter pub get          # two new packages were added: http, crypto
flutter run -d chrome    # laptop demo
flutter run              # phone, with a device plugged in or an emulator
```

If `flutter run -d chrome` complains about the camera, use the gallery option in the capture sheet. On the phone, the camera works.

---

## 2. The Gemini API key (read this before pushing to GitHub)

**The key is never in the code and never in the repo.** The app looks for it in two places, in this order:

1. A build-time value passed with `--dart-define`
2. A key the user pastes in the app, under Settings, stored only on that device

So each teammate uses their own key, and nothing secret is committed.

### Get a key (free, 1 minute)

Go to <https://aistudio.google.com/apikey>, sign in with a Google account, create an API key, copy it.

### Option A, fastest for a teammate

Run the app, open **Settings** from the home screen, paste the key, press Save, then press **Test connection**. The key stays on that device. Nothing else to do.

### Option B, build-time, best for the demo machine

```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=AIza...votre_cle
flutter run --dart-define=GEMINI_API_KEY=AIza...votre_cle
flutter build apk --release --dart-define=GEMINI_API_KEY=AIza...votre_cle
```

To avoid retyping it, create `dart_defines.json` at the project root (already covered by the rule below):

```json
{ "GEMINI_API_KEY": "AIza...votre_cle" }
```

```bash
flutter run --dart-define-from-file=dart_defines.json
```

### Before the first push

Add these lines at the end of `.gitignore`:

```
dart_defines.json
*.env
```

Then confirm nothing leaked:

```bash
git grep -n "AIza" || echo "no key in the repo"
```

### What happens with no key

Nothing breaks. The app runs the deterministic clinical rule engine, and the report says so (`Règles cliniques seules (hors ligne)`). That is the honest fallback, and it is worth saying out loud in the pitch: the safety layer does not depend on the network.

---

## 3. Demo script for the jury (3 minutes)

1. **Landing** · choose the language. The app opens in Tunisian derja; Arabic, French and English are one tap away, and the layout flips direction.
2. **Patient account** · Create account, phone + password. It is a real account: salted SHA-256 hash, 4000 iterations, session restored on relaunch.
3. **Start the check** · four guided capture slots (right sole, left sole, right top, left top). Take at least one photo.
4. **Questionnaire** · eight yes/no red-flag questions plus an optional glucose value.
5. **Analyse** · the photos and the answers go to Gemini in one multimodal call. The reply comes back as structured JSON, gets merged with the rule engine, and becomes the report: level, observations, advice, confidence, photo quality.
6. **Point at the safety line** · the rule engine can only raise the level, never lower it. If the patient declares an open wound, the case is red whatever the image model says.
7. **Send to a professional** · the case leaves the patient app.
8. **Sign out, sign in as a professional** · create a doctor account, and the case is in the queue, sorted with red first.
9. **Open the case** · photos, AI proposal, patient answers. Confirm or override the level, choose the orientation (home follow-up, SSB, regional hospital), leave a note, save. The patient report now shows the validated decision.
10. **FHIR export** · the code icon in the case header shows the HL7 FHIR R4 transaction Bundle: Patient with an INS placeholder identifier, QuestionnaireResponse, one Observation per finding, one Media per photo, RiskAssessment carrying the AI output and its basis, ServiceRequest for the validated referral, Provenance with both the app and the clinician as agents.

---

## 4. What was built, and what is honest to say

**Real:**

- Real accounts with hashed passwords, sessions, two roles.
- Real multimodal AI call to Gemini, with structured output parsing, model fallback, timeout and error handling.
- Deterministic clinical rule engine that runs always and can only raise the triage level.
- Real end-to-end path: capture, questionnaire, triage, report, submission, clinician review, validated decision that comes back to the patient.
- Real FHIR R4 Bundle generated from the actual case data.
- Four languages with correct RTL.

**Not yet, and say so before the jury asks:**

- The AI layer is a general vision model prompted for this task. It is not a model trained on diabetic foot images, and it has not been evaluated on a labelled dataset. The next step is a real dataset with a clinical partner, and a measured agreement study against clinician assessment.
- Storage is local to the device. The production path is a server with INPDP authorization, the national health identifier (INS), and DICOMweb for the photos.
- SNOMED CT codes in the export are indicative. SNOMED licensing for Tunisia has to be confirmed, otherwise a local code system with the same shape is used.

That honesty is worth points. The challenge rules ask for proof, limits and provenance, not for claims.
