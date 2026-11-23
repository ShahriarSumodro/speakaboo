# Speakaboo Design Rules

## Color System (60-30-10)

| Role | Color | Usage |
|------|-------|-------|
| 60% Background | `#FBF8F5` (warm off-white) | Main background |
| 30% Surfaces | `#F1E9E1` (warm cream) | Cards, sheets, containers |
| 10% Accent | `#F26B21` (orange) | Main action per screen, max 3 accent elements |
| Text | `#2A211B` (warm dark brown) | All text |

- Neutrals carry approximately 4% of the accent's warm hue.
- No extra random colors allowed.
- **Blur test:** A blurred screenshot must show three flat color zones, not confetti.

## Layout Rules

### Navigation
- Bottom navigation bar: **Talk** | **Characters** | **Missions** | **Profile** (max 5 items)
- All tap targets minimum **44px**

### Typography
- Base font size: **17px**
- Scalable text for accessibility

### Screen Structure
- One core module per screen
- Sections flow in one direction (vertical stack OR one horizontal scroller, not both)
- Building blocks: cards, text, images, inputs
- **NEVER** nest a card inside a card
- One task per screen; secondary choices open as **bottom sheets**

### Gestures
- Swipe right = back
- Swipe down = dismiss sheet
- Long-press = contextual preview (where useful)
- Hide persistent toolbars when contextual actions take over

### Empty States
- First-time users: clean full-screen empty state with one popover pointing to the main button
- "No results": friendly imagery, a suggestion, and an exit action

## Tone

- Friendly, never childish for university users
- Never scary for kids
- Corrections are gentle and short
- Encourage speaking confidence above all

## Character Visual Style

- Simple, expressive cartoon faces
- Mouth animation synced to audio playback
- Idle blink animation
- Each character has a distinct visual identity

## Accessibility

- Minimum 44px touch targets
- WCAG AA contrast ratio compliance
- Scalable text support
- Screen reader compatible labels
