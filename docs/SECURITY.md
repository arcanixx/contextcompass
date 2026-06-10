# SECURITY.md — ContextCompass

> Polityka bezpieczeństwa, prywatności i weryfikacji wieku.  
> Obowiązuje wszystkich contributerów, wszystkie platformy (web, plugin, mobile).

---

## Spis treści

1. [Autentykacja i sesje](#1-autentykacja-i-sesje)
2. [Urządzenia zaufane i auto-logout](#2-urządzenia-zaufane-i-auto-logout)
3. [Biometria (mobile)](#3-biometria-mobile)
4. [Weryfikacja wieku 18+](#4-weryfikacja-wieku-18)
5. [Szyfrowanie danych](#5-szyfrowanie-danych)
6. [Screenshoty i nagrywanie ekranu](#6-screenshoty-i-nagrywanie-ekranu)
7. [Prywatność danych — RODO/GDPR](#7-prywatność-danych--rodogdpr)
8. [Klucze API — zasady przechowywania](#8-klucze-api--zasady-przechowywania)
9. [Bezpieczeństwo pluginu przeglądarkowego](#9-bezpieczeństwo-pluginu-przeglądarkowego)
10. [Monitorowanie i alerty](#10-monitorowanie-i-alerty)

---

## 1. Autentykacja i sesje

### Metody logowania

| Metoda | Status | Uwagi |
|---|---|---|
| Email + hasło | ✅ MVP | Bcrypt przez Supabase Auth |
| Google OAuth | ✅ MVP | Priorytetowa (łatwiejsza weryfikacja wieku) |
| Apple OAuth | ✅ MVP | Wymagane dla iOS App Store |
| 2FA (TOTP) | ✅ MVP | Opcjonalne dla użytkownika, obowiązkowe przy włączaniu 18+ |
| Magic link (email) | 🔜 Post-MVP | Bez hasła, link jednorazowy |
| Biometria | ✅ Mobile | TouchID / FaceID / fingerprint przez expo-local-authentication |

### Tokeny JWT

```
Access token:   ważny 1 godzinę
Refresh token:
  - Zaufane urządzenie:  30 dni (odnawialny)
  - Niezaufane urządzenie: 15 minut (nie odnawialny)

Przechowywanie:
  - Web/PWA:    httpOnly cookie (preferred) lub memoria (sessionStorage na niezaufanych)
  - Plugin:     chrome.storage.local (encrypted)
  - Mobile:     expo-secure-store (iOS Keychain / Android Keystore)
```

### Nowe urządzenie / nowe IP

Przy pierwszym logowaniu z nowego adresu IP lub device fingerprint:
1. Modal informacyjny: "Logowanie z nowego urządzenia/miejsca"
2. Wysyłka kodu weryfikacyjnego na email (6-cyfrowy, ważny 10 minut)
3. Po weryfikacji kodu: pytanie o zaufanie urządzenia (patrz sekcja 2)

---

## 2. Urządzenia zaufane i auto-logout

### Flow dodawania urządzenia zaufanego

```
[Weryfikacja nowego urządzenia]
         ↓
[Modal: "Czy to Twoje prywatne urządzenie?"]
    |                        |
   TAK                      NIE
    ↓                        ↓
[Dodaj do trusted_devices]  [Sesja tymczasowa]
[Refresh token: 30 dni]     [Timeout: 15 min]
[Biometria: dostępna]       [Biometria: niedostępna]
[Auto-logout: wyłączony]    [Auto-logout: aktywny]
```

### Auto-logout (niezaufane urządzenia)

- Timer nieaktywności: resetowany przy każdym kliknięciu, przewijaniu, pisaniu
- Po 15 minutach: modal "Twoja sesja wygasła ze względów bezpieczeństwa"
- Dane lokalne (IndexedDB): wyczyszczone przy wylogowaniu
- Jeśli użytkownik wraca: ekran logowania z komunikatem wyjaśniającym

### Zarządzanie urządzeniami zaufanymi

W Ustawieniach → Bezpieczeństwo → Zaufane urządzenia:
- Lista: `{name, last_used, browser/OS, location}` (max 5 urządzeń)
- Przycisk "Usuń" przy każdym
- Przycisk "Usuń wszystkie (wyloguj wszędzie)"
- Przy przekroczeniu 5 urządzeń: automatycznie usuwa najstarsze

### Struktura w bazie

```json
// profiles.trusted_devices (JSONB)
[
  {
    "device_id": "fp_abc123",
    "name": "Chrome na MacBook Pro",
    "user_agent": "Mozilla/5.0...",
    "last_used": "2025-01-15T10:30:00Z",
    "created_at": "2025-01-01T00:00:00Z"
  }
]
```

---

## 3. Biometria (mobile)

### Obsługiwane metody

| Platforma | Metoda | API |
|---|---|---|
| iOS | Face ID | `expo-local-authentication` |
| iOS | Touch ID | `expo-local-authentication` |
| Android | Fingerprint | `expo-local-authentication` |
| Android | Face recognition | `expo-local-authentication` |

### Flow konfiguracji

```
[Pierwsze logowanie na mobile]
         ↓
[Udane logowanie email/hasło lub OAuth]
         ↓
[Modal: "Chcesz włączyć logowanie biometryczne?"]
[Wyjaśnienie: "Twoje dane NIE są wysyłane poza urządzenie"]
    |                    |
   TAK                  NIE
    ↓                    ↓
[Sprawdź dostępność]   [Pomiń — można włączyć później]
[Testowa autoryzacja]
[Zapisz flagę w profiles.settings.biometric_enabled]
```

### Zachowanie

- Ikona biometrii automatycznie dopasowana do typu: odcisk palca lub twarz
- Przy nieudanej biometrii (3 próby): fallback do hasła
- Przy zmianie hasła: biometria wymagana do ponownej konfiguracji
- Wyłączenie biometrii: Ustawienia → Bezpieczeństwo → Biometryczne logowanie

### Kod — kluczowe fragmenty

```typescript
// Wykrywanie dostępności i typu biometrii
const biometricTypes = await LocalAuthentication.supportedAuthenticationTypesAsync();
const hasFaceId = biometricTypes.includes(LocalAuthentication.AuthenticationType.FACIAL_RECOGNITION);
const hasFingerprint = biometricTypes.includes(LocalAuthentication.AuthenticationType.FINGERPRINT);

// Ikona w UI
const BiometricIcon = hasFaceId ? FaceIdIcon : FingerprintIcon;
```

---

## 4. Weryfikacja wieku 18+

### Cel

Aktywacja trybu 18+ odblokowuje:
- Template kontaktu `erotic`
- Zaawansowane szablony romantyczne
- System prompt AI bez filtrów treści dla dorosłych

### Metody weryfikacji (w kolejności pewności)

#### Poziom 1 — Self-declaration (MVP)
- Użytkownik wypełnia formularz: data urodzenia + checkbox "Oświadczam, że mam ukończone 18 lat"
- Formularz zawiera ostrzeżenie prawne
- Wiek obliczany po stronie klienta i serwera (edge function)
- Zapisywany: `profiles.age`, `profiles.verified_18plus = true`
- **Poziom pewności: niski** — standard dla MVP, akceptowalny prawnie jako "reasonable effort"

#### Poziom 2 — Weryfikacja emailem
- Link potwierdzający wysyłany na adres email
- Email musi być domeną komercyjną (nie-tymczasową — lista w `config/disposable-email-domains.json`)
- **Poziom pewności: średni**

#### Poziom 3 — Google/Apple (konto płatne) [Post-MVP]
- Konto Google Workspace lub Apple ID z informacją o wieku (jeśli API udostępnia)
- **Poziom pewności: wysoki**

#### Poziom 4 — Weryfikacja tożsamości [Komercyjna wersja]
- Integracja z Yoti lub Veriff (skan dowodu)
- Kosztowne (~0,5–2€ za weryfikację), opłacalne przy dużej bazie użytkowników
- **Poziom pewności: bardzo wysoki**

### Flow weryfikacji w aplikacji

```
[Użytkownik próbuje wybrać template 'erotic' lub 'romantic_advanced']
         ↓
[profiles.verified_18plus == false?]
         ↓
[Modal weryfikacyjny:]
  - Informacja: "Ta funkcja dostępna tylko dla dorosłych"
  - Formularz: data urodzenia (DatePicker)
  - Checkbox: oświadczenie (z linkiem do Regulaminu)
  - Przycisk "Potwierdź i zweryfikuj"
         ↓
[Edge Function: oblicza wiek, waliduje]
  - Wiek < 18 → odrzucenie z komunikatem, flaga nie ustawiana
  - Wiek >= 18 → ustawia profiles.verified_18plus = true
         ↓
[Sukces: modal zamknięty, funkcja odblokowana]
[Toast: "Dostęp do treści dla dorosłych odblokowany"]
```

### Zabezpieczenia AI bez weryfikacji

Gdy `verified_18plus = false`:
- System prompt zawiera: "WAŻNE: Nie generuj treści erotycznych, seksualnych ani sugestywnych. Odrzucaj takie prośby."
- Lista słów kluczowych w `config/adult-keywords.json` jest filtrowana w Edge Function `ai-proxy`
- Template `erotic` ukryty w UI (nie tylko disabled — niewidoczny w dropdownie)

---

## 5. Szyfrowanie danych

### Dane lokalne (IndexedDB)

```
Algorytm:     AES-GCM 256-bit
Klucz:        derywowany z hasła użytkownika (PBKDF2) + sól przechowywana w Supabase
IV:           32 bajty losowe, generowane przy każdym zapisie
```

Zaszyfrowane pola:
- `conversation_messages.content`
- `contacts.context`
- `profiles.ai_insights`

Niezaszyfrowane (metadane):
- ID rekordów, timestamps, typy (potrzebne do synchronizacji)

```typescript
// cryptoService.ts — interfejs
export async function encryptText(plaintext: string, userId: string): Promise<string>
export async function decryptText(ciphertext: string, userId: string): Promise<string>
export async function initCryptoKey(userId: string, password: string): Promise<CryptoKey>
```

### Dane w Supabase

- Szyfrowanie w spoczynku: wbudowane w platformę Supabase (AES-256)
- Transport: HTTPS/TLS 1.3
- Wrażliwe pola w bazie: hashe (nie raw treść rozmów)

### Zasada minimalizacji danych

- **Nie przechowujemy** pełnych treści wklejonych rozmów
- Przechowujemy: podsumowanie wygenerowane przez AI, metadane, hash (do deduplikacji)
- Użytkownik może eksportować wszystkie swoje dane → ZIP z JSON

---

## 6. Screenshoty i nagrywanie ekranu

### Web / PWA

**Ograniczenia techniczne:** Web API nie pozwala na pełne zablokowanie screenshotów. Stosujemy:

1. **Nasłuch klawiszy** → PrintScreen, Cmd+Shift+3, Cmd+Shift+4:
   ```typescript
   document.addEventListener('keydown', (e) => {
     if (e.key === 'PrintScreen' || (e.metaKey && e.shiftKey && ['3','4'].includes(e.key))) {
       blurSensitiveContent();
       showScreenshotWarning();
     }
   });
   ```
2. **Page Visibility API** → `visibilitychange` (użytkownik przełącza aplikację):
   - Automatyczne zamazanie wrażliwych treści przez 2s po powrocie
3. **CSS blur** na wrażliwych sekcjach podczas zdarzeń screenshotowych:
   ```css
   .sensitive-content.screenshot-blur {
     filter: blur(20px);
     transition: filter 0.1s;
   }
   ```

### React Native (Android)

```typescript
// Blokada natywna — ustawiana przy montowaniu głównego komponentu
import { Platform } from 'react-native';
import RNScreenshotPrevent from 'react-native-screenshot-prevent';

// W App.tsx useEffect:
if (Platform.OS === 'android') {
  RNScreenshotPrevent.enabled(true);  // FLAG_SECURE
}
```

### React Native (iOS)

```typescript
// iOS nie pozwala programowo zablokować screenshotów
// Wykrywamy screenshot/nagranie:
RNScreenshotPrevent.addListener(() => {
  toast.warning(t('security.screenshot_detected'));
  blurSensitiveContent();
});
```

### Plugin przeglądarkowy

- Plugin nie ma kontroli nad screenshotami strony hosta
- Overlay z podpowiedziami jest w shadow DOM — zniknie przy większości screenshot tools
- Ostrzeżenie w onboardingu: "ContextCompass nie może zapobiec screenshotom w przeglądarce"

---

## 7. Prywatność danych — RODO/GDPR

### Prawa użytkownika (zaimplementowane)

| Prawo | Implementacja |
|---|---|
| Dostęp do danych | Przycisk "Pobierz moje dane" → ZIP z JSON (wszystkie tabele) |
| Sprostowanie | Edycja profilu i kontaktów w aplikacji |
| Usunięcie (prawo do bycia zapomnianym) | Przycisk "Usuń konto" → cascade delete w DB, token invalidation |
| Przenoszalność | Export ZIP/JSON |
| Sprzeciw wobec profilowania | Wyłączenie "Aktualizacja profilu przez AI" w ustawieniach |

### Polityka prywatności — wymagane elementy

Dokument `PRIVACY_POLICY.md` (do wygenerowania przez prawnika lub Termly.io):
- Administrator danych: [imię/firma, adres, email]
- Cel przetwarzania: analiza komunikacji, personalizacja podpowiedzi AI
- Podstawa prawna: zgoda (art. 6 ust. 1 lit. a RODO)
- Okres przechowywania: do usunięcia konta + 30 dni (backup)
- Podmioty trzecie: Supabase (USA, Privacy Shield), Google (AI), Stripe (płatności)
- Przekazywanie do krajów trzecich: tak (Supabase USA) — standardowe klauzule umowne
- Kontakt DPO: [email]

### Cookies i śledzenie

- Cookies sesyjne: tylko do autentykacji (httpOnly, Secure, SameSite=Strict)
- Brak cookies reklamowych / śledzących
- Brak Google Analytics (jeśli użytkownik nie wyrazi zgody)
- Opcjonalna, anonimowa telemetria błędów (opt-in przy rejestracji)

### Lokalizacja danych

- Supabase region: `eu-central-1` (Frankfurt) — dane w UE
- Backupy automatyczne Supabase: region EU

### Zgoda na przetwarzanie

- Przy rejestracji: checkbox "Akceptuję Politykę Prywatności i Regulamin" (wymagany)
- Przy włączaniu trybu 18+: osobna zgoda na przetwarzanie danych wrażliwych (art. 9 RODO)
- Wiek <18 próbuje się zarejestrować: zablokowane, komunikat

---

## 8. Klucze API — zasady przechowywania

### Gdzie MOŻNA trzymać klucze

| Lokalizacja | Dostęp | Klucze |
|---|---|---|
| Supabase Edge Function env | Serwer only | GEMINI_KEY, GROQ_KEY, OPENAI_KEY (nasze) |
| Supabase Vault (secrets) | Serwer only | STRIPE_SECRET, ERROR_WEBHOOK_URL |
| `expo-secure-store` (mobile) | Urządzenie użytkownika | Klucz użytkownika (własny OpenAI etc.) |
| `chrome.storage.local` (plugin) | Urządzenie użytkownika | Access token JWT |

### Gdzie NIGDY nie trzymać kluczy

- ❌ Kod źródłowy (`.ts`, `.js`, `.json`)
- ❌ `.env` commitowany do repozytorium
- ❌ Zmienne `VITE_*` (trafiają do bundle JS klienta)
- ❌ `localStorage` / `sessionStorage` (xss podatność)
- ❌ URL query params

### Klucze użytkownika (własne API)

Gdy użytkownik chce użyć swojego klucza OpenAI/Claude:
1. Pole w Ustawieniach → AI → "Własny klucz API"
2. Klucz szyfrowany przez `cryptoService.ts` (AES-GCM)
3. Zaszyfrowany zapisywany w `profiles.settings` w Supabase
4. Odszyfrowanie tylko przez Edge Function (klucz deszyfrujący nigdy nie opuszcza serwera)
5. Komunikat w UI: "Klucz jest szyfrowany i nigdy nie jest wysyłany w postaci jawnej"

---

## 9. Bezpieczeństwo pluginu przeglądarkowego

### Content Security Policy (CSP)

```json
// manifest.json
"content_security_policy": {
  "extension_pages": "script-src 'self'; object-src 'none'; connect-src https://*.supabase.co https://generativelanguage.googleapis.com"
}
```

### Izolacja content script

- Shadow DOM dla overlay UI — brak interferencji z CSS strony
- `window.postMessage` z weryfikacją `origin` — nie nasłuchuj na wszystkie wiadomości
- Żadnych eval(), new Function() w kodzie pluginu

### Uprawnienia — minimalne

- `activeTab` — nie `tabs` (mniej uprawnień)
- `storage` — tylko `chrome.storage.local`, nie sync (dane nie wędrują na serwery Google)
- `contextMenus` — dla prawego przycisku
- `scripting` — dla content script injection (tylko na zadeklarowanych domenach)

### XSS w overlay

- Treści AI wyświetlane przez React (auto-escape) lub `textContent` (nie `innerHTML`)
- Tekst użytkownika/rozmówcy: sanityzacja przez `DOMPurify` przed wyświetleniem w overlay

---

## 10. Monitorowanie i alerty

### Tabela `error_logs` — co logować

| Typ zdarzenia | Poziom | Akcja |
|---|---|---|
| Błąd Edge Function | ERROR | Webhook do autora (natychmiast) |
| Błąd sync offline | WARNING | Zapis do DB (batch raport co 24h) |
| Nieudane logowanie (3x) | WARNING | Zapis + opcjonalne zablokowanie |
| Wyczerpanie limitu AI | INFO | Zapis, trigger do zmiany modelu |
| Błąd JS klienta | ERROR | Webhook jeśli > 10 na godzinę |
| Próba dostępu do 18+ bez weryfikacji | INFO | Zapis (analiza nadużyć) |

### Webhook autora

```typescript
// Payload webhookowy (POST do ERROR_WEBHOOK_URL)
{
  "event": "error",
  "severity": "ERROR",
  "message": "Edge Function ai-proxy failed: 500",
  "platform": "extension",
  "user_id": "uuid-anonymized",  // pierwsze 8 znaków UUID
  "timestamp": "2025-01-15T10:30:00Z",
  "app_version": "0.2.1",
  "error_id": "uuid-full"  // do wyszukania w Supabase
}
```

### Alerty automatyczne (Supabase cron + webhooks)

- Co 5 minut: sprawdź liczbę błędów ERROR w ostatnich 5 minutach → jeśli > 20, wyślij alert
- Co 24h: podsumowanie błędów z poprzedniego dnia na email autora
- Co tydzień: raport aktywności (nowe rejestracje, active users, AI calls, premium users)
