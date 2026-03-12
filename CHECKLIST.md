# Pooply — Launch Checklist

## Firebase Setup

- [x] Create Firestore collection `inviteCodes`
- [x] Add initial document `POOPLY2026` with fields:
  - `isActive: true`
  - `maxUses: 100`
  - `currentUses: 0`
  - `redeemedBy: []`
- [x] Firestore security rules written (`firestore.rules`) — deploy with `firebase deploy --only firestore:rules`
- [x] Storage security rules written (`storage.rules`) — deploy with `firebase deploy --only storage`
- [x] Deploy Firestore rules to Firebase (published via Console)
- [x] Deploy Storage rules to Firebase (published via Console, Storage enabled)
- [x] Verify Firebase Auth is enabled (Email/Apple Sign-In providers)
- [x] Verify Firestore indexes are set up for `users/{uid}/logs` (ordered by `timestamp`) — single-field, auto-created by Firestore
- [x] ~~Enable Firebase Cloud Messaging for push notifications~~ — using local notifications, not needed
- [x] Confirm `GoogleService-Info.plist` is the production bundle
- [x] Cloud Functions deployed (`analyzePoopImage`, `healthCheck`)

## Xcode / Project Configuration

- [ ] Set correct Bundle Identifier (`com.BrandonGrossnickle.Pooply`)
- [ ] Set deployment target (iOS 16+ recommended)
- [ ] Add Push Notifications capability in Signing & Capabilities
- [ ] Add Background Modes capability (Remote notifications)
- [ ] Add App Tracking Transparency capability (already using ATT prompt)
- [x] Add Sign in with Apple capability (in entitlements)
- [x] `Pooply.entitlements` has `aps-environment` set to `production`
- [ ] Set correct Team and provisioning profile
- [x] Confirm all fonts (Nunito-Black, Nunito-Bold, Nunito-Regular) are in bundle and `Info.plist`
- [ ] Confirm mascot image is in asset catalog
- [ ] Confirm app icon is in `AppIcon.appiconset` with correct `Contents.json`
- [ ] Set version number (e.g. `1.0.0`) and build number (e.g. `1`)
- [ ] Archive with Release configuration (not Debug)
- [x] Add `PrivacyInfo.xcprivacy` to project (drag into Xcode)
- [x] Add `Configuration.storekit` to project (drag into Xcode)

## RevenueCat / StoreKit

- [x] RevenueCat API key configured in `SubscriptionService.swift`
- [x] Create products in App Store Connect:
  - Weekly subscription (`pooply_weekly`)
  - Annual subscription (`pooply_annual`)
- [x] Create subscription group in App Store Connect (POOPLY UNLIMITED)
- [x] Add products to RevenueCat dashboard
- [x] Create offering `default` with `weekly` and `annual` packages in RevenueCat
- [x] Set entitlement identifier to `unlimited` in RevenueCat
- [x] Create StoreKit configuration file for local testing (`Configuration.storekit`)
- [ ] Test purchases in sandbox with sandbox Apple ID
- [ ] Test restore purchases flow
- [x] Test invite code bypass (should skip paywall entirely)
- [ ] Verify subscription persists across app relaunch
- [ ] Verify invite code access persists across app relaunch

## App Store Connect

- [ ] Create app listing in App Store Connect
- [ ] Fill in app name, subtitle, and description
- [ ] Add screenshots for required device sizes (6.7", 6.5", 5.5" — check current requirements)
- [ ] Add app preview video (optional but recommended)
- [ ] Set primary and secondary categories (Health & Fitness)
- [ ] Set age rating (complete the questionnaire)
- [x] Privacy policy URL: https://grossyb.github.io/pooply_privacy/
- [ ] Add terms of service URL
- [ ] Set pricing (Free with in-app purchases)
- [ ] Fill in review notes for App Review team
  - Mention the invite code feature and provide test code `POOPLY2026`
  - Provide test account credentials if using email auth
- [ ] Add subscription information (description, localization) in App Store Connect
- [ ] Submit for review

## Privacy & Legal

- [x] Host privacy policy at a public URL (https://grossyb.github.io/pooply_privacy/)
- [x] Privacy policy deployed via GitHub Pages
- [ ] Host terms of service at a public URL
- [ ] Complete App Privacy section in App Store Connect (data collection disclosures):
  - Health & Fitness (stool analysis data)
  - Contact Info (name)
  - Identifiers (user ID)
  - Usage Data (analytics)
  - Diagnostics (crash logs if using Firebase Crashlytics)
- [x] Add ATT usage description in `Info.plist` (`NSUserTrackingUsageDescription`)
- [x] Add camera usage description in `Info.plist` (`NSCameraUsageDescription`)
- [x] Add photo library usage description in `Info.plist` (`NSPhotoLibraryUsageDescription`)
- [x] Add `PrivacyInfo.xcprivacy` privacy manifest

## Testing

- [ ] Full onboarding flow: welcome → features → profile → questionnaire → auth → invite code → completion
- [ ] Enter wrong invite code → error message, error haptic, shake animation
- [ ] Enter valid invite code → green success message, success haptic, auto-advance after 1.5s
- [ ] Skip invite code → proceeds to completion → paywall appears after
- [ ] Complete with valid invite code → goes straight to main app (no paywall)
- [ ] Kill and reopen app after invite code → still has full access
- [ ] Kill and reopen app after subscription → still has full access
- [ ] Test swipe back from invite code screen
- [ ] Test swipe forward blocked on invite code screen
- [ ] Test onboarding progress bar shows correct step count
- [ ] Test camera capture and AI analysis flow
- [ ] Test manual log entry
- [ ] Test insights view with multiple logs
- [ ] Test profile modal
- [ ] Test push notification permission prompt
- [ ] Test ATT permission prompt
- [ ] Test on multiple device sizes (iPhone SE, iPhone 15, iPhone 15 Pro Max)
- [ ] Test with no internet connection (graceful error handling)
- [ ] Test with slow network (loading states)

## Marketing

- [ ] Create TikTok account for Pooply
  - Go to https://www.tiktok.com/signup
  - Username idea: `@pooplyapp`
  - Set up business account (for analytics)
  - Add app store link to bio once live
  - Plan content: gut health tips, app demos, funny poop facts, before/after tracking results
- [ ] Create Instagram account (`@pooplyapp`)
- [ ] Design App Store screenshots with marketing copy
- [ ] Create promotional graphics for social media
- [ ] Plan launch day social media posts
- [ ] Consider TikTok ads (can target health & wellness audience)
- [ ] Set up a simple landing page / website

## Post-Launch

- [ ] Monitor Firebase Analytics for onboarding completion rates
- [ ] Monitor invite code redemption counts
- [ ] Monitor RevenueCat dashboard for subscription metrics
- [ ] Monitor App Store Connect for crash reports
- [ ] Respond to App Store reviews
- [ ] Plan v1.1 based on user feedback
