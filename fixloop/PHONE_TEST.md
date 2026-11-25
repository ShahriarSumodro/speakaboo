# Speakaboo Real-Phone 10-Minute Regression Checklist

Test configuration: Real Android phone (`SM A366B`) connected via USB.

---

## 1. Setup & Connection

1. Run adb port forwarding:
   ```powershell
   adb reverse tcp:8000 tcp:8000
   ```
2. Start the Speakaboo backend from repo root:
   ```powershell
   python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
   ```
3. Open Speakaboo on the phone. In Settings > **Server Connection (Dev)**, ensure URL is:
   `http://localhost:8000`
4. Tap **Test Connection** -> Verify popup indicates `Connected` and server status `ok`. Tap **Save & Apply**.

---

## 2. Test Cases (10 Minutes)

### Test 1: Server Connection Banner Auto-Refresh (Fix B3)
- [ ] Stop backend (`Ctrl+C`). Observe red "Server not ready" banner appears.
- [ ] Restart backend. Tap the refresh icon on the banner, or wait up to 15 seconds, or switch apps and return.
- [ ] **Pass condition**: The red banner disappears immediately when health is restored. No sticky red banner.

### Test 2: Character Detail & Theme Contrast (Fix B6)
- [ ] Open **Companions** tab -> Tap **Farmer Reggie**.
- [ ] Switch phone theme to **Dark Theme** (or select Dark in Settings).
- [ ] Inspect the AppBar title: must be crisp and readable with high contrast against the dark AppBar.
- [ ] Inspect character name and "Personality & Teaching Style": must be light text on dark background (>= 4.5:1 contrast).
- [ ] Inspect the "Best For", "Speaking Style", and "Vocabulary Focus" card:
  - "Best For: Young learners, beginners, and anyone needing high encouragement."
  - "Speaking Style: Direct, earnest, slightly dramatic..."
  - "Vocabulary Focus: Everyday actions, nature, routines, and simple grammatical sentence building" (MUST NOT be empty).
- [ ] Switch to **Light Theme**:
  - Verify all texts remain clearly readable with dark brown/black typography on warm sand card.
- [ ] **Pass condition**: All texts meet WCAG AA (>= 4.5:1 contrast) in both themes; Vocabulary Focus row is populated with real pedagogical focus.

### Test 3: Voice Preview & Error Handling (Fix B2)
- [ ] On character detail screen, tap **Hear their voice**.
- [ ] If Groq Orpheus model terms have been accepted: audio plays smoothly.
- [ ] If model terms have not yet been accepted:
  - Backend logs HTTP 400 with model terms note.
  - App shows friendly toast: "Voice preview temporarily unavailable. Please try again." with **Retry** button.
  - App MUST NEVER play fake 100ms silent audio or crash.
- [ ] **Pass condition**: Real voice audio or friendly retry UI. Zero fake/silent mock audio in production.

### Test 4: Multi-Turn Voice Conversation (Fix B1)
- [ ] Select **Farmer Reggie** and tap **Start Talking** (or navigate to **Talk** tab).
- [ ] Tap the microphone button and say:
  - Turn 1: *"Hello Reggie! How is the harvest today?"*
  - Observe: Character transcribes early, reply streaming completes, text displays in message bubble.
- [ ] Wait for character to finish speaking.
- [ ] Tap the microphone button again and say:
  - Turn 2: *"I am learning English today. What should we plant?"*
  - Observe: Character transcribes, remembers Turn 1 context, and replies.
- [ ] Repeat for Turn 3:
  - *"Can you give me a sentence with the word pumpkin?"*
  - Observe: Character replies with turn 3.
- [ ] **Pass condition**: Companion continues answering seamlessly on turn 2, 3, and onwards. Does NOT stall, stop speaking, or freeze after Turn 1.

### Test 5: Authentication & Spaced Repetition (Fix B4)
- [ ] Open **Vocabulary** tab:
  - Cards load cleanly without 401 Unauthorized errors in uvicorn log.
  - Search saved words and filter by Leitner boxes.
- [ ] Open **Parent Dashboard**:
  - Set a 4-digit PIN (e.g. `1234`). Verify success message.
  - Unlock dashboard with the PIN.
  - Verify uvicorn terminal shows zero `401 Unauthorized` responses.
- [ ] **Pass condition**: Auto-authentication attaches signed Bearer token to all requests; automatic re-registration refreshes expired tokens.

### Test 6: Shadowing Mode (Fix B5)
- [ ] Open **Daily Missions** -> Tap a Shadowing mission (or open Shadowing from Learning screen).
- [ ] Verify script list loads scripts (e.g. "Morning Market", "Study Habits") without 404.
- [ ] Select a script, tap record, speak the target phrase, and tap evaluate.
- [ ] **Pass condition**: Evaluation returns accuracy score, pace score, and awards XP. No 404 endpoint errors.
