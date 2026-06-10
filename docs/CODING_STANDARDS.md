# CODING_STANDARDS.md — ContextCompass

> Zasady pisania kodu obowiązujące w całym projekcie.  
> Przeznaczone dla: programistów, modeli AI (Claude, GPT, Gemini) pracujących nad kodem.  
> **Każdy contributor (ludzki lub AI) musi przeczytać ten plik przed dotknięciem kodu.**

---

## Spis treści

1. [Zasady ogólne](#1-zasady-ogólne)
2. [Nagłówki plików — obowiązkowe](#2-nagłówki-plików--obowiązkowe)
3. [TypeScript — wymagania](#3-typescript--wymagania)
4. [Struktura plików i rozmiar](#4-struktura-plików-i-rozmiar)
5. [Importy i eksporty](#5-importy-i-eksporty)
6. [Obsługa błędów](#6-obsługa-błędów)
7. [Internacjonalizacja (i18n)](#7-internacjonalizacja-i18n)
8. [Style i UI](#8-style-i-ui)
9. [Testy](#9-testy)
10. [Debug mode i mocki](#10-debug-mode-i-mocki)
11. [Bezpieczeństwo — zasady w kodzie](#11-bezpieczeństwo--zasady-w-kodzie)
12. [UX — obowiązkowe wzorce](#12-ux--obowiązkowe-wzorce)
13. [Git i commit messages](#13-git-i-commit-messages)
14. [Czego NIE robić](#14-czego-nie-robić)
15. [Co KONIECZNIE robić](#15-co-koniecznie-robić)
16. [Checklist przed PR](#16-checklist-przed-pr)

---

## 1. Zasady ogólne

- Kod piszemy w **TypeScript** (strict mode). Zero plików `.js` w `packages/`.
- Każdy plik ma **jedną odpowiedzialność** (Single Responsibility Principle).
- Nazwy zmiennych, funkcji i plików w **camelCase** (pliki komponentów React w PascalCase).
- Stałe globalne — **UPPER_SNAKE_CASE** w `constants.ts`.
- Komentarze — po polsku lub angielsku (konsekwentnie w jednym pliku), wyłącznie dla nieoczywistej logiki. Oczywisty kod nie wymaga komentarza.
- Żadnego kodu zakomentowanego w PR. Jeśli kod jest zbędny — usuń go, nie komentuj.
- Każda publiczna funkcja i typ — **JSDoc** z opisem parametrów.

---

## 2. Nagłówki plików — obowiązkowe

**Każdy plik** w `packages/` musi zaczynać się od nagłówka w następującym formacie:

```typescript
/*
 * File:       useAuth.ts
 * Path:       packages/web/src/hooks/useAuth.ts
 * Exports:    useAuth, AuthProvider
 * Depends on: react, @supabase/supabase-js, shared/services/supabaseClient
 * Purpose:    Hook zarządzający stanem autentykacji użytkownika
 */
```

### Zasady nagłówka

- `File` — sama nazwa pliku (bez ścieżki)
- `Path` — ścieżka od roota repozytorium
- `Exports` — lista eksportowanych stałych, funkcji, klas, typów (przecinkami)
- `Depends on` — lista importów (pakiety npm + lokalne ścieżki skrócone)
- `Purpose` — jedno zdanie opisujące co robi ten plik

Skrypt `scripts/generate_headers.sh` może wygenerować szkielet nagłówka automatycznie.  
Skrypt `scripts/check_headers.sh` weryfikuje, czy nagłówek istnieje we wszystkich plikach.

---

## 3. TypeScript — wymagania

### tsconfig.json (strict)
```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true
  }
}
```

### Typy — zasady

```typescript
// ✅ Dobrze
function getContact(id: string): Promise<Contact | null> { ... }

// ❌ Źle — any jest zakazane
function getContact(id: any): Promise<any> { ... }

// ✅ Dobrze — unknown z walidacją
function parseApiResponse(data: unknown): Contact {
  if (!isContact(data)) throw new Error('Invalid contact data');
  return data;
}

// ✅ Dobrze — type guard
function isContact(value: unknown): value is Contact {
  return typeof value === 'object' && value !== null && 'id' in value;
}
```

### Typy — gdzie trzymać

- Globalne typy domenowe → `packages/shared/src/types/`
- Typy lokalne (tylko w jednym komponencie) → zdefiniowane w tym samym pliku
- Typy API response → `packages/shared/src/types/api.ts`
- **Zakaz** definiowania tych samych typów w kilku miejscach

---

## 4. Struktura plików i rozmiar

### Limit rozmiaru

| Typ pliku | Maksimum |
|---|---|
| Komponent React | 150 linii |
| Hook | 100 linii |
| Serwis / utility | 150 linii |
| Strona (page) | 120 linii (logika w hookach) |
| Plik typów | 200 linii |
| Edge Function | 150 linii |

Jeśli plik przekracza limit → **podziel na mniejsze moduły**.  
Skrypt `scripts/check_file_lengths.sh` raportuje przekroczenia.

### Wzorzec podziału dużego komponentu

```
ContactForm.tsx           ← max 150 linii, tylko JSX + lokalne handlery
useContactForm.ts         ← logika formularza, walidacja, submit
contactFormValidators.ts  ← czyste funkcje walidacyjne (testowalnie)
contactFormTypes.ts       ← typy lokalne formularza (jeśli dużo)
```

---

## 5. Importy i eksporty

### Importy

```typescript
// ✅ Dobrze — konkretne importy
import { useState, useEffect } from 'react';
import { supabaseClient } from 'shared/services/supabaseClient';
import { Contact } from 'shared/types/contact';

// ❌ Źle — import całego modułu
import * as React from 'react';
import * as Types from 'shared/types';
```

### Eksporty

```typescript
// ✅ Dobrze — named exports (łatwiejsze tree-shaking i wyszukiwanie)
export function useAuth() { ... }
export const AUTH_TIMEOUT = 900;

// ❌ Źle — barrel re-exports (index.ts z export *)
export * from './useAuth';       // ZAKAZANE
export * from './useContacts';   // ZAKAZANE
```

**Wyjątek:** Plik `packages/shared/src/types/index.ts` może re-exportować **tylko typy** (nie funkcje, nie serwisy), ponieważ nie powoduje problemów z tree-shakingiem.

### Kolejność importów (Prettier + ESLint pilnują automatycznie)

1. Pakiety zewnętrzne (react, @supabase/...)
2. Pakiety wewnętrzne (shared/...)
3. Lokalne importy (../components/..., ./utils)
4. Typy (import type { ... })

---

## 6. Obsługa błędów

### Zasada: catch every async call

```typescript
// ✅ Dobrze
async function fetchContact(id: string): Promise<Contact | null> {
  try {
    const { data, error } = await supabase.from('contacts').select().eq('id', id).single();
    if (error) throw error;
    return data;
  } catch (err) {
    captureError(err instanceof Error ? err : new Error(String(err)), {
      action: 'fetchContact',
      extra: { contactId: id },
    });
    return null;
  }
}

// ❌ Źle — brak obsługi błędu
async function fetchContact(id: string) {
  const { data } = await supabase.from('contacts').select().eq('id', id).single();
  return data;
}
```

### Hierarchia błędów

- **Błędy sieciowe** (fetch fail, Supabase offline) → toast "Brak połączenia. Spróbuj ponownie."
- **Błędy AI** (limit, 429, timeout) → toast "AI chwilowo niedostępne — przełączono na [fallback]"
- **Błędy walidacji** → inline komunikat pod polem formularza
- **Błędy krytyczne** (crash komponentu) → ErrorBoundary z komunikatem i przyciskiem "Odśwież"
- **Wszystkie błędy produkcyjne** → `captureError()` z kontekstem

### ErrorBoundary — obowiązkowy

Każda strona (page) musi być opakowana w `<ErrorBoundary>`:

```typescript
// pages/Dashboard.tsx
export default function Dashboard() {
  return (
    <ErrorBoundary fallback={<ErrorFallback />}>
      <DashboardContent />
    </ErrorBoundary>
  );
}
```

---

## 7. Internacjonalizacja (i18n)

### Zasada absolutna: zero hardcoded stringów w UI

```typescript
// ✅ Dobrze
const { t } = useTranslation();
return <Button>{t('contact.add.button')}</Button>;

// ❌ Źle — hardcoded po polsku
return <Button>Dodaj osobę</Button>;

// ❌ Źle — hardcoded po angielsku
return <Button>Add person</Button>;
```

### Struktura kluczy w `config/locales/pl.json`

```json
{
  "common": {
    "save": "Zapisz",
    "cancel": "Anuluj",
    "delete": "Usuń",
    "confirm": "Potwierdź",
    "loading": "Ładowanie...",
    "error_generic": "Coś poszło nie tak. Spróbuj ponownie.",
    "offline_banner": "Brak połączenia — pracujesz offline",
    "clear_field": "Wyczyść pole"
  },
  "auth": {
    "login.title": "Zaloguj się",
    "login.email": "Adres e-mail",
    "login.password": "Hasło",
    "login.submit": "Zaloguj",
    "biometric.prompt": "Zaloguj się odciskiem palca lub Face ID"
  },
  "contact": {
    "add.title": "Dodaj osobę",
    "add.button": "Dodaj osobę",
    "name.label": "Imię lub pseudonim",
    "context.label": "Co wiesz o tej osobie?",
    "template.label": "Typ relacji",
    "template.general": "Ogólna",
    "template.romantic": "Romantyczna",
    "template.work": "Zawodowa",
    "template.erotic": "Intymna (18+)"
  },
  "hint": {
    "loading": "Generuję podpowiedź...",
    "copy": "Kopiuj",
    "copied": "Skopiowano!",
    "fallback_warning": "Używam szablonu offline (AI niedostępne)"
  }
}
```

### Zasada kluczy

- Format: `moduł.element.właściwość` (kebab-case wewnątrz sekcji)
- Nigdy nie duplikuj tłumaczeń — jeśli tekst jest wspólny, używaj `common.*`
- Interpolacja: `t('greeting', { name: user.name })` → `"Cześć, {{name}}!"`

---

## 8. Style i UI

### TailwindCSS — zasady

```typescript
// ✅ Dobrze — utility classes, bez własnego CSS
<button className="px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors">

// ❌ Źle — własne klasy CSS (poza animacjami)
<button className="my-custom-button">
```

### Paleta kolorów (zdefiniowana w `tailwind.config.js`)

```javascript
theme: {
  extend: {
    colors: {
      primary:   { 500: '#6366F1', 600: '#4F46E5' },  // indigo
      secondary: { 500: '#EC4899', 600: '#DB2777' },  // pink
      accent:    { 500: '#10B981' },                  // emerald
      danger:    { 500: '#EF4444' },                  // red
      warning:   { 500: '#F59E0B' },                  // amber
    }
  }
}
```

### Motyw ciemny/jasny

- Tailwind dark mode: `class` strategy (klasa `.dark` na `<html>`)
- Zmiana motywu: `document.documentElement.classList.toggle('dark')`
- Zapis preferencji: `profiles.settings.theme`
- Domyślnie: podążaj za systemem (`prefers-color-scheme`)

### Komponenty — zasady

- Każdy komponent ma **domyślny props** (nie rzuca error przy brakujących opcjonalnych propsach)
- Interaktywne elementy mają `aria-label` (dostępność)
- Focusable elements mają widoczny focus ring: `focus:ring-2 focus:ring-primary-500`
- Loading states: skeleton loader (nie spinner dla całej strony, tylko dla konkretnego elementu)

---

## 9. Testy

### Organizacja testów

```
packages/shared/src/services/__tests__/
  aiService.test.ts
  syncEngine.test.ts
  logger.test.ts

packages/web/src/hooks/__tests__/
  useAuth.test.ts
  useContacts.test.ts

packages/web/src/components/__tests__/
  ContactForm.test.tsx
  HintPanel.test.tsx

packages/extension/src/__tests__/
  contextMenu.test.ts
  textSelector.test.ts
```

### Wymagania

- Każdy **serwis** w `shared/services/` musi mieć testy jednostkowe
- Każdy **hook** musi mieć testy (używaj `renderHook` z `@testing-library/react`)
- Każda **page** musi mieć test E2E (Playwright) dla happy path
- Coverage minimum: **70%** dla `shared/`, **60%** dla `web/`

### Przykład testu jednostkowego

```typescript
// aiService.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { getAIHint } from '../aiService';
import { mockGeminiResponse } from '../../mocks/aiMock';

vi.mock('../supabaseClient', () => ({ supabase: mockSupabase }));

describe('getAIHint', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('returns hint variants when Gemini responds', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockGeminiResponse));
    const result = await getAIHint({ contactId: 'test-id', inputText: 'hej' });
    expect(result).toHaveLength(2);
    expect(result[0]).toHaveProperty('text');
    expect(result[0]).toHaveProperty('tone');
  });

  it('falls back to Groq when Gemini returns 429', async () => {
    // test fallback chain
  });
});
```

---

## 10. Debug mode i mocki

### Flaga DEV

```typescript
// packages/shared/src/constants.ts
export const IS_DEV = import.meta.env.DEV === true;
export const FORCE_MOCK_AI = import.meta.env.VITE_MOCK_AI === 'true';
export const FORCE_MOCK_SUPABASE = import.meta.env.VITE_MOCK_SUPABASE === 'true';
```

### Zachowanie w trybie DEV

| Moduł | Tryb DEV | Tryb PROD |
|---|---|---|
| AI | Mockowe odpowiedzi (instant) | Prawdziwe API |
| Supabase | LocalStorage mock | Prawdziwa baza |
| Logger | `console.error` | Edge Function + webhook |
| Błędy | Szczegółowy stack trace w UI | Ogólny komunikat |
| Limity AI | Ignorowane | Egzekwowane |
| Weryfikacja 18+ | Bypass checkbox | Pełny flow |

### Symulacja błędów (tylko DEV)

W `localStorage` można ustawić flagi symulacji:

```javascript
// W konsoli przeglądarki:
localStorage.setItem('__simulate_offline', 'true');
localStorage.setItem('__simulate_ai_429', 'true');
localStorage.setItem('__simulate_sync_error', 'true');
```

Aplikacja sprawdza te flagi w hookach i serwisach (wyłącznie gdy `IS_DEV`).

### Panel developerski (DEV only)

Floating button w prawym dolnym rogu (tylko gdy `IS_DEV`):
- Pokazuje: aktualny model AI, status sync, użycie limitów
- Przyciski: "Wymuś offline", "Zresetuj limity", "Wyczyść IndexedDB", "Wygeneruj test data"

---

## 11. Bezpieczeństwo — zasady w kodzie

### Klucze API — absolutny zakaz

```typescript
// ❌ NIGDY — klucz w kodzie klienta
const GEMINI_KEY = 'AIzaSy...';

// ❌ NIGDY — klucz w zmiennej VITE_ (trafia do bundle)
const key = import.meta.env.VITE_GEMINI_KEY;

// ✅ Dobrze — klucze tylko w Edge Functions (env serwera)
// W kliencie: wywołaj /functions/v1/ai-proxy, klucz nigdy nie opuszcza serwera
```

### Sanityzacja inputów

- Wszystkie dane wejściowe od użytkownika przechodzą przez `validators.ts` przed zapisem
- Przy wyświetlaniu danych z bazy używaj React JSX (automatyczny escape) — nigdy `dangerouslySetInnerHTML`
- Maksymalna długość pól: context → 2000 znaków, wiadomość → 5000 znaków, nazwa → 100 znaków

### Storage

- `localStorage` — zakazany bezpośrednio. Używaj `localStore.ts` (wrapper z szyfrowaniem)
- `chrome.storage.local` w pluginie — tylko przez `extensionStorage.ts`
- Wrażliwe dane (treści rozmów) → zawsze przez `cryptoService.ts` (AES-GCM)

---

## 12. UX — obowiązkowe wzorce

To jest **wymaganie funkcjonalne**, nie opcjonalne upiększenie.

### Pola tekstowe — obowiązkowo

Każde pole `<input>` lub `<textarea>` z możliwością wpisywania tekstu **musi** mieć:

```typescript
// ClearableInput.tsx — bazowy komponent dla wszystkich inputów tekstowych
<div className="relative">
  <input
    value={value}
    onChange={onChange}
    aria-label={ariaLabel}
    className="w-full pr-8 ..." // padding-right na przycisk X
  />
  {value.length > 0 && (
    <button
      onClick={onClear}
      aria-label={t('common.clear_field')}
      className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
    >
      <XMarkIcon className="w-4 h-4" />
    </button>
  )}
</div>
```

**Zasada:** Ikona X pojawia się wyłącznie gdy pole ma treść (`value.length > 0`).

### Toasty — system powiadomień

- Biblioteka: `react-hot-toast` lub własna implementacja przez Context
- Pozycja: górny prawy róg (desktop) / górny środek (mobile)
- Typy: `success` (zielony), `error` (czerwony), `warning` (żółty), `info` (niebieski)
- Czas wyświetlania: 3s (info/success), 5s (warning), 8s (error, z przyciskiem "X")
- Kolejkowanie: max 3 toasty jednocześnie na ekranie

```typescript
// Użycie (nigdy hardcoded string — zawsze przez t())
toast.success(t('contact.saved'));
toast.error(t('common.error_generic'));
toast.info(t('hint.fallback_warning', { model: 'Groq' }));
```

### Tooltips

- Biblioteka: Radix UI `Tooltip` lub `@floating-ui/react`
- Trigger: `hover` na desktop, `long press` (600ms) na mobile
- Delay: 500ms (żeby nie migały przy szybkim ruchu myszy)
- Zawartość: krótki opis (max 2 linijki), nigdy akcja klikalna wewnątrz tooltipa

```typescript
// Obowiązkowe dla:
// - ikon bez tekstu (np. przycisk mikrofonu, archiwizacji)
// - skróconych limitów (np. "12/30" → tooltip "12 podpowiedzi z 30 dziennych")
// - przycisku Premium (tooltip "Odblokuj nielimitowane podpowiedzi")
<Tooltip content={t('chat.voice_input.tooltip')}>
  <IconButton icon={<MicrophoneIcon />} onClick={startRecording} />
</Tooltip>
```

### Modale — zasady

- Żadnych `window.alert()`, `window.confirm()`, `window.prompt()` — zawsze modal
- Tło modalu: `backdrop-blur-sm bg-black/40`
- Zamykanie: kliknięcie tła, przycisk X, klawisz `Escape`
- Focus trap: focus pozostaje wewnątrz modalu (dostępność)
- Akcje destruktywne (usuń, wyloguj wszystkie urządzenia): dwuetapowe potwierdzenie

```typescript
// ConfirmDialog.tsx — wzorzec dla destruktywnych akcji
<ConfirmDialog
  title={t('contact.delete.title')}
  description={t('contact.delete.description', { name: contact.name })}
  confirmLabel={t('common.delete')}
  confirmVariant="danger"
  onConfirm={handleDelete}
  onCancel={closeModal}
/>
```

### Stany ładowania

- **Skeleton loader** (nie spinner) dla list i kart — pokazuje zarys struktury
- **Inline spinner** dla przycisków akcji (przycisk staje się disabled + spinner w środku)
- **Pełnoekranowy loader** tylko dla: inicjalizacji aplikacji, nawigacji między stronami
- Minimalne opóźnienie loaderów: 200ms (żeby nie migały przy szybkich odpowiedziach)

```typescript
// LoadingButton — wzorzec dla przycisków z akcją async
<LoadingButton
  isLoading={isSubmitting}
  loadingText={t('common.saving')}
  onClick={handleSubmit}
>
  {t('common.save')}
</LoadingButton>
```

### Help i onboarding

- **Tooltip na każdej nowej funkcji** (pierwsze uruchomienie) — jedna wskazówka na raz, `?` w rogu
- **Overlay z 3 krokami** (onboarding) — nie można pominąć (chyba że klikniesz "Pomiń")
- **Help icon** (`?`) przy każdej sekcji ustawień → otwiera modal z wyjaśnieniem
- **Opisy placeholder** w polach formularzy (nie zastępują labelek, są uzupełnieniem):

```typescript
<Input
  label={t('contact.context.label')}
  placeholder={t('contact.context.placeholder')} // "np. Poznaliśmy się na koncercie, lubi jazz..."
  helpText={t('contact.context.help')}           // Tekst pod polem: "To pomoże AI lepiej rozumieć tę rozmowę"
/>
```

### Wskaźnik offline

```typescript
// NetworkBanner.tsx — widoczny na każdej stronie, sticky top
{!isOnline && (
  <div className="sticky top-0 z-50 bg-warning-500 text-white text-sm text-center py-2 px-4">
    <WifiOffIcon className="inline w-4 h-4 mr-1" />
    {t('common.offline_banner')}
  </div>
)}
```

### Biometria (mobile — React Native)

Logowanie przez odcisk palca / Face ID:

```typescript
// packages/mobile/src/services/biometricAuth.ts
import * as LocalAuthentication from 'expo-local-authentication';

export async function authenticateWithBiometrics(): Promise<boolean> {
  const hasHardware = await LocalAuthentication.hasHardwareAsync();
  const isEnrolled = await LocalAuthentication.isEnrolledAsync();
  if (!hasHardware || !isEnrolled) return false;

  const result = await LocalAuthentication.authenticateAsync({
    promptMessage: t('auth.biometric.prompt'),  // "Zaloguj się odciskiem palca lub Face ID"
    fallbackLabel: t('auth.biometric.fallback'), // "Użyj hasła"
    cancelLabel: t('auth.biometric.cancel'),     // "Anuluj"
    disableDeviceFallback: false,               // Pozwól na PIN jako fallback
  });

  return result.success;
}
```

- Biometria dostępna: pokazuj przycisk z ikoną odcisku/twarzy na ekranie logowania
- Typ biometrii wykrywaj automatycznie i dostosuj ikonę (FaceID vs TouchID vs fingerprint)
- Przy pierwszym użyciu: modal wyjaśniający, że klucz jest przechowywany lokalnie na urządzeniu
- Ustawienie włączenia/wyłączenia biometrii: Ustawienia → Bezpieczeństwo

---

## 13. Git i commit messages

### Format commitów (Conventional Commits)

```
typ(zakres): krótki opis (max 72 znaki)

[opcjonalny dłuższy opis]

[opcjonalne: Closes #123]
```

### Typy

| Typ | Kiedy |
|---|---|
| `feat` | Nowa funkcjonalność |
| `fix` | Naprawa błędu |
| `docs` | Zmiany w dokumentacji |
| `style` | Formatowanie, spacje (bez zmiany logiki) |
| `refactor` | Refaktoryzacja bez nowych funkcji |
| `test` | Dodanie/zmiana testów |
| `chore` | Konfiguracja, zależności, skrypty |

### Przykłady

```
feat(contacts): dodano archiwizację kontaktów
fix(ai): poprawiono fallback na Groq po błędzie 429
docs(security): zaktualizowano opis weryfikacji 18+
test(sync): dodano testy offline dla SyncEngine
chore(deps): aktualizacja @supabase/supabase-js do 2.45
```

### Zasady branchy

```
main          → produkcja (chroniony, wymaga PR)
develop       → integracja feature branchy
feature/xyz   → nowa funkcjonalność
fix/xyz       → naprawa błędu
docs/xyz      → dokumentacja
```

---

## 14. Czego NIE robić

### Kod

- ❌ Nie używać `any` w TypeScript — zawsze `unknown` z type guard lub konkretny typ
- ❌ Nie tworzyć cyklicznych importów (A importuje B, B importuje A)
- ❌ Nie pomijać `await` przy async funkcjach
- ❌ Nie używać `localStorage` bezpośrednio — tylko przez `localStore.ts`
- ❌ Nie trzymać kluczy API w plikach klienta ani zmiennych `VITE_*`
- ❌ Nie używać `window.alert`, `window.confirm`, `window.prompt` — zawsze modal
- ❌ Nie hardcodować stringów UI — zawsze `t('klucz')`
- ❌ Nie używać `dangerouslySetInnerHTML`
- ❌ Nie pomijać `try/catch` w async funkcjach
- ❌ Nie commitować zakomentowanego kodu
- ❌ Nie dodawać nagłówka po napisaniu pliku — nagłówek jest PIERWSZY

### Architektura

- ❌ Nie duplikować logiki między `web/`, `extension/`, `mobile/` — wspólny kod do `shared/`
- ❌ Nie wywoływać Gemini/Groq/OpenAI bezpośrednio z klienta — zawsze przez Edge Function
- ❌ Nie zapisywać raw treści rozmów w bazie (tylko hash + podsumowanie AI)
- ❌ Nie ignorować stanu offline (zawsze obsłuż brak sieci)
- ❌ Nie tworzyć pliku przekraczającego 200 linii bez wcześniejszego podziału

### UX

- ❌ Nie wyświetlać pola tekstowego bez przycisku X (clear)
- ❌ Nie wyświetlać ikony bez tooltipa (o ile ikona jest interaktywna)
- ❌ Nie blokować UI globalnym spinnerem dla operacji > 2s — używaj skeleton loaderów
- ❌ Nie ignorować stanu ładowania/błędu — każda operacja async ma 3 stany: loading, success, error

---

## 15. Co KONIECZNIE robić

### Kod

- ✅ Zaczynaj każdy plik od nagłówka (File, Path, Exports, Depends on, Purpose)
- ✅ Używaj `captureError()` w każdym bloku `catch`
- ✅ Testuj offline przed każdym PR (wyłącz sieć w DevTools)
- ✅ Dokumentuj publiczne funkcje JSDoc
- ✅ Sprawdzaj coverage (`pnpm test:coverage`) przed mergem
- ✅ Uruchamiaj `pnpm lint` przed commitem (lub użyj husky pre-commit hook)

### UX

- ✅ Każde pole tekstowe → przycisk X do czyszczenia
- ✅ Każda ikona interaktywna → tooltip z opisem
- ✅ Każda operacja async → loading state + error state
- ✅ Każda akcja destruktywna → modal potwierdzenia
- ✅ Każda strona → opakowanie w `<ErrorBoundary>`
- ✅ Każde powiadomienie → przez toast (nigdy alert)
- ✅ Wskaźnik offline → widoczny na każdej stronie
- ✅ Biometria (mobile) → dostępna po pierwszym logowaniu

### Bezpieczeństwo

- ✅ Przy nowym urządzeniu → pytaj o zaufane/niezaufane
- ✅ Przy włączaniu trybu 18+ → pełny flow weryfikacji
- ✅ Przy zapisie wrażliwych danych → przez `cryptoService.ts`

---

## 16. Checklist przed PR

Przed stworzeniem Pull Request upewnij się, że:

```
Kod
□ Każdy nowy plik ma nagłówek (File, Path, Exports, Depends on, Purpose)
□ Żadnego `any` w TypeScript
□ Każda async funkcja ma try/catch + captureError
□ Żadnych hardcoded stringów — wszystko przez t()
□ Plik nie przekracza limitu linii
□ Brak cyklicznych importów (pnpm lint nie zgłasza błędów)
□ Brak zakomentowanego kodu

Testy
□ Nowe funkcjonalności mają testy jednostkowe
□ pnpm test przechodzi bez błędów
□ pnpm test:coverage — coverage nie spadło

UX
□ Każde nowe pole tekstowe ma przycisk X
□ Każda nowa ikona interaktywna ma tooltip
□ Loading, success i error state są obsłużone

Bezpieczeństwo
□ Żadnego klucza API w kodzie klienta
□ Żadnego localStorage bezpośrednio

Ogólne
□ pnpm lint przechodzi czysto
□ pnpm build kończy się bez błędów
□ Testowane w trybie offline (DevTools → Network → Offline)
□ Commit message zgodny z Conventional Commits
```
