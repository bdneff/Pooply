# Pooply UI Redesign Specification
## Apple Editors' Choice Quality | Feminine, Minimal, Colorful

---

## Design Philosophy

**Core Principles:**
- Clean white/off-white backgrounds with colorful accent cards
- Soft shadows for depth, no harsh borders
- Nunito font family throughout (already in project)
- Feminine without being "girly" - sophisticated wellness aesthetic
- Colorful palette that pops against minimal backgrounds
- Professional yet approachable - like Calm meets Apple Health

**Inspiration Sources:**
- Bevel (minimal white bg, floating cards, AI insights)
- Journal App (horizontal date strip, colorful cards on white)
- Function Health (sophisticated gauges, premium feel)
- Your mockups (mascot, poop score hero metric, semi-circular gauges)

---

## Design System

### Color Palette

```
BACKGROUNDS
├── Primary:      #FFFFFF (white)
├── Secondary:    #F8FAF9 (off-white, subtle warmth)
└── Card Base:    #FFFFFF (white cards with shadows)

BRAND COLORS
├── Primary:      #19B888 (Pooply Teal) - CTAs, positive states
├── Secondary:    #2E7D32 (Forest Green) - text, headers
└── Accent:       #1B5E20 (Dark Forest) - emphasis text

CATEGORY COLORS
├── Regular/Good: #19B888 (teal)
├── Hard:         #FF7A33 (warm amber)
├── Loose:        #008CFF (sky blue)
└── Blood Alert:  #E53935 (red)

SUPPORTING COLORS
├── Hydration:    #4FC3F7 (light blue)
├── Fiber:        #FFB74D (warm yellow/wheat)
├── Warning:      #FFA726 (orange)
└── Neutral:      #78909C (gray for secondary text)

CARD ACCENT BACKGROUNDS (subtle tints)
├── Teal Tint:    #E8F5F1 (10% teal)
├── Blue Tint:    #E3F2FD (10% blue)
├── Amber Tint:   #FFF3E0 (10% amber)
└── Pink Tint:    #FCE4EC (for variety)
```

### Typography (Nunito)

```
HIERARCHY
├── Hero Number:     Nunito Black, 48-56pt (Poop Score %)
├── Page Title:      Nunito Bold, 28-32pt
├── Section Header:  Nunito Bold, 20pt
├── Card Title:      Nunito Bold, 18pt
├── Body:            Nunito Regular, 16pt
├── Caption:         Nunito Regular, 14pt
├── Label:           Nunito Bold, 12pt (uppercase for small labels)
└── Micro:           Nunito Regular, 11pt

COLORS
├── Primary Text:    #1B5E20 (dark forest)
├── Secondary Text:  #2E7D32 (forest green)
├── Tertiary Text:   #78909C (gray)
└── On-Color Text:   #FFFFFF or #1F1F1F (based on bg)
```

### Shadows & Depth

```
CARD SHADOW (primary)
├── Layer 1:  color: black 8%, blur: 16, y: 8
└── Layer 2:  color: black 4%, blur: 4, y: 2

FLOATING ELEMENTS (tab bar, FAB)
├── Layer 1:  color: black 12%, blur: 24, y: 12
└── Layer 2:  color: black 6%, blur: 8, y: 4

SUBTLE SHADOW (inner cards)
└── Single:   color: black 4%, blur: 8, y: 4
```

### Spacing System

```
├── xs:   4pt
├── sm:   8pt
├── md:   16pt
├── lg:   24pt
├── xl:   32pt
└── xxl:  48pt

CARD PADDING:     20pt
SCREEN PADDING:   20pt horizontal
CARD RADIUS:      20pt (large cards), 16pt (medium), 12pt (small)
```

### Components

```
BUTTONS
├── Primary CTA:  Teal bg (#19B888), white text, capsule, h: 52pt
├── Secondary:    White bg, teal border, teal text, capsule
├── Icon Button:  48x48pt, rounded, subtle bg on tap
└── FAB:          56x56pt, teal bg, white + icon, circle

CARDS
├── Standard:     White bg, 20pt padding, 20pt radius, card shadow
├── Accent:       Tinted bg (e.g., #E8F5F1), no shadow, 16pt radius
└── Stat Card:    White bg, centered content, 16pt radius

GAUGES
├── Hero Gauge:   Arc shape, 180pt diameter, 14pt stroke
├── Mini Gauge:   Circle, 64pt diameter, 4pt stroke
└── Progress Bar: 8pt height, rounded caps
```

---

## Page Specifications

---

### 1. HOME PAGE

**Layout Structure:**
```
┌─────────────────────────────────────┐
│  "Hi, {Name}"              [Avatar] │  ← Greeting + Profile button
│  How's your gut today?              │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │     POOP SCORE              │    │  ← Hero Card (white, shadow)
│  │        82%                  │    │
│  │    ◠◠◠◠◠◠◠◠◠◠◠◠◠◠          │    │  ← Arc gauge
│  │   "7 of last 10 were good"  │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  [TODAY] [WEEK] [MONTH]             │  ← Segmented control
├─────────────────────────────────────┤
│  ┌─────┐  ┌─────┐  ┌─────┐         │
│  │ 72% │  │  0% │  │ 65% │         │  ← 3 Mini Stat Cards
│  │Hydra│  │Blood│  │Fiber│         │
│  └─────┘  └─────┘  └─────┘         │
├─────────────────────────────────────┤
│  Streaks          🔥 12  🏆 28     │  ← Streaks section
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │  JANUARY 2026      < >      │    │  ← Calendar Card
│  │  S  M  T  W  T  F  S        │    │
│  │  ●  ●  ○  ●  ●  ○  ●  ...   │    │  ← Dots show log days
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  Recent Logs                        │
│  ┌─────────────────────────────┐    │
│  │ 🍦 Sunday 8:15 AM    Good ● │    │  ← Log cards
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 🍦 Saturday 2:45 PM Loose ● │    │
│  └─────────────────────────────┘    │
│                                     │
│  [View All Logs]                    │
└─────────────────────────────────────┘
```

**Key Changes from Current:**
1. White background instead of mint everywhere
2. Personal greeting with user's name: "Hi, {Name}"
3. Poop Score as HERO metric (not Gut Health) - calculated from multiple inputs
4. Mini stat cards in a row (Hydration, Blood, Fiber) - cleaner than current gauges
5. Streaks inline, not inside calendar
6. Calendar is more compact with dot indicators
7. Log cards redesigned with more info

**Poop Score Calculation (NEW):**
```swift
func calculatePoopScore(for log: Log) -> Int {
    var score = 0

    // Bristol Type (40% weight)
    switch log.type {
    case .smoothSausage, .crackedSausage: score += 40  // Types 3-4 ideal
    case .softBlobs: score += 28                        // Type 5 okay
    case .lumpySausage: score += 20                     // Type 2 mild
    case .fluffyPieces: score += 15                     // Type 6
    case .separateHardLumps: score += 10               // Type 1
    case .watery: score += 5                            // Type 7 worst
    }

    // Color (25% weight)
    switch log.color {
    case .mediumBrown, .darkBrown: score += 25  // Ideal
    case .lightBrown: score += 20
    case .green, .yellow: score += 10           // Concerning
    case .black, .red: score += 0               // Alert
    }

    // Blood (20% weight) - Critical factor
    if log.bloodPercentage == 0 {
        score += 20
    } else if log.bloodPercentage < 0.05 {
        score += 5
    }
    // Blood present = 0 points

    // Size (15% weight)
    switch log.size {
    case .medium: score += 15  // Ideal
    case .large: score += 12
    case .small: score += 8
    }

    return score  // Max 100
}
```

---

### 2. INSIGHTS PAGE

**Layout Structure:**
```
┌─────────────────────────────────────┐
│  Insights                   [?]     │  ← Page title + info
│  Your gut health at a glance        │
├─────────────────────────────────────┤
│  [TODAY] [WEEK] [MONTH]             │  ← Segmented control
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │  Weekly Quality    Last 7d  │    │  ← Chart Card
│  │                             │    │
│  │   ▐▌  ▐▌                    │    │
│  │   ▐▌  ▐▌▐▌    ▐▌           │    │  ← Stacked bar chart
│  │   ▐▌  ▐▌▐▌▐▌  ▐▌▐▌         │    │
│  │   Mon Tue Wed Thu Fri Sat   │    │
│  │                             │    │
│  │   ● Good  ● Hard  ● Loose   │    │  ← Legend
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  AI Insights                        │  ← Section header
│  ┌─────────────────────────────┐    │
│  │ 💡 60% of your poops were   │    │  ← Insight cards
│  │    GOOD this week. Higher   │    │
│  │    hydration may have helped│    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 💧 Loose stools mostly      │    │
│  │    happened at night,       │    │
│  │    especially Fri & Sat.    │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 🩸 Blood logged 2 times in  │    │
│  │    last 14 days. Most       │    │
│  │    recently: 4 days ago.    │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  Patterns                           │
│  ┌───────┐ ┌───────┐ ┌───────┐     │
│  │Morning│ │ Avg   │ │Weekly │     │  ← Pattern mini cards
│  │ 68%   │ │ Score │ │ Trend │     │
│  │regular│ │  74   │ │  ↑12% │     │
│  └───────┘ └───────┘ └───────┘     │
└─────────────────────────────────────┘
```

**Key Changes from Current:**
1. Add AI-style insight cards (natural language)
2. Pattern recognition mini cards
3. Better chart styling with rounded bars
4. White background with colored chart

**New Insight Generation Functions:**
```swift
func generateInsights(for timeframe: String) -> [Insight] {
    // Analyze patterns and return natural language insights
    // - Good poop percentage
    // - Time-of-day patterns
    // - Blood alerts
    // - Streak changes
    // - Hydration correlations
}
```

---

### 3. MANUAL ENTRY PAGE (Sheet)

**Layout Structure:**
```
┌─────────────────────────────────────┐
│  ✕                    Log     Save  │  ← Header
├─────────────────────────────────────┤
│                                     │
│  When                               │
│  ┌─────────┐  ┌─────────────────┐   │
│  │  Now ✓  │  │  Choose Time    │   │  ← Segmented toggle
│  └─────────┘  └─────────────────┘   │
│                                     │
│  [Date Picker if "Choose Time"]     │
├─────────────────────────────────────┤
│  Type (Bristol Scale)               │
│  ┌─────┐ ┌─────┐ ┌─────┐           │
│  │ 🟤1 │ │ 🟤2 │ │ 🟤3 │           │
│  │Hard │ │Lumpy│ │Crack│           │  ← 2 rows of 3-4
│  └─────┘ └─────┘ └─────┘           │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │
│  │ 🟤4 │ │ 🟤5 │ │ 🟤6 │ │ 🟤7 │   │
│  │Smoth│ │Soft │ │Fluff│ │Water│   │
│  └─────┘ └─────┘ └─────┘ └─────┘   │
├─────────────────────────────────────┤
│  Color                              │
│  ⬤ ⬤ ⬤ ⬤ ⬤ ⬤ ⬤                    │  ← Color circles
│  Lt Med Dk Grn Yel Blk Red          │
├─────────────────────────────────────┤
│  Size                               │
│  ┌────────┐ ┌────────┐ ┌────────┐   │
│  │ Small  │ │Medium ✓│ │ Large  │   │  ← Capsule buttons
│  └────────┘ └────────┘ └────────┘   │
├─────────────────────────────────────┤
│  Blood Present                      │
│  ┌─────────────────────────────┐    │
│  │ Blood in stool?      [OFF]  │    │  ← Toggle row
│  └─────────────────────────────┘    │
│                                     │
│  ⚠️ Blood can indicate...          │  ← Warning text (if on)
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐    │
│  │         Save Log            │    │  ← Primary CTA
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

**Key Changes from Current:**
1. White background
2. Better organized type grid (2 rows)
3. Add labels under type images
4. Show warning message when blood toggle is on
5. Larger, clearer Save button at bottom
6. Remove duplicate "Contains Blood" text

---

### 4. PROFILE PAGE (Sheet)

**Layout Structure:**
```
┌─────────────────────────────────────┐
│  ✕               Profile            │  ← Header
├─────────────────────────────────────┤
│                                     │
│           ┌───────────┐             │
│           │   Avatar  │             │  ← User avatar (initials)
│           │    BG     │             │
│           └───────────┘             │
│            Brandon                  │
│            52 total logs            │
│                                     │
├─────────────────────────────────────┤
│  Stats                              │
│  ┌─────────┐ ┌─────────┐           │
│  │   74    │ │   28    │           │
│  │Avg Score│ │ Longest │           │  ← Mini stat cards
│  │         │ │ Streak  │           │
│  └─────────┘ └─────────┘           │
├─────────────────────────────────────┤
│  Account                            │
│  ┌─────────────────────────────┐    │
│  │ 📝 Edit Profile          >  │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 🔔 Notifications         >  │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 💳 Subscription          >  │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  About                              │
│  ┌─────────────────────────────┐    │
│  │ 📄 Terms of Service      >  │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 🔒 Privacy Policy        >  │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │ 🚪 Log Out                  │    │  ← Destructive action
│  └─────────────────────────────┘    │
│                                     │
│            v1.0.0                   │  ← Version
└─────────────────────────────────────┘
```

**Key Changes from Current:**
1. Add user stats (avg score, longest streak)
2. Better organized sections
3. Add notifications option
4. Add Edit Profile option
5. Show app version

---

### 5. TAB BAR / NAVIGATION

**Option A: Floating Capsule + FAB (RECOMMENDED)**
```
┌─────────────────────────────────────┐
│                                     │
│           [Content]                 │
│                                     │
│                                     │
│    ┌───────────────────────┐        │
│    │  🏠 Home    📊 Insights│        │  ← Floating gray capsule
│    └───────────────────────┘        │
│                              [＋]   │  ← Green FAB, bottom right
└─────────────────────────────────────┘
```

**Specs:**
- Capsule: `#F5F5F5` background, centered, 8pt padding
- Icons: 24x24pt, selected = teal, unselected = gray
- FAB: 56x56pt, `#19B888` bg, white "+" icon
- FAB position: 20pt from right, 20pt from bottom
- FAB shadow: strong floating shadow
- Tap FAB → Show action sheet (Camera / Manual)

**Why This Option:**
- Modern, matches Journal reference
- FAB is easy to reach with thumb
- Doesn't compete with content
- Clear visual hierarchy

---

### 6. LOG CARD COMPONENT

**Current → New Design:**
```
CURRENT:
┌─────────────────────────────────────┐
│ [img]  Sunday           ●          │
│        12:00 pm                    │
│        Regular                     │
└─────────────────────────────────────┘

NEW:
┌─────────────────────────────────────┐
│                                     │
│  [poop   Sunday, Jan 19      8:15a │
│   img]   ─────────────────────────  │
│          Score: 82  ●●  Good    >  │
│                     └─ indicators   │
└─────────────────────────────────────┘
```

**New Log Card Specs:**
- White background with subtle shadow
- Poop type image on left (48x48)
- Date + time on top right
- Score + category on bottom
- Indicators: hydration dot, blood dot (if applicable)
- Chevron for detail view expansion
- 16pt padding, 16pt corner radius

---

### 7. DAY LOGS MODAL

**Layout:**
```
┌─────────────────────────────────────┐
│  ✕     Sunday, January 19, 2026    │
├─────────────────────────────────────┤
│  3 logs                             │
│  ┌─────────────────────────────┐    │
│  │  8:15 AM                    │    │
│  │  [img] Score: 82    Good ●  │    │
│  │        Type 4 • Med Brown   │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │  2:45 PM                    │    │
│  │  [img] Score: 65    Loose ● │    │
│  │        Type 6 • Light Brown │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │  9:25 PM                    │    │
│  │  [img] Score: 45    Hard ●  │    │
│  │        Type 2 • Dark Brown  │    │
│  └─────────────────────────────┘    │
│                                     │
│  Daily Summary                      │
│  ┌─────────────────────────────┐    │
│  │ Avg Score: 64  │ 1 Good     │    │
│  │ Hydration: 72% │ 1 Loose    │    │
│  │ Blood: None    │ 1 Hard     │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

---

## Implementation Phases

### Phase 1: Foundation
- [ ] Update color constants in Extensions.swift
- [ ] Create new shadow modifiers
- [ ] Remove WelcomeView from ContentView
- [ ] Set `showWelcomeView = false` as default

### Phase 2: Design System
- [ ] Create DesignSystem.swift with all constants
- [ ] Update typography throughout
- [ ] Create reusable card component

### Phase 3: Home Page
- [ ] Redesign HomeView with white background
- [ ] Add personalized greeting with name
- [ ] Implement new Poop Score calculation
- [ ] Redesign mini stat cards
- [ ] Redesign calendar (compact with dots)
- [ ] Update LogCard component

### Phase 4: Insights Page
- [ ] Redesign InsightsView
- [ ] Add AI insight generation
- [ ] Add pattern cards
- [ ] Improve chart styling

### Phase 5: Manual Entry
- [ ] Redesign ManualEntryView
- [ ] Better type grid layout
- [ ] Add blood warning message

### Phase 6: Profile
- [ ] Redesign ProfileModal
- [ ] Add user stats
- [ ] Better section organization

### Phase 7: Navigation
- [ ] Implement floating capsule tab bar
- [ ] Add FAB for "Add Log"
- [ ] Action sheet for Camera/Manual choice

### Phase 8: Polish
- [ ] Animations and transitions
- [ ] Haptic feedback
- [ ] Final QA pass

---

## Files to Modify

| File | Changes |
|------|---------|
| `Extensions.swift` | Add new colors, shadows, typography |
| `ContentView.swift` | Remove WelcomeView, new tab bar |
| `HomeView.swift` | Complete redesign |
| `InsightsView.swift` | Add insights, redesign |
| `ManualEntryView.swift` | Cleaner layout |
| `ProfileModal.swift` | Add stats, sections |
| `LogCard.swift` | New design with score |
| `UserViewModel.swift` | Add Poop Score calculation |
| `Log.swift` | Add score property |

## Files to Delete

| File | Reason |
|------|--------|
| `WelcomeView.swift` | Removing onboarding for now |

## New Files to Create

| File | Purpose |
|------|---------|
| `DesignSystem.swift` | Centralized design tokens |
| `InsightGenerator.swift` | AI insight text generation |
| `Components/StatCard.swift` | Reusable stat card |
| `Components/FloatingTabBar.swift` | New navigation |

---

## Approval Checklist

Before implementation, confirm:
- [ ] Color palette approved
- [ ] Typography scale approved
- [ ] Home page layout approved
- [ ] Insights page layout approved
- [ ] Tab bar style approved (Floating + FAB)
- [ ] Poop Score calculation logic approved
- [ ] Ready to delete WelcomeView

---

*Design Spec v1.0 | Created for Pooply UI Overhaul*
