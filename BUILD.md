# Building PassKeeper

## Android APK (built locally on Windows)

Rebuild with the bundled SDK:

```powershell
D:\Project\WORKSPACE\FIles\PassKeeper\flutter\bin\flutter.bat build apk --release
```

Artifact: `build\app\outputs\flutter-apk\app-release.apk` (~51 MB, contains
arm32/arm64/x86_64). The version in `pubspec.yaml` (currently **1.1.2**) is
injected into the APK automatically; bump it there whenever you release
(versionCode increments with the `+n` part, e.g. `1.1.3+3`).

Note: the release build is signed with the **debug keystore** (config in
`android/app/build.gradle`). Fine for local installs and testing; for Play Store
distribution, create a real release keystore and signing config.

## iOS

An iOS build requires macOS + Xcode — it cannot be produced on Windows. Two supported paths:

### Option A: GitHub Actions (no Mac needed)

1. Create a GitHub repository and push this project (the embedded `flutter/` SDK
   folder is git-ignored already).
2. The `.github/workflows/build-mobile.yml` workflow builds on push (or manually
   from the Actions tab) and uploads two artifacts:
   - `PassKeeper-android` — release APK
   - `PassKeeper-ios` — **unsigned** `.ipa`
3. For running on your own devices, install the unsigned ipa via Sideloadly,
   AltStore, or Xcode (requires a free Apple ID). For TestFlight/App Store
   distribution you need a paid Apple Developer Program membership and code
   signing (sign via Xcode or `xcodebuild -exportArchive`).

### Option B: any Mac

```bash
flutter pub get
flutter build ipa --release        # signed, needs your signing setup
# or for local testing without signing:
flutter build ios --release --no-codesign
```

## Local environment notes

- Flutter SDK lives inside the project at `flutter/` (not on PATH) — always use
  the full path or add `flutter\bin` to PATH.
- Gradle uses the JDK bundled with Android Studio via `org.gradle.java.home`
  in `android/gradle.properties` (no `JAVA_HOME` on PATH needed).
- SDK licenses were accepted manually (`android-sdk/licenses/`) because
  cmdline-tools is missing; installing cmdline-tools + `flutter doctor
  --android-licenses` is the cleaner long-term fix.
- Parallel Gradle evaluation is disabled and evaluation order is anchored to
  `:app` in `android/build.gradle` — this is required for plugins like
  `android_file_picker` that read the `flutter` Gradle extension at build
  script evaluation time. Do not remove those blocks.

## Security / storage model (what the app does at runtime)

- Fully offline/local-first: entries live in a single AES-256-GCM encrypted
  file (`vault.enc`) in the app's documents directory; the vault key is
  derived from the master password with PBKDF2-HMAC-SHA256 (600k iterations)
  plus a random salt stored in `flutter_secure_storage`. No cloud anywhere.
- Wrong-password attempts lock out after 5 tries (escalating cooldowns).
- Biometric unlock must be **armed in Settings** (the master password is
  verified once, then the key is wrapped and stored). Arming checks that the
  device actually has biometrics; unlocking always shows a real
  fingerprint/Face prompt via `local_auth`.
- The "Block screenshots" toggle sets Android `FLAG_SECURE` through the
  `passkeeper/secure` MethodChannel (`MainActivity.kt`); it also hides the
  app content from the task switcher.
- Auto-lock (idle + when the app is backgrounded) is global, enforced by the
  router: vault screens can never render while the vault is locked.
- Copied passwords are cleared from the clipboard after the configured delay
  with one shared timer.
- Dead-weight dependencies (`sqflite`, `sqlcipher_flutter_libs`, `crypto`,
  `pointycastle`, `clipboard`) were removed; storage uses the encrypted file
  directly.

## Known upcoming maintenance (non-blocking)

- Kotlin 2.2.20 in `android/settings.gradle` will need an upgrade to ≥ 2.3.20
  in a future Flutter release.
- `cryptography_flutter` still applies the Kotlin Gradle Plugin; migrate or
  drop it when Flutter removes that path.
