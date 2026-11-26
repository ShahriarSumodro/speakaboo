# Speakaboo Before-Redesign Audit (`design/before/`)

Captured on `RFGYC3TSCLT` (1080×2340) across 10 screenshots in `design/before/`:
- `01_talk.png` — Talk screen (offline state)
- `02_characters_live.png` — Characters list
- `02b_character_detail.png` — Character Detail (Detective Kabir)
- `03_missions_live.png` — Daily Missions
- `04_profile_live.png` — Learner Profile
- `05_settings.png` — Settings
- `06_scenarios.png` — Speaking Scenarios
- `07_topics.png` — Conversation Topics
- `08_shadowing.png` — Shadowing Practice
- `09_vocabulary.png` — Vocabulary Notebook

## Global Diagnosis: Why the App Feels Flat, Lifeless & Low Grade
1. **Muddy Espresso & Monochrome Orange:** Dark mode uses `#1B1613` / `#2A221D` brown-black with `#FF7A33` orange for almost every icon, badge, and button—zero color variety or semantic separation.
2. **Generic System Typography & Zero Hierarchy:** Default Roboto/sans-serif everywhere; no playful display font (`Fredoka`) or warm body font (`Nunito`), no marker highlights, no personality.
3. **Flat Surfaces & No Tactile Depth:** Cards are flat `1px`-bordered or low-contrast boxes with zero 3D pressable button edges, zero pastel washes, and zero bounce/spring feedback.
4. **Blank-Void Empty & Error States:** `Missions`, `Scenarios`, `Topics`, and `Vocabulary` show plain centered gray text on an empty dark screen—no character presence, no illustration, no next-step CTA.
5. **No Home Screen Hub:** The app opens straight into `TalkScreen` with a floating face and 3 stacked red error banners when offline, rather than a warm, welcoming Home hub (`Start Speaking` + `Today's Mission` + own progress + 4 practice modes).

## Per-Screen Audit
- **Talk (`01_talk.png`):** When backend is unreachable, 3 separate error UIs stack simultaneously (top red Material banner + dark red card + white bottom Snackbar). Character face is static without breathing/blinking/idle charm.
- **Characters (`02_characters_live.png`):** Every character—including active *Farmer Reggie*—displays a generic padlock icon instead of their illustrated character face. No personality or color identity per character.
- **Character Detail (`02b_character_detail.png`):** Outlined `Hear their voice` pill and flat dark chips look clinical; no character color theme or playful stage.
- **Missions (`03_missions_live.png`):** Plain `"Could not load missions. Check connection."` text in a dark void with no retry action or character encouragement.
- **Profile (`04_profile_live.png`):** Monotonous vertical stack of identical dark cards; `0 XP / 0 Days / BEGINNER` looks like a cold admin dashboard; `Practice Modes` are 3 identical dark squares.
- **Settings (`05_settings.png`):** Plain `ListTile`-style dark cards; theme selector is a bare text dropdown (`System ▾`) instead of a tactile 3-way segmented pill (`Light | Dark | System`).
- **Scenarios & Topics (`06_scenarios.png`, `07_topics.png`):** Bare `"No scenarios found."` / `"No topics available."` text with no character, no empty-state card, no action.
- **Shadowing & Vocabulary (`08_shadowing.png`, `09_vocabulary.png`):** Unstyled Material `ChoiceChip` uses default teal `#00BFA5` that clashes with the brown/orange palette; Vocabulary empty state has no character or CTA.
