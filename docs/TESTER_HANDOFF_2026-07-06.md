# TransformFitAI Tester Handoff - 2026-07-06

## Build Status

- Web demo build: `build/web`
- Web preview URL: `https://captainamericafitnes-613a4a99--transformfit-v59-k2hja961.web.app`
- Android debug APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Current local Android APK SHA-256 after audit rebuild: `67ee44196e52269cef8121cec860bd6b257b565ebdbc958c58b9104889d0d318`
- Last Firebase-distributed Android APK SHA-256: `c473e3a1ad53c5b12027bca3c67a5eb5ed402553c9f542a401e80d33ffadad9d`
- Release-control note: redistribute the current local APK before claiming the latest rebuild is in testers' hands.
- Firebase App Distribution app: `1:526878839209:android:fd281dae618461636574b8`
- Tester emails pushed: Android `jloehr2131@gmail.com`, Apple/web `rodgemd1@gmail.com`
- Direct fallback emails sent from the local Google Mail account to both corrected recipients; see proof note `transformfit-v61-corrected-tester-email-proof.md`.
- iOS/TestFlight: blocked until full Xcode is selected and a valid signing identity is installed.

## Beta Scope

This is a constrained tester beta for the activation corridor, coach brief, wearable/DAI state, and workout logging loop. It is not an App Store or Play Store production release.

## Tester Tasks

1. Open the app and confirm the first screen tells you what to do next.
2. Start a session from the activation corridor.
3. Log one working set from the live logger.
4. Confirm the pinned bottom bar shows the set you are about to log.
5. Open Coach and explain, in your own words, today's call, why it changed, and what to do next.
6. Finish the workout and save the debrief.
7. Open Proof or Progress and confirm the app records the session honestly.

## Pass Criteria

- Tester can find the first action in under 10 seconds.
- Tester can log a set without scrolling back to verify exercise, load, reps, or RPE.
- Tester can explain why the coach changed the plan.
- No unsafe pain, medical, shame, or body-pressure copy appears.
- No crash in the first-session flow.

## Known Gaps

- No real recruited-user panel has run yet.
- TestSprite cloud/device testing is not proven in this environment.
- iOS native build and TestFlight are blocked by Xcode/signing.
- Android debug APK is sideloadable; Play Internal/App Bundle still needs scoped signing/release setup.
- Wearable integrations are represented in app state and gates; physical device HealthKit/Health Connect proof is still pending.
