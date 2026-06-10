# ARCHITECTURE_PRINCIPLES.md
# Zasady Architektury — Uniwersalny Przewodnik Projektowy

> **Przeznaczenie:** Ten plik to szablon wielokrotnego użytku. Wklej go do nowego projektu i uzupełnij sekcje `[PROJECT_SPECIFIC]`.
> Zawiera wszystkie kluczowe decyzje i zasady, które MUSZĄ być w każdym projekcie — niezależnie od domeny.
> **Dla AI:** Zanim napiszesz pierwszą linię kodu — przeczytaj ten dokument od początku do końca.

---

## SEKCJA A — INFORMACJE O PROJEKCIE `[PROJECT_SPECIFIC]`

```
Nazwa projektu:     ContextCompass
Typ:                Plugin przeglądarkowy + PWA + Mobile (React Native)
Opis (1 zdanie):    AI asystent kontekstu rozmów — podpowiada co i jak odpowiedzieć, pamiętając relację z rozmówcą
Stack:              React 18 + TypeScript + TailwindCSS + Supabase + Vite
Monorepo:           pnpm workspaces (shared / web / extension / mobile)
Backend:            Supabase (Auth, PostgreSQL, Edge Functions, Storage)
State management:   React hooks + IndexedDB (offline cache) + Supabase (source of truth)
Deploy:             Vercel (PWA) + Supabase (backend) + Chrome Web Store (plugin)
```

---

## SEKCJA B — OBOWIĄZKOWE MODUŁY (każdy projekt musi je mieć)

Poniższe moduły są niezbędne w każdym projekcie. Lokalizacja może się różnić, ale funkcja jest identyczna.

### B.1. Logger (`shared/services/logger.ts`)

Jeden centralny logger. Nigdy `console.log` bezpośrednio.

```typescript
// Interfejs obowiązkowy
export function logInfo(category: string, message: string, data?: unknown): void
export function logWarn(category: string, message: string, data?: unknown): void
export function logError(category: string, message: string, error?: unknown): void
export function captureError(error: Error, context?: ErrorContext): void

// Zachowanie:
// IS_DEV = true  → console.* z kolorami + kontekstem
// IS_DEV = false → wywołuje endpoint logowania błędów (webhook/Supabase/Sentry)
```

**Kategorie logów** — zdefiniuj w `constants.ts`:
```typescript
export const LOG_CATEGORIES = {
  AUTH: 'auth',
  SYNC: 'sync',
  AI: 'ai',
  UI: 'ui',
  IPC: 'ipc',        // dla Electron
  STORE: 'store',
  NETWORK: 'network',
} as const;
```

### B.2. Stałe (`shared/constants.ts`)

```typescript
export const IS_DEV = import.meta.env.DEV === true;
export const APP_VERSION = import.meta.env.VITE_APP_VERSION ?? '0.0.1';
export const APP_NAME = 'NazwaProjektu';

// Limity — zawsze w stałych, nigdy hardcoded w komponentach
export const LIMITS = {
  MAX_INPUT_LENGTH: 5000,
  MAX_CONTACTS: 10,           // free tier
  MAX_CONTACTS_PREMIUM: -1,   // unlimited
  AUTO_LOGOUT_MINUTES: 15,
} as const;

// Feature flags
export const FEATURES = {
  VOICE_INPUT: true,
  BIOMETRIC_AUTH: true,
  ADULT_CONTENT: false,       // wymaga weryfikacji 18+
  PREMIUM_FEATURES: false,
} as const;
```

### B.3. Konfiguracja (`config/default.config.json`)

Jeden plik JSON z wszystkimi domyślnymi wartościami. Nigdy hardcoded w kodzie.

```json
{
  "appName": "NazwaProjektu",
  "defaultLanguage": "pl",
  "supportedLanguages": ["pl", "en"],
  "security": { "autoLogoutMinutes": 15 },
  "limits": { "free": {}, "premium": {} },
  "debug": { "mockInDev": true, "logLevel": "info" }
}
```

### B.4. Internacjonalizacja (`config/locales/pl.json` + `en.json`)

- **Zero hardcoded stringów** w komponentach
- Klucze: `moduł.element.właściwość` (np. `auth.login.title`)
- Oba pliki muszą mieć identyczne klucze
- Skrypt `scripts/check_locales.js` weryfikuje spójność
- Interpolacja: `{{variableName}}` (i18next standard)

```json
{
  "common": {
    "save": "Zapisz",
    "cancel": "Anuluj",
    "clear_field": "Wyczyść pole",
    "loading": "Ładowanie...",
    "error_generic": "Coś poszło nie tak. Spróbuj ponownie.",
    "offline": "Brak połączenia — pracujesz offline"
  }
}
```

### B.5. Walidatory (`shared/validators.ts`)

Czyste funkcje walidacyjne + type guardy. Używane zarówno w UI jak i server-side.

```typescript
export function isValidEmail(value: unknown): value is string
export function isContact(value: unknown): value is Contact
export function sanitizeText(input: string, maxLength: number): string
```

### B.6. Moduł synchronizacji / storage (`shared/services/syncEngine.ts`)

Warstwa abstrakcji nad storage. Nigdy bezpośrednio `localStorage` ani `IndexedDB`.

```typescript
// Interfejs minimalny
export class SyncEngine {
  async save(key: string, data: unknown): Promise<void>
  async load<T>(key: string): Promise<T | null>
  async delete(key: string): Promise<void>
  async sync(): Promise<SyncResult>        // synchronizacja z backendem
  onNetworkRestore(callback: () => void): void
}
```

### B.7. Test runner (`scripts/run_tests.ts` lub `vitest`)

- Framework: **Vitest** (lub Jest dla Node)
- Mocki w `shared/mocks/` — nigdy prawdziwe API w testach
- Coverage minimum: **60% dla shared**, **40% dla UI**
- Każda publiczna funkcja serwisu = jeden test

### B.8. Skrypty developerskie (`scripts/`)

```
scripts/
├── check_headers.sh          # weryfikacja nagłówków plików
├── check_file_lengths.sh     # weryfikacja limitów linii
├── check_locales.js          # weryfikacja spójności tłumaczeń
├── generate_headers.sh       # automatyczne dodawanie nagłówków
└── deploy.sh                 # build + deploy (opcjonalnie)
```

---

## SEKCJA C — ZASADY STRUKTURY PLIKÓW

### C.1. Nagłówek (OBOWIĄZKOWY w każdym pliku)

```typescript
/*
 * File:       nazwaPliku.ts
 * Path:       packages/shared/src/services/nazwaPliku.ts
 * Exports:    eksportFn1, EksportType
 * Depends on: react, shared/services/logger, ../types/contact
 * Purpose:    Jedno zdanie opisujące funkcję pliku
 */
```

### C.2. Limity rozmiaru (TWARDE — weryfikowane przez CI)

| Typ pliku | Max linii |
|-----------|-----------|
| Komponent React | 150 |
| Hook | 100 |
| Serwis | 150 |
| Strona (page) | 120 |
| Plik typów | 200 |
| Edge Function | 150 |
| Dowolny inny | 200 |

**Jeśli plik przekracza limit → podziel, nie negocjuj.**

### C.3. Wzorzec podziału dużego modułu

```
FormularzKontaktu.tsx     ← max 150 linii, tylko JSX + lokalne handlery
useFormularzKontaktu.ts   ← logika formularza, walidacja, submit
formularzKontaktuUtils.ts ← czyste funkcje pomocnicze (testowalnie)
```

---

## SEKCJA D — ZASADY UX (OBOWIĄZKOWE — nie opcjonalne)

### D.1. Pola tekstowe — ZAWSZE przycisk X do czyszczenia

```tsx
// Każdy <input type="text"> i <textarea> MUSI mieć ClearableInput
<ClearableInput
  value={value}
  onChange={setValue}
  onClear={() => setValue('')}
  label={t('field.label')}
  helpText={t('field.help')}    // opcjonalne, tekst pod polem
/>
// X pojawia się TYLKO gdy value.length > 0
```

### D.2. Przyciski z akcją async — ZAWSZE LoadingButton

```tsx
<LoadingButton
  isLoading={isSubmitting}
  loadingText={t('common.saving')}
  onClick={handleSubmit}
>
  {t('common.save')}
</LoadingButton>
// Przycisk: disabled + spinner gdy isLoading
```

### D.3. Akcje destruktywne — ZAWSZE ConfirmDialog

Każda akcja usunięcia / wylogowania / wyczyszczenia = modal potwierdzenia.
**ZERO window.confirm(), window.alert(), window.prompt()**

```tsx
<ConfirmDialog
  isOpen={isOpen}
  title={t('item.delete.title')}
  description={t('item.delete.confirm', { name: item.name })}
  confirmLabel={t('common.delete')}
  confirmVariant="danger"
  onConfirm={handleDelete}
  onCancel={close}
/>
// Dla usunięcia konta: wymagane wpisanie "USUŃ" w pole tekstowe
```

### D.4. Powiadomienia — ZAWSZE toast, nigdy alert

```typescript
// Typy i czasy wyświetlania:
toast.success(t('...'))   // 3s — potwierdzenie zapisu
toast.error(t('...'))     // 8s — błąd (długi bo ważny)
toast.warning(t('...'))   // 5s — fallback, limit
toast.info(t('...'))      // 3s — zmiana modelu, info
// Max 3 toasty jednocześnie. Pozycja: top-right (desktop), top-center (mobile)
```

### D.5. Tooltips — OBOWIĄZKOWE dla ikon bez tekstu

```tsx
<Tooltip content={t('button.tooltip')} delay={500}>
  <IconButton
    icon={<MicrophoneIcon />}
    aria-label={t('button.aria')}   // dostępność!
    onClick={fn}
  />
</Tooltip>
```

### D.6. Stany ładowania — skeleton, nie globalny spinner

```
Listy / karty z API → skeleton loader (zarys struktury)
Przyciski akcji     → LoadingButton (spinner w przycisku)
Nawigacja stron     → pełnoekranowy loader (tylko tu!)
Minimalny czas      → 200ms (brak flashowania loaderów)
```

### D.7. Wskaźnik offline — widoczny na każdej stronie

```tsx
// W głównym layoucie (App.tsx lub Layout.tsx)
{!isOnline && (
  <NetworkBanner>
    {t('common.offline')}
  </NetworkBanner>
)}
// + blokada akcji AI gdy offline (z tooltipem wyjaśniającym)
```

### D.8. Sortowanie list — standard

Każda lista z więcej niż jednym elementem POWINNA mieć sortowanie. Minimalnie:
- **Domyślne** (najczęściej A–Z lub chronologiczne)
- **Po dacie/aktywności**
- Preferencja zapamiętana w `user.settings`

### D.9. Biometria (mobile)

```typescript
// Wykryj dostępność i typ, dostosuj UI:
const biometricType = await getBiometricType(); // 'face' | 'fingerprint' | null
// Pokaż odpowiedni przycisk + ikonę tylko gdy dostępna
// Fallback: logowanie hasłem przy nieudanej biometrii (3 próby)
```

---

## SEKCJA E — ZASADY BEZPIECZEŃSTWA

### E.1. Klucze API — absolutne reguły

```
✅ Klucze w zmiennych środowiskowych serwera (Edge Function secrets, .env server-only)
✅ Klient wysyła requesty przez własne API proxy — klucze nigdy nie docierają do przeglądarki
❌ NIGDY klucz w kodzie klienta
❌ NIGDY klucz w zmiennych VITE_* (trafiają do bundle)
❌ NIGDY klucz w localStorage, sessionStorage, IndexedDB (plain text)
```

### E.2. Storage — hierarchia

```
IndexedDB / localStorage    → tylko przez abstrakcję (localStore.ts / storageService.ts)
Dane wrażliwe               → szyfrowanie AES-GCM przez cryptoService.ts
Tokeny sesji                → przez bibliotekę auth (Supabase Auth / NextAuth) — nie ręcznie
```

### E.3. Walidacja danych

```typescript
// Zawsze waliduj dane przychodzące z zewnątrz (API, użytkownik, storage)
// Używaj type guardów — nie rzucaj bez sprawdzenia
function isValidData(value: unknown): value is MyType {
  return typeof value === 'object' && value !== null && 'requiredField' in value;
}
```

### E.4. Brak dangerouslySetInnerHTML

```typescript
// ❌ Nigdy
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// ✅ Zawsze przez DOMPurify lub textContent
<div>{sanitizedText}</div>
```

---

## SEKCJA F — ZASADY OBSŁUGI BŁĘDÓW

### F.1. Try/catch — zawsze w async

```typescript
// Każda async funkcja MUSI mieć try/catch
async function fetchData(id: string): Promise<Data | null> {
  try {
    const result = await apiCall(id);
    return result;
  } catch (err) {
    captureError(err instanceof Error ? err : new Error(String(err)), {
      action: 'fetchData',
      extra: { id }
    });
    return null;    // zwracamy null, nie rzucamy dalej
  }
}
```

### F.2. ErrorBoundary — na każdej stronie

```tsx
export default function PageName() {
  return (
    <ErrorBoundary fallback={<ErrorFallback />}>
      <PageContent />
    </ErrorBoundary>
  );
}
```

### F.3. Hierarchia błędów

| Typ błędu | Reakcja UI | Logger |
|-----------|-----------|--------|
| Brak sieci | NetworkBanner + blokada AI | `logWarn` |
| Błąd API (4xx) | Toast error + inline message | `logError` |
| Błąd krytyczny (5xx) | Toast error + raport do serwera | `captureError` |
| Błąd walidacji | Inline pod polem formularza | (brak, to oczekiwane) |
| Niezłapany crash | ErrorBoundary + raport | `captureError` |

---

## SEKCJA G — ZASADY DLA AI PRACUJĄCYCH NAD PROJEKTEM

### G.1. Zanim napiszesz kod — sprawdź

1. Czy istnieje już taki serwis/hook? (nie duplikuj)
2. Do którego pakietu należy kod? (`shared` / `web` / `extension` / `mobile`)
3. Czy plik będzie < 150 linii? (jeśli nie — zaplanuj podział)
4. Czy znasz klucz i18n dla każdego stringa w UI?

### G.2. Każdy wygenerowany plik MUSI mieć

- [ ] Nagłówek (`File`, `Path`, `Exports`, `Depends on`, `Purpose`)
- [ ] Try/catch w każdej async funkcji
- [ ] `captureError` w każdym catch
- [ ] Żadnych hardcoded stringów — tylko `t('klucz')`
- [ ] Żadnych `any` w TypeScript
- [ ] Brak `console.log` (tylko `logInfo/logWarn/logError`)

### G.3. Wzorce do zawsze stosowania

```typescript
// INPUT z X (clear)
<ClearableInput value={v} onChange={setV} onClear={() => setV('')} label={t('...')} />

// PRZYCISK async
<LoadingButton isLoading={loading} onClick={asyncFn}>{t('...')}</LoadingButton>

// USUNIĘCIE
<ConfirmDialog isOpen={open} onConfirm={del} onCancel={close} ... />

// TOAST
toast.success(t('...')) / toast.error(t('...')) / toast.warning(t('...'))

// TOOLTIP na ikonie
<Tooltip content={t('...')}><IconButton aria-label={t('...')} /></Tooltip>
```

### G.4. Pytaj gdy

- Nie wiesz do jakiego pakietu należy kod
- Zmiana schematu DB (nowa tabela / kolumna)
- Plik przekroczyłby 150 linii — zaproponuj podział
- Decyzja architektoniczna sprzeczna z tym dokumentem

### G.5. Działaj bez pytania gdy

- Tworzysz komponent UI według wzorców z Sekcji D
- Dodajesz testy do istniejącego kodu
- Uzupełniasz klucze i18n w obu plikach locales jednocześnie
- Naprawiasz błędy TypeScript (strict violations)

---

## SEKCJA H — CHECKLIST NOWEGO PROJEKTU

Przy starcie nowego projektu — zaznacz każdy punkt:

### Konfiguracja bazowa
- [ ] Monorepo skonfigurowane (`pnpm-workspace.yaml`)
- [ ] TypeScript strict mode (`strict: true` w tsconfig)
- [ ] ESLint + Prettier skonfigurowane
- [ ] Husky pre-commit hooks (lint + check_headers)
- [ ] `config/default.config.json` utworzony
- [ ] `config/locales/pl.json` i `en.json` utworzone (identyczne klucze)
- [ ] `shared/constants.ts` z `IS_DEV`, `APP_VERSION`, `LIMITS`, `FEATURES`

### Moduły obowiązkowe
- [ ] `shared/services/logger.ts` (logInfo, logWarn, logError, captureError)
- [ ] `shared/services/syncEngine.ts` (lub odpowiednik dla projektu)
- [ ] `shared/validators.ts` (type guardy dla głównych typów)
- [ ] `shared/mocks/` (mock serwisów dla testów i IS_DEV)
- [ ] `scripts/check_headers.sh`
- [ ] `scripts/check_file_lengths.sh`
- [ ] `scripts/check_locales.js`

### Komponenty UI obowiązkowe
- [ ] `ClearableInput` (input z X do czyszczenia)
- [ ] `LoadingButton` (przycisk z loading state)
- [ ] `ConfirmDialog` (modal potwierdzenia destruktywnych akcji)
- [ ] `ErrorBoundary` (catch błędów komponentów)
- [ ] `NetworkBanner` (wskaźnik offline)
- [ ] `Toast` system (success/error/warning/info)
- [ ] `Tooltip` wrapper

### Bezpieczeństwo
- [ ] `.env.example` z dokumentacją zmiennych
- [ ] `.gitignore` zawiera `.env.local`, `.env`, `*.key`
- [ ] Klucze API tylko w server-side env (Edge Functions / backend)
- [ ] RLS na wszystkich tabelach (jeśli Supabase)
- [ ] Walidacja inputów przed zapisem

### Dokumentacja
- [ ] `README.md` z Quick Start
- [ ] `docs/DEVELOPMENT_PLAN.md`
- [ ] `docs/CODING_STANDARDS.md`
- [ ] `docs/SECURITY.md`
- [ ] `docs/AI_PROMPT_GUIDE.md`
- [ ] `docs/UI_MOCKUP.html`
- [ ] `docs/CODE_REVIEW_CHECKLIST.md`
- [ ] `docs/AUDIT_CHECKLIST.md`
- [ ] `docs/ARCHITECTURE_PRINCIPLES.md` (ten plik)
- [ ] `logs/` folder (wyniki review i auditów)

---

## SEKCJA I — SZABLON SZYBKIEGO OPISU PROJEKTU

Gdy zaczynasz nowy projekt, wypełnij poniższy szablon. Na jego podstawie AI wygeneruje kompletną dokumentację.

```markdown
## Opis projektu

**Nazwa:** [NazwaProjektu]
**Typ:** [web app / mobile app / plugin / desktop / API]
**Jednozdaniowy opis:** [Co robi aplikacja i dla kogo]

**Użytkownicy:** [Kto będzie używał? Wiek, tech-savviness, kontekst użycia]
**Główne funkcje (max 7):**
1. ...
2. ...
3. ...

**Ograniczenia wiekowe:** [tak 18+ / nie]
**Monetyzacja:** [freemium / subskrypcja / jednorazowa / brak]
**Platformy:** [web / iOS / Android / Chrome plugin / desktop]
**Backend:** [Supabase / Firebase / własny / brak]
**AI w projekcie:** [tak — opis / nie]
**Offline support:** [tak / nie / częściowy]
**Powiadomienia:** [push / in-app / email / brak]

**Kluczowe ekrany (max 5):**
1. ...
2. ...

**Co NIE jest w projekcie (zakres MVP):**
- ...
```

---

## SEKCJA J — PYTANIA DO ZADANIA PRZED STARTEM

Przed napisaniem pierwszej linii kodu odpowiedz na:

1. **Czy potrzebujesz konta użytkownika?** → Tak: Supabase Auth. Nie: localStorage/IndexedDB wystarczy.
2. **Czy dane mają być synchronizowane między urządzeniami?** → Tak: backend wymagany.
3. **Czy są treści wrażliwe (18+, medyczne, finansowe)?** → Tak: dodaj weryfikację i disclaimery.
4. **Czy aplikacja działa offline?** → Tak: offline-first z IndexedDB + sync queue.
5. **Czy potrzebujesz powiadomień?** → Tak: Service Worker + Push API (web) / native (mobile).
6. **Jaki jest model monetyzacji?** → Wpływa na architekturę limitów i premium features.
7. **Czy będzie plugin przeglądarkowy?** → Tak: Manifest V3, Shadow DOM, oddzielna architektura.
8. **Czy będzie aplikacja mobilna?** → PWA wystarczy na start; React Native gdy potrzeba FLAG_SECURE lub lepszego audio.
9. **Kto będzie utrzymywał kod?** → 1 osoba: JavaScript + komentarze. Zespół: TypeScript strict + więcej testów.
10. **Jaki jest horyzont czasowy MVP?** → 4 tygodnie: uproszczona architektura. 3 miesiące: pełna.
