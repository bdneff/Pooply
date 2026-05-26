# Pooply

> Your gut health companion. AI-powered stool tracking for a happier, healthier gut.

Pooply is an invite-only iOS app that lets users snap a photo of a stool sample and get instant, structured analysis (Bristol type, color, hydration %, fiber %, blood detection, and a plain-English narrative). It scores every log against the Bristol Stool Scale, visualizes weekly/monthly/yearly trends, and gamifies consistency with a Green Zone streak.

---

## Repository layout

```
pooply/
├── Pooply/                       ← iOS app (SwiftUI, iOS 17+)
│   ├── DesignSystem.swift             Theme tokens (colors, fonts, spacing)
│   ├── PooplyApp.swift                App entry point
│   ├── Models/                        Data models (Log, User, OnboardingData)
│   ├── Services/                      Firebase + UserDefaults + Subscription
│   ├── ViewModels/
│   └── Views/                         All UI surfaces
├── Pooply.xcodeproj/             ← Xcode project file
├── firebase-functions/           ← Cloud Functions backend (Node 20)
│   └── index.js                       analyzePoop — OpenAI Vision proxy
├── firestore.rules               ← Firestore security rules (source of truth)
├── storage.rules                 ← Firebase Storage security rules
├── privacy-policy.html           ← Hosted privacy policy artifact
└── README.md                     ← you are here
```

---

## Stack

- **iOS app:** SwiftUI, iOS 17+, Swift 5.10
- **Auth:** Firebase Auth (email/password + Sign in with Apple)
- **Database:** Cloud Firestore (`users/{uid}` + `users/{uid}/logs/{logId}`)
- **Storage:** Firebase Storage for log images (`users/{uid}/images/`)
- **Backend:** Firebase Cloud Functions (Node 20, OpenAI Vision API)
- **Analytics:** Firebase Analytics
- **Build / Distribution:** Xcode → App Store Connect

---

## iOS app — local dev

### Requirements
- Xcode 16+
- iOS 17+ simulator or device
- A `GoogleService-Info.plist` from your Firebase project, dropped into `Pooply/` (not committed — pull from your Firebase Console)

### Build & run

```bash
open Pooply.xcodeproj
```

Then in Xcode:
1. Select the **Pooply** target → **Signing & Capabilities** → set your team
2. Choose a simulator or your device
3. ⌘R to build and run

### Onboarding flow

`Welcome → Invite Code → 12-Question Survey → Auth → Completion → Home`

The invite-code gate is **mandatory** for closed beta. Codes live in the Firestore `inviteCodes` collection — see [Invite codes](#invite-codes) below.

---

## Firebase Cloud Functions — `firebase-functions/`

Hosts `analyzePoop`, the HTTPS callable function the iOS app invokes from `CameraView` after capture. It sends the image to OpenAI Vision, parses the response into a typed schema, maps the Bristol type to a deterministic hydration/fiber range, and returns it to the client.

### First-time setup

```bash
cd firebase-functions
npm install

# Set the OpenAI key as a Firebase secret
firebase functions:secrets:set OPENAI_API_KEY
# paste your sk-... key when prompted
```

### Commands

| Command | What it does |
|---|---|
| `npm run serve` | Run the local emulator (functions only) |
| `npm run shell` | Interactive REPL to invoke functions manually |
| `npm run deploy` | Deploy to production (`firebase deploy --only functions`) |
| `npm run logs` | Tail production logs |

> The inner `firebase-functions/functions/` subdirectory is stale boilerplate from `firebase init`. The deployed code is `firebase-functions/index.js` (because `firebase.json` declares `"source": "."`). Safe to delete the inner folder if you want to clean up; not blocking anything.

### Schema coordination

When changing the function's response shape, update **both sides in the same commit**:
- `firebase-functions/index.js` (the response JSON)
- `Pooply/Services/AnalysisService.swift` (the Swift `AnalysisResult` decoding)

That's the main reason this folder lives in the same repo as the iOS app — a single PR, single git log, one place to coordinate.

### Splitting into its own repo later

If you outgrow the monorepo, extract this folder while preserving git history:

```bash
# From the repo root — preserves only firebase-functions/ history into a new branch
git subtree split --prefix=firebase-functions -b firebase-functions-only

# Push to a new (empty) GitHub repo
git remote add functions-repo git@github.com:<your-org>/pooply-functions.git
git push functions-repo firebase-functions-only:main

# Then remove from this repo
git rm -r firebase-functions
git commit -m "Move Firebase functions to dedicated repo"
git push origin main
```

Cleaner alternative: `git filter-repo --subdirectory-filter firebase-functions` (requires `brew install git-filter-repo`).

---

## Security rules — `firestore.rules` + `storage.rules`

These are the **source of truth** for what's deployed to Firebase. The Firebase Console reflects what's running right now; these files are the version-controlled copy.

### Deploy rules

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```

### What's gated

| Path | Read | Write |
|---|---|---|
| `users/{uid}` | Owner only | Owner only |
| `users/{uid}/logs/{logId}` | Owner only | Owner only |
| `inviteCodes/{code}` | Public (so pre-auth gate works) | Auth'd, only `currentUses`/`redeemedBy` |
| `users/{uid}/images/*` (Storage) | Owner only, max 10MB, `image/*` only | Owner only |
| Everything else | Denied | Denied |

> ⚠️ `inviteCodes` reads are **public** by design — the invite-code phase runs *before* Firebase Auth in the onboarding flow, so requiring auth would block fresh-install users (including App Store reviewers). Codes contain no PII; updates are still gated by auth + field allowlist.

---

## Invite codes

Pooply is invite-only at launch. Each code is a Firestore document at `inviteCodes/{CODE}` with this shape:

```
{
  isActive: true,
  maxUses: 100,
  currentUses: 0,
  redeemedBy: ["<userId>", ...]
}
```

The validate step (`FirebaseService.validateInviteCode`) reads the doc and checks `isActive && currentUses < maxUses`. Redemption (`FirebaseService.redeemInviteCode`) runs *after* auth in `CompletionContent` and atomically increments `currentUses` + appends the user's UID to `redeemedBy`.

Create new codes manually in Firebase Console → Firestore → `inviteCodes` collection.

---

## App Store / TestFlight

### Required Firebase setup before submission
- `inviteCodes/{YOUR_CODE}` doc exists and `isActive: true`
- Firestore rules deployed with `allow read: if true;` on `inviteCodes`
- A demo Firebase Auth user created for the App Store reviewer (matches the credentials in App Store Connect → App Review Information)

### Required App Store Connect setup
- **App Review Information → Sign-In Information:** demo email + password
- **App Review Information → Notes:** include the invite code + a note about Sign in with Apple being supported
- **App Privacy → Published** with 7 data types declared (Name, Email, User ID, Health, Photos, Product Interaction, Crash Data)
- **App Information → Regulated Medical Device:** No
- **App Information → Content Rights:** No third-party content

### Build numbers
Each upload requires a unique build number. Bump it in Xcode → target → General → Identity → Build before archiving.

---

## Brand

| Token | Hex |
|---|---|
| Background (cream) | `#F6F1E7` |
| Brand main (baby blue) | `#8ADBFF` |
| Mascot (caramel) | `#C68F4A` |
| Text primary (espresso) | `#2A201A` |

Full token map lives in `Pooply/DesignSystem.swift`.

---

## Privacy

Pooply is privacy-first. Logs and photos are encrypted, scoped to the owning user via Firestore + Storage rules, and never shared with advertisers or third parties. Hosted privacy policy: <https://grossyb.github.io/pooply_privacy/>.
