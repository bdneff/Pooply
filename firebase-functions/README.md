# Pooply Cloud Functions

Firebase Cloud Functions backend for Pooply. Hosts the `analyzePoop` HTTPS callable function that the iOS app invokes from `CameraView` to send a captured image to OpenAI's Vision API and return a structured stool analysis (type, color, size, hydration %, fiber %, blood detection, narrative).

This folder is self-contained and lives alongside the iOS app in the same monorepo for tighter coordination between API schema changes and iOS consumers. Split into its own repo later if needed — see [Splitting into its own repo](#splitting-into-its-own-repo) below.

---

## Layout

```
firebase-functions/
├── index.js                ← active function code (analyzePoop + Bristol scoring)
├── package.json            ← active dependencies (Node 20, OpenAI SDK, firebase-admin)
├── firebase.json           ← Firebase config — source is "." (this folder)
├── .firebaserc             ← project alias
├── functions/              ← ⚠️ stale boilerplate from `firebase init` — DO NOT use
│   ├── index.js                 (the placeholder "helloWorld" example)
│   └── package.json
└── node_modules/           ← gitignored
```

**Important:** `firebase.json` declares `"source": "."`, so the **root `index.js`** is the deployed function. The inner `functions/` subdirectory is leftover scaffolding from `firebase init` and is not used. Safe to delete if you want to clean up, but not blocking anything by being there.

---

## Prerequisites

- Node 20 (`nvm install 20 && nvm use 20`)
- Firebase CLI (`npm install -g firebase-tools`)
- Logged into the right Firebase project: `firebase login` then `firebase use <project-id>`

---

## First-time setup

```bash
cd firebase-functions
npm install
```

Set the OpenAI API key as a Firebase secret (the function reads it via `defineSecret("OPENAI_API_KEY")`):

```bash
firebase functions:secrets:set OPENAI_API_KEY
# paste your sk-... key when prompted
```

Verify the secret is registered:

```bash
firebase functions:secrets:access OPENAI_API_KEY
```

---

## Day-to-day commands

| Command | What it does |
|---|---|
| `npm run serve` | Spin up the local emulator (functions only) for offline testing |
| `npm run shell` | Interactive REPL to invoke functions manually |
| `npm run deploy` | Deploy to production — runs `firebase deploy --only functions` |
| `npm run logs` | Tail Cloud Functions logs from production |

Deploys typically take 1–3 minutes. The CLI prints the deployed function URL when it's done; the iOS app calls it via `Functions.functions().httpsCallable("analyzePoop")` so the URL is auto-resolved by the Firebase SDK.

---

## How the iOS app calls it

`Pooply/Services/AnalysisService.swift` invokes the function with the captured image (base64-encoded). The function:

1. Validates the request
2. Sends the image to OpenAI Vision (GPT-4o or similar)
3. Parses the model's JSON response into a typed schema
4. Maps the Bristol type to a deterministic hydration/fiber range (see `BRISTOL_SCORES` in `index.js`) so scores feel honest, not arbitrary
5. Returns a strict JSON shape the Swift side decodes into `AnalysisResult`

When changing the response schema, update **both** sides in the same commit:
- `firebase-functions/index.js` (response shape)
- `Pooply/Services/AnalysisService.swift` (`AnalysisResult` decoding)

This is the main reason this folder lives in the same repo as the iOS app.

---

## Splitting into its own repo

If/when you outgrow the monorepo (multiple platforms, separate CI, team scaling), extract this folder into a standalone repo while preserving its git history:

### Option A — `git subtree split` (simple, no plugins)

From the **root** of this repo:

```bash
# Create a new branch that contains ONLY firebase-functions/ history
git subtree split --prefix=firebase-functions -b firebase-functions-only

# Push that branch to a new GitHub repo (create it empty on github.com first)
git remote add functions-repo git@github.com:<your-org>/pooply-functions.git
git push functions-repo firebase-functions-only:main
```

After extraction:

```bash
# Remove the folder from the monorepo and commit
git rm -r firebase-functions
git commit -m "Move Firebase functions to dedicated repo"
git push origin main

# Delete the temp split branch
git branch -D firebase-functions-only
git remote remove functions-repo
```

### Option B — `git filter-repo` (cleanest history rewrite)

Install: `brew install git-filter-repo`

```bash
# Clone the monorepo into a sibling directory first (filter-repo is destructive)
git clone <monorepo-url> pooply-functions-extracted
cd pooply-functions-extracted

# Keep only the firebase-functions/ subdirectory and rewrite history
git filter-repo --subdirectory-filter firebase-functions

# Now this dir is a clean standalone repo — push to a new remote
git remote add origin git@github.com:<your-org>/pooply-functions.git
git push -u origin main
```

After either approach, in the new standalone repo you'll want to:
- Add a CI workflow (e.g., GitHub Actions) that runs `firebase deploy --only functions` on merge to `main` using a Firebase token
- Move the OpenAI secret rotation to a dedicated process
- Update the iOS team's contributing docs to point at the new repo for backend changes

---

## Secrets & security

- **Never commit `.env` files or API keys.** All secrets go through `firebase functions:secrets:set`.
- The OpenAI key is referenced via `defineSecret("OPENAI_API_KEY")` and only resolved at function-invocation time on Google's infrastructure.
- The function uses `onCall` (callable), which requires a Firebase Auth token on every request — unauthenticated callers are automatically rejected by the SDK before your code runs.

---

## Common issues

| Symptom | Fix |
|---|---|
| `Error: HTTP Error: 401, Request had invalid authentication credentials` from iOS | User isn't signed in to Firebase Auth. Check `AuthService` state. |
| `Function failed on loading user code` on deploy | Node version mismatch — ensure `engines.node` in `package.json` matches your local Node version. |
| `Secret OPENAI_API_KEY does not exist` at runtime | Set it via `firebase functions:secrets:set OPENAI_API_KEY` and redeploy. |
| Local emulator returns CORS errors | Use the iOS Firebase SDK's callable client (which handles emulator routing), not raw HTTP. |
