# 04_SECURITY.md
# Path: docs/04_SECURITY.md
# Purpose: Security model, biometric auth, session management, screenshot prevention
# Depends on: 01_ARCHITECTURE.md

---

# KlassMate — Security Design

---

## 1. Authentication Layers

KlassMate uses a **three-layer auth model**:

```
Layer 1: Identity        — Who are you? (Supabase Auth)
Layer 2: Device Trust    — Is this your device? (Device registry + biometrics)
Layer 3: Class Access    — Are you in this class? (RLS + class_members status)
```

All three must pass for a user to read or write messages.

---

## 2. Biometric Authentication

### Supported methods
| Platform | Method | Library |
|----------|--------|---------|
| iOS | Face ID, Touch ID | `expo-local-authentication` |
| Android | Fingerprint, Face Unlock | `expo-local-authentication` |
| Web | Not supported in MVP | (Web Authn Phase 2) |

### When biometrics are offered
1. After the **first successful email/password login** on a device, the app asks:
   > "Czy chcesz używać Face ID / odcisku palca do szybkiego logowania?"
   > [Tak, włącz] [Nie teraz] [Nigdy nie pytaj]

2. On subsequent app opens (session valid, device trusted): biometric prompt shown directly — no password needed.

3. Biometrics are **required again** (re-authentication) before:
   - Changing email or password
   - Deleting account
   - Revoking a trusted device
   - Exporting backup data
   - Viewing/copying another member's contact info

### Fallback behaviour
```
Biometric attempt fails (3x)
    │
    └──► Fall back to password prompt
              │
              └──► On success → grant access
                   On failure × 5 → lock account for 15 minutes, notify via email
```

### Storage
- Biometric preference: stored in **device Keychain** (iOS) / **Keystore** (Android) via `expo-secure-store`
- The Supabase session token is also stored in Keychain/Keystore, never in AsyncStorage
- On web: session token in `httpOnly` cookie (handled by Supabase Auth)

### Implementation sketch
```typescript
// src/lib/auth/biometrics.ts

import * as LocalAuthentication from 'expo-local-authentication';
import * as SecureStore from 'expo-secure-store';
import { logger } from '@/lib/errors/logger';

const BIOMETRIC_PREF_KEY = 'biometric_enabled';

export const isBiometricAvailable = async (): Promise<boolean> => {
  const compatible = await LocalAuthentication.hasHardwareAsync();
  const enrolled = await LocalAuthentication.isEnrolledAsync();
  return compatible && enrolled;
};

export const authenticateWithBiometrics = async (
  reason: string
): Promise<boolean> => {
  try {
    const result = await LocalAuthentication.authenticateAsync({
      promptMessage: reason,
      fallbackLabel: 'Użyj hasła',
      cancelLabel: 'Anuluj',
      disableDeviceFallback: false,
    });
    return result.success;
  } catch (error) {
    logger.error('Biometric auth failed', { error });
    return false;
  }
};

export const getBiometricPreference = async (): Promise<boolean> => {
  const val = await SecureStore.getItemAsync(BIOMETRIC_PREF_KEY);
  return val === 'true';
};

export const setBiometricPreference = async (enabled: boolean): Promise<void> => {
  await SecureStore.setItemAsync(BIOMETRIC_PREF_KEY, String(enabled));
};
```

---

## 3. Session & Device Trust

### Trusted vs Untrusted device

| | Trusted Device | Untrusted Device |
|--|---------------|-----------------|
| Example | User's own phone | School computer, friend's tablet |
| Session expiry | Never (until explicit logout) | 4 hours of inactivity |
| Biometrics | Offered and encouraged | Not offered |
| Re-login prompt | Only if session manually revoked | After 4h idle |
| How to trust | User taps "Trust this device" on first login | Default state for all new devices |

### First login on new device — flow
```
User logs in on new device
    │
    ├──► Show screen: "Zalogowano na nowym urządzeniu"
    │    Device info: [device name, OS, approximate location if available]
    │
    ├──► "Czy to Twoje urządzenie?"
    │    [Tak, to moje urządzenie — zaufaj] [Nie, wyloguj się]
    │
    ├──► If YES:
    │    - Insert into devices table (is_trusted = true)
    │    - Offer biometric setup
    │    - No session timeout
    │
    └──► If NO:
         - Insert into devices table (is_trusted = false)
         - Set session expiry timer (4h)
         - Skip biometric setup
         - Show info: "Zostaniesz automatycznie wylogowany po 4 godzinach bezczynności"
```

### Inactivity logout (untrusted device)
```typescript
// src/lib/auth/session.ts
const INACTIVITY_TIMEOUT_MS = 4 * 60 * 60 * 1000; // 4 hours

// On each user interaction, reset the timer
// On timer fire → call supabase.auth.signOut() + navigate to login
// On re-login on same untrusted device → do NOT re-show trust prompt
//   (user already said "no" or has the 4h timeout intentionally)
```

### Trusted devices management
- User can view all trusted devices in **Settings → Trusted Devices**
- Each entry shows: device name, OS, last seen date
- User can revoke any trusted device (requires biometric re-auth)
- Revoking immediately invalidates the session on that device

---

## 4. Two-Factor Authentication (2FA)

### Who requires 2FA
| Role | 2FA requirement |
|------|----------------|
| Class Admin | Mandatory — cannot hold admin role without 2FA enabled |
| Member | Optional (encouraged) |

### Method
- **TOTP** (Time-based One-Time Password) — compatible with Google Authenticator, Authy, etc.
- Supabase Auth has built-in TOTP MFA support

### 2FA flow
```
Admin enables 2FA in settings
    │
    ├──► Show QR code to scan in authenticator app
    ├──► Ask for confirmation code to verify setup
    ├──► Generate and display 8 backup codes (one-time use each)
    │    "Zapisz te kody w bezpiecznym miejscu!"
    └──► Save backup codes (hashed) to DB

Login with 2FA enabled:
    │
    ├──► Enter email + password
    ├──► Enter 6-digit TOTP code
    └──► OR enter a backup code (consume it from DB)
```

---

## 5. Screenshot Prevention

### Reality check (document for users)
| Platform | What we can do |
|----------|---------------|
| Android | `FLAG_SECURE` — prevents screenshots AND screen recording system-wide in the app |
| iOS | Cannot prevent screenshots. Can detect when a screenshot is taken and show a warning toast |
| Web | Cannot prevent screenshots or screen recording. Impossible on web. |

### Implementation
```typescript
// src/utils/platform.ts

import { Platform } from 'react-native';
import * as ScreenCapture from 'expo-screen-capture';

export const enableScreenshotPrevention = async (): Promise<void> => {
  if (Platform.OS === 'android') {
    await ScreenCapture.preventScreenCaptureAsync();
  } else if (Platform.OS === 'ios') {
    // Detection only — add listener, show toast warning
    ScreenCapture.addScreenshotListener(() => {
      // Show toast: "Pamiętaj o ochronie prywatności swoich kolegów"
    });
  }
  // Web: no-op
};
```

### User communication
- Do NOT say "screenshots are blocked" — say "Staramy się chronić prywatność użytkowników. Na urządzeniach Android wykonanie zrzutu ekranu jest niemożliwe w obrębie aplikacji."
- This is a `FEATURES.SCREENSHOT_PREVENTION` flag — if disabled, the feature is silently skipped.

---

## 6. Content Moderation Security

### Why moderation runs server-side (Edge Function)
- Client cannot be trusted to run its own moderation
- A malicious client could bypass client-side checks
- The moderation decision is made **before any data hits the database**
- RLS alone is not enough — we need pre-insert moderation

### Edge Function auth
- Edge Functions are called with the user's JWT
- The function validates the JWT and extracts `user_id`
- The function uses the **service role key** (server-side only, never exposed to client) to write to `moderation_queue`

### DM moderation specifics
- DMs run through the same `moderate-message` Edge Function
- **Critical difference:** If a DM is flagged, it goes to automatic rejection (no human review of DM content by admins)
- Class admins cannot see DM content, ever
- A user can manually report a DM via a "Zgłoś wiadomość" button → creates an anonymised report in `moderation_queue` (content hash only, not full text, until a superadmin reviews)

---

## 7. Data Encryption

| Data | Encryption method |
|------|------------------|
| Data in transit | TLS 1.3 (Supabase default) |
| Data at rest | AES-256 (AWS/Supabase default for Frankfurt region) |
| Session tokens | Stored in device Keychain/Keystore (OS-level encryption) |
| Attachment files | Encrypted in Supabase Storage at rest |
| Backup exports | ZIP with AES-256 password (user chooses password) |

---

## 8. Security Headers (Web/PWA)

Add to Expo web build output:
```
Content-Security-Policy: default-src 'self'; img-src 'self' data: blob: https://*.supabase.co; connect-src 'self' https://*.supabase.co wss://*.supabase.co
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(self), geolocation=()
```

---

## 9. Vulnerability Reporting

- Include a `SECURITY.md` in the repository root
- Provide an email address (e.g. `security@klassmatch.pl`) for responsible disclosure
- Commit to a 72-hour initial response time
