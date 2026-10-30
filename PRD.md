# PassKeeper: Product Requirements Document (PRD)

**Version:** 1.1
**Status:** Draft → Ready for implementation
**Owner:** Product / Engineering
**Last updated:** 2026-10-23
**Handoff:** Execute tasks in `TASKS.md` in order with `@frodo`.

---

## 1. Vision

A secure, offline-first password manager for Android and iOS from a single codebase. PassKeeper lets a single user store, organize, and retrieve login credentials entirely on-device, with no account, no server, and no network dependency. Security is the product: every byte of vault data is encrypted at rest with a key derived from the user's master password.

## 2. Scope

### 2.1 In scope (v1)
- Master-password-protected vault, optional biometric unlock.
- CRUD for login entries with title, username, password, website, notes, category, favorite flag.
- Search and filter by title, website, category; favorites pinned on top.
- Password generator with adjustable length and character types; strength meter.
- Clipboard copy with automatic clear after a configurable timeout (default 30s).
- Encrypted backup export/import (file-based, cross-device).
- Change master password with full vault re-encryption.
- Settings: auto-lock timeout, biometrics toggle, theme (light/dark/system), clipboard timeout.
- Hardening: screenshot/app-switcher blocking, no sensitive logging, no plain-text storage.

### 2.2 Out of scope (v1) — explicitly deferred
- Cloud sync, accounts, or any server component.
- Browser extensions, desktop clients, web app.
- Autofill / keyboard integration.
- Team sharing, multi-user, or shared vaults.
- Passkeys / FIDO2, TOTP, secure notes beyond free-text notes.
- Password breach checking / Have-I-Been-Pwned integration.

### 2.3 Assumptions (change these if wrong)
- Framework: Flutter (one codebase for Android and iOS).
- Storage: local only, encrypted on device. No cloud account, no server.
- Unlock: master password, with optional biometrics (fingerprint / Face ID).
- Minimum OS: Android 8.0 (API 26), iOS 13.
- Single user per device install (no multi-profile).

## 3. Personas

- **P1 — Privacy-first user:** wants a password manager that never touches the network; distrusts cloud providers.
- **P2 — Everyday user:** wants fast unlock (biometrics), quick search, and reliable copy-to-clipboard.
- **P3 — Migrator:** moving from another manager; needs encrypted backup import/export.

## 4. User Stories

Each story has: ID, priority (P0 = must have for v1, P1 = should have, P2 = nice to have), and acceptance criteria.

### 4.1 Onboarding and Unlock
- **US-1 (P0):** As a new user, I create a master password so that my vault is protected.
  - AC: Master password must be ≥ 8 chars with at least one upper, one lower, one digit, and one symbol (or a passphrase ≥ 4 words). Confirmation field must match. Strength meter shown. Salt + verification hash stored in secure storage. No plain-text password persisted.
- **US-2 (P0):** As a returning user, I unlock the app with my master password so that only I can see my data.
  - AC: Wrong password shows error without leaking which part failed; after 5 failed attempts, 30s cooldown; successful unlock derives key and opens vault; failed attempts logged count only (no password).
- **US-3 (P1):** As a user, I enable biometric unlock so that I can open the app quickly.
  - AC: Toggle in settings; biometric prompt on unlock; falls back to master password on failure/cancel; biometric does not replace master password (still required after reboot / first launch).
- **US-4 (P0):** As a user, I want the app to auto-lock after inactivity or when it goes to the background so that my data stays safe.
  - AC: Locks after configured idle timeout (default 60s); locks immediately on backgrounding (configurable); locked state clears in-memory key; returning requires unlock.

### 4.2 Vault Management
- **US-5 (P0):** As a user, I add an entry (title, username, password, website, notes) so that I can store a login.
  - AC: All fields optional except title; password required for "login" type; validation on title length; saves encrypted; success feedback.
- **US-6 (P0):** As a user, I view, edit, and delete entries so that my vault stays accurate.
  - AC: Detail screen shows all fields with show/hide; edit pre-fills; delete requires confirmation dialog; changes re-encrypt and persist.
- **US-7 (P0):** As a user, I search and filter entries by title, website, or category so that I can find them fast.
  - AC: Search debounced ≤ 200ms; case-insensitive contains; filter chips for categories; empty state shown.
- **US-8 (P1):** As a user, I organize entries into categories (Social, Banking, Work, Other).
  - AC: Category selectable on add/edit; default "Other"; filter by category; category color/icon.
- **US-9 (P1):** As a user, I mark favorites so that frequent logins appear first.
  - AC: Star toggle; favorites section pinned at top of list; persisted.

### 4.3 Password Tools
- **US-10 (P0):** As a user, I generate strong passwords with adjustable length and character types.
  - AC: Length slider 8–64; toggles for upper/lower/digits/symbols; at least one type selected; regenerate button; copy button.
- **US-11 (P0):** As a user, I see a password strength meter when creating or editing an entry.
  - AC: Meter updates live as password typed; categories: weak/fair/good/strong with color; uses entropy estimate.
- **US-12 (P0):** As a user, I copy a password to the clipboard, and the clipboard clears automatically after 30 seconds.
  - AC: Copy action shows snackbar; timer clears clipboard after configured timeout (default 30s, setting); if app backgrounded, clear immediately.
- **US-13 (P0):** As a user, I toggle password visibility so that I can check what I typed.
  - AC: Eye icon toggles masking; state resets on navigation.

### 4.4 Security and Data
- **US-14 (P0):** As a user, I want all vault data encrypted at rest (AES-256) with a key derived from my master password.
  - AC: AES-256-GCM; key via Argon2id (preferred) or PBKDF2 (≥ 600k iterations) fallback; unique salt per install; nonce per encryption; no plaintext in DB/logs.
- **US-15 (P1):** As a user, I export an encrypted backup and import it on another device.
  - AC: Export writes a single encrypted file (`.pkbackup`) containing salt + ciphertext; import verifies master password before restore; atomic replace with rollback on failure; file picker integration.
- **US-16 (P1):** As a user, I change my master password and the vault is re-encrypted.
  - AC: Requires current password; derives new key; re-encrypts all entries atomically; updates salt/verifier; rollback on failure.
- **US-17 (P0):** As a user, screenshots and app-switcher previews are blocked on sensitive screens.
  - AC: Android: FLAG_SECURE on all screens (or at least vault/unlock); iOS: blur overlay in app switcher; no screenshot in recents.

### 4.5 Settings
- **US-18 (P1):** As a user, I set the auto-lock timeout and toggle biometrics, dark mode, and clipboard timeout.
  - AC: Settings persisted in secure/encrypted store; changes apply immediately; defaults sensible.

## 5. Non-Functional Requirements

- **NFR-1 Offline:** Works fully offline; no network calls in v1.
- **NFR-2 Performance:** Cold start < 2s on mid-range device; list scroll 60fps for up to 1,000 entries; search < 100ms.
- **NFR-3 Security:** No secrets in logs, crash reports, or plain-text storage; key only in memory while unlocked; memory cleared on lock.
- **NFR-4 Compatibility:** Android 8.0+ (API 26), iOS 13+.
- **NFR-5 Accessibility:** Screen-reader labels on all interactive elements; sufficient contrast in both themes.
- **NFR-6 Reliability:** No data loss on crash during write (atomic transactions); backup/restore round-trips losslessly.
- **NFR-7 Size:** APK/AAB reasonable (< 30MB).

## 6. Data Model

```
Entry {
  id: UUID (primary key)
  title: string (required, 1..120)
  username: string?
  password: string? (encrypted as part of blob)
  website: string?
  notes: string?
  category: enum { social, banking, work, other } (default other)
  favorite: bool (default false)
  createdAt: ISO8601
  updatedAt: ISO8601
}

Vault (encrypted container) {
  version: int
  entries: Entry[]
}

SecureStorage {
  salt: bytes (16)
  verifier: bytes (verification hash of derived key)
  biometricsEnabled: bool
  settings: { autoLockSeconds, clipboardClearSeconds, theme, biometrics }
}
```

Storage: encrypted SQLite (or encrypted JSON file) for vault; platform secure storage (Keychain/Keystore) for salt, verifier, settings.

## 7. Security Design

- **KDF:** Argon2id (memory 64MB, iterations 3, parallelism 4) with 16-byte random salt. Fallback PBKDF2-HMAC-SHA256 (600,000 iterations) if Argon2 unavailable on platform.
- **Encryption:** AES-256-GCM; 12-byte random nonce per encryption; 16-byte tag. Ciphertext stored with nonce prepended.
- **Key handling:** Master password never stored. Derived key held in memory only while unlocked; zeroed on lock/background. No key in logs.
- **Verification:** Store HMAC/verification hash of derived key to validate password without storing password.
- **Biometrics:** Uses platform biometric API to gate access to a stored wrapped key (or to trigger unlock flow requiring master password fallback). Biometric alone never decrypts; it authorizes key release from Keystore/Keychain.
- **Backup:** Encrypted with same scheme but a separate salt included in file; master password required to import.
- **Change password:** Re-derive, re-encrypt all entries in a transaction; commit only on success.
- **Anti-tampering:** GCM tag verification on every read; corrupt data → fail closed (lock + error).

## 8. Architecture (feature-based)

```
lib/
  main.dart
  app/            # app widget, routing, theme
  core/           # crypto, storage, db, biometrics, clipboard, lifecycle
  features/
    onboarding/   # create master password
    unlock/       # unlock screen, biometric
    vault/        # list, detail, add, edit, delete
    generator/    # password generator
    settings/     # settings screen
    backup/       # export/import
  shared/         # widgets, models, utils
```

State management: Riverpod (or Bloc). Routing: go_router. DB: sqflite + sqlcipher (or drift) for encrypted storage. Secure storage: flutter_secure_storage.

## 9. Acceptance (release gate)

- All P0 user stories pass on one Android device and one iOS device.
- Security audit (security-audit skill) passes with zero high/critical findings.
- Test gate (test-gate skill) passes coverage thresholds (≥ 80% on core, ≥ 60% overall).
- No secrets in logs verified by static review + dynamic test.
- Backup round-trip verified on two devices.

## 10. Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Argon2 not available on some Android devices | High | PBKDF2 fallback with high iteration count |
| Key in memory exposure | High | Clear on background; no screenshots; short idle timeout default |
| Data loss on crash mid-write | Medium | Atomic transactions; backup before destructive ops |
| Biometric bypass concerns | Medium | Biometric only authorizes; master password still canonical |
| Performance with large vaults | Low | Index title; lazy loading; pagination |

## 11. Open Questions

1. Should v1 support import from other managers (CSV)? (Deferred decision — currently out of scope.)
2. Exact Argon2 parameters acceptable on low-end devices? (Benchmark during Phase 2.)
3. Should auto-lock default be 60s or 120s? (Default 60s, user configurable.)
