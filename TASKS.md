# PassKeeper: Tasks

**Status:** Not started
**Handoff:** Execute in order with `@frodo`. Mark each task `[x]` when done and verified. Do not skip the hardening and test gates.

Legend: `[ ]` not started · `[~]` in progress · `[x]` done · `[!]` blocked

---

## Phase 1: Foundation
- [ ] **T1.** Create a Flutter project named `passkeeper` targeting Android and iOS with a clean feature-based folder structure.
  - Acceptance: `flutter create` succeeds; folders per PRD §8; runs on emulator.
- [ ] **T2.** Add dependencies for encryption, secure storage, local database, biometrics, state management, and routing.
  - Acceptance: `pubspec.yaml` includes crypto, flutter_secure_storage, sqflite/sqlcipher or drift, local_auth, riverpod (or bloc), go_router; `flutter pub get` succeeds.
- [ ] **T3.** Set up the app theme with light and dark modes and shared UI components.
  - Acceptance: ThemeData for light/dark; theme toggle works; shared buttons/inputs/cards in `shared/widgets`.

## Phase 2: Security Core
- [ ] **T4.** Implement key derivation (Argon2id preferred, PBKDF2 fallback) turning master password into encryption key.
  - Acceptance: Unit tests for determinism, salt sensitivity, parameter correctness; fallback path tested.
- [ ] **T5.** Implement AES-256-GCM encryption and decryption for vault data.
  - Acceptance: Round-trip tests; tamper detection (GCM tag) fails closed; unique nonce per call.
- [ ] **T6.** Store key salt and verification hash in platform secure storage (Keychain/Keystore).
  - Acceptance: Values retrievable after restart; not in plain files; secure storage wrapper tested.
- [ ] **T7.** Build the encrypted local database layer for vault entries.
  - Acceptance: CRUD operations; transactional; encrypted at rest; migration path defined.

## Phase 3: Onboarding and Unlock
- [ ] **T8.** Build the create-master-password screen with strength meter and confirmation field.
  - Acceptance: Validation per US-1; strength meter live; persists salt/verifier; navigates to vault on success.
- [ ] **T9.** Build the unlock screen with master password entry.
  - Acceptance: Unlock works; wrong password error; lockout after 5 failures; no password logged.
- [ ] **T10.** Add biometric unlock with fallback to master password.
  - Acceptance: Toggle in settings; prompt on unlock; fallback works; required after reboot.
- [ ] **T11.** Implement auto-lock on inactivity and on app backgrounding.
  - Acceptance: Idle timer; background lock; key cleared; returns to unlock.

## Phase 4: Vault Features
- [ ] **T12.** Build the vault list screen with favorites pinned on top.
  - Acceptance: List renders; favorites section; empty state; pull-to-refresh (no-op offline).
- [ ] **T13.** Build the add-entry screen with all fields and category selection.
  - Acceptance: All fields; validation; saves encrypted; success feedback.
- [ ] **T14.** Build the entry detail screen with show/hide and copy actions.
  - Acceptance: Displays all fields; toggle visibility; copy password.
- [ ] **T15.** Build edit and delete flows with delete confirmation.
  - Acceptance: Edit pre-fills; delete confirms; persists.
- [ ] **T16.** Add search and category filtering to the vault list.
  - Acceptance: Debounced search; filter chips; combined filters.
- [ ] **T17.** Implement clipboard auto-clear after 30 seconds.
  - Acceptance: Clipboard cleared after configured timeout; clears on background.

## Phase 5: Password Tools
- [ ] **T18.** Build the password generator with length slider and character-type toggles.
  - Acceptance: Length 8–64; toggles; at least one type; regenerate; copy.
- [ ] **T19.** Integrate the generator and strength meter into add and edit screens.
  - Acceptance: Generate button fills password field; strength meter live.

## Phase 6: Data and Settings
- [ ] **T20.** Implement encrypted backup export to a file.
  - Acceptance: Writes `.pkbackup`; file picker; success feedback.
- [ ] **T21.** Implement backup import with master password verification.
  - Acceptance: Verifies password; atomic restore with rollback; error handling.
- [ ] **T22.** Implement change-master-password with full vault re-encryption.
  - Acceptance: Requires current password; re-encrypts all; rollback on failure.
- [ ] **T23.** Build the settings screen for auto-lock timeout, biometrics, theme, and clipboard timeout.
  - Acceptance: All toggles/sliders; persisted; applied immediately.

## Phase 7: Hardening
- [ ] **T24.** Block screenshots and hide app-switcher previews on Android and iOS.
  - Acceptance: FLAG_SECURE on Android; blur overlay on iOS recents.
- [ ] **T25.** Remove any logging of sensitive data and verify nothing is stored in plain text.
  - Acceptance: Static review; grep for password/key in logs; storage inspection.
- [ ] **T26.** Write unit tests for key derivation, encryption, and database layers.
  - Acceptance: Coverage ≥ 80% on core modules.
- [ ] **T27.** Write widget and integration tests for onboarding, unlock, and add-entry flows.
  - Acceptance: Tests pass on emulator.
- [ ] **T28.** Run the security-audit skill and fix every finding.
  - Acceptance: Zero high/critical findings.
- [ ] **T29.** Run the test-gate skill and confirm coverage thresholds pass.
  - Acceptance: Thresholds met.

## Phase 8: Release
- [ ] **T30.** Configure app icons, splash screens, and bundle identifiers for both platforms.
  - Acceptance: Icons/splash present; bundle IDs set; no default Flutter branding.
- [ ] **T31.** Build a signed Android release (AAB) and an iOS release archive.
  - Acceptance: AAB builds; iOS archive builds (on macOS).
- [ ] **T32.** Test on at least one physical Android device and one physical iOS device.
  - Acceptance: All P0 stories pass on both devices; results documented.

---

## Dependency Notes
- T4–T7 must complete before T8 (onboarding needs crypto/storage).
- T12–T17 depend on T7 (database).
- T20–T22 depend on T4–T7.
- T24–T29 depend on all feature tasks.
- T30–T32 depend on all prior tasks.

## Progress Log
| Date | Task | Note |
|---|---|---|
| 2026-10-23 | — | PRD and TASKS refined; Flutter scaffold + UI for design screens created (Welcome, Vault, Generator, Settings, onboarding, unlock). |

## Definition of Done (per task)
1. Code implemented and compiles (`flutter analyze` clean).
2. Unit/widget tests added or updated and passing.
3. No secrets logged; no plain-text sensitive storage.
4. Acceptance criteria in TASKS.md verified and checked off.
5. PRD user story acceptance criteria satisfied.
