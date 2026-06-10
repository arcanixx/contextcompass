<!-- =============================================================================
 FILE: 01b_ARCHITECTURE_SUPPLEMENT.md
 PATH: docs/01b_ARCHITECTURE_SUPPLEMENT.md
 VERSION: 0.1.0
 PURPOSE: Uzupełnienie architektury o sortowanie, przypomnienia, modały aplikacyjne, logi in-app i raportowanie błędów.
 FUNCTIONS: -
 DEPENDS ON: docs/01_ARCHITECTURE.md
 UWAGA: Ten plik rozszerza 01_ARCHITECTURE.md. Oba traktować łącznie.
 ============================================================================= -->

# 01b — Architektura: Uzupełnienia

---

## 1. Sortowanie i filtrowanie

Sortowanie i filtry są przechowywane per-widok w kluczu `ui_prefs` wewnątrz `profiles.settings` JSONB.
Dzięki temu preferencje przeżywają restart aplikacji i synchronizują się między urządzeniami.

### 1.1. Schema preferencji sortowania

```typescript
// src/types/auth.types.ts (rozszerzenie)
interface UiPreferences {
  channelListSort: 'alphabetical' | 'last_activity' | 'unread_first';
  memberListSort: 'alphabetical' | 'online_first' | 'role_first';
  classListSort: 'last_activity' | 'alphabetical';
  noteListSort: 'updated_desc' | 'alphabetical' | 'subject';
  dmListSort: 'last_message' | 'unread_first';
  channelListFilter: 'all' | 'unread';
}
```

### 1.2. Opcje sortowania per widok

| Widok | Domyślne | Opcje dostępne |
|-------|----------|----------------|
| Lista klas (Home) | Ostatnia aktywność ↓ | Alfabetycznie, ostatnia aktywność |
| Lista kanałów (Sidebar) | Alfabetycznie | Alfabetycznie, ostatnia aktywność, nieodczytane na górze |
| Lista członków | Alfabetycznie | Alfabetycznie, online first, admini na górze |
| Lista notatek | Data edycji ↓ | Data edycji, alfabetycznie, według przedmiotu |
| Lista DM | Ostatnia wiadomość ↓ | Ostatnia wiadomość, nieodczytane na górze |
| Kolejka moderacji | Data wpłynięcia ↓ | Data wpłynięcia, pewność AI ↓ |

### 1.3. Implementacja — hook sortowania

```typescript
// src/hooks/useSortedList.ts
/**
 * @file useSortedList.ts
 * @path src/hooks/useSortedList.ts
 * @description Generyczny hook do sortowania list z persystencją preferencji użytkownika.
 * @exports useSortedList
 * @dependsOn src/store/uiStore.ts, src/lib/supabase/queries/profiles.ts
 */

import { useMemo, useCallback } from 'react';
import { useUiStore } from '@/store/uiStore';

type SortKey = keyof UiPreferences;

export const useSortedList = <T>(
  items: T[],
  sortKey: SortKey,
  comparators: Record<string, (a: T, b: T) => number>,
) => {
  const { uiPrefs, setUiPref } = useUiStore();
  const currentSort = uiPrefs[sortKey];

  const sorted = useMemo(() => {
    const comparator = comparators[currentSort];
    if (!comparator) return items;
    return [...items].sort(comparator);
  }, [items, currentSort]);

  const setSort = useCallback((value: string) => {
    setUiPref(sortKey, value);
  }, [sortKey]);

  return { sorted, currentSort, setSort };
};
```

---

## 2. Przypomnienia (Reminders)

### 2.1. Schema tabeli

```sql
-- supabase/migrations/0005_reminders.sql
CREATE TABLE reminders (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id      uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  class_id      uuid REFERENCES classes(id) ON DELETE CASCADE,
  channel_id    uuid REFERENCES channels(id) ON DELETE SET NULL,
  thread_id     uuid REFERENCES threads(id) ON DELETE SET NULL,
  title         text NOT NULL CHECK (char_length(title) BETWEEN 1 AND 200),
  note          text,
  remind_at     timestamptz NOT NULL,
  is_sent       boolean NOT NULL DEFAULT false,
  is_dismissed  boolean NOT NULL DEFAULT false,
  repeat_type   text DEFAULT 'none'
    CHECK (repeat_type IN ('none', 'daily', 'weekly')),
  created_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reminders_owner_only" ON reminders FOR ALL
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

CREATE INDEX idx_reminders_remind_at ON reminders(remind_at)
  WHERE is_sent = false AND is_dismissed = false;
```

### 2.2. Typy przypomnień

| Typ | Opis | Przykład |
|-----|------|---------|
| Globalne | Nie powiązane z żadną klasą | "Jutro sprawdzian" |
| Klasowe | Powiązane z klasą | "Zebranie klasy 3B o 17:00" |
| Kanałowe | Powiązane z przedmiotem | "Praca domowa z matematyki — kanał #matematyka" |
| Wątkowe | Powiązane z wątkiem | "Odpowiedz na wątek o zadaniu nr 5" |

### 2.3. Flow powiadomień

```
CRON Edge Function (co 1 minuta):
    │
    ├── SELECT * FROM reminders
    │   WHERE remind_at <= now()
    │   AND is_sent = false
    │   AND is_dismissed = false
    │
    ├── Dla każdego reminderu:
    │   ├── Sprawdź czy kanał/klasa nie jest wyciszona
    │   ├── Wyślij push notification przez Expo Push API
    │   └── UPDATE reminders SET is_sent = true WHERE id = ...
    │
    └── Log: ile wysłano, ile pominięto (wyciszone)
```

### 2.4. UI — tworzenie przypomnienia

Dostępne z trzech miejsc:
- Długie naciśnięcie wiadomości → "Przypomnij o tym"
- Przycisk + w widoku notatek → "Dodaj przypomnienie"
- Ustawienia → Przypomnienia → Nowe

Modal tworzenia przypomnienia:
```
┌─────────────────────────────────────────────┐
│  🔔 Nowe przypomnienie                      │
│                                             │
│  Tytuł: [________________________]          │
│  Notatka: [_____________________]           │
│                                             │
│  Data i godzina:                            │
│  [📅 Wybierz datę]  [🕐 Wybierz godzinę]  │
│                                             │
│  Powiązanie (opcjonalne):                   │
│  [Klasa ▾] [Przedmiot ▾]                   │
│                                             │
│  Powtarzaj: [Nie ▾]                        │
│                                             │
│  [Anuluj]              [Zapisz]            │
└─────────────────────────────────────────────┘
```

---

## 3. Modały aplikacyjne — zero window.* alertów

### 3.1. Zasada nadrzędna

**Bezwzględny zakaz:** `window.alert()`, `window.confirm()`, `window.prompt()`, `Alert.alert()` (React Native).

Każda interakcja wymagająca potwierdzenia lub informacji używa `src/components/ui/Modal.tsx`.

### 3.2. Typy modali

```typescript
// src/components/ui/Modal.tsx

type ModalVariant =
  | 'info'          // Informacja, jedno OK
  | 'confirm'       // Potwierdź / Anuluj (akcja neutralna)
  | 'destructive'   // Usuń / Anuluj (akcja czerwona, nieodwracalna)
  | 'input'         // Formularz wewnątrz modala
  | 'custom';       // Dowolna treść

interface ModalProps {
  variant: ModalVariant;
  title: string;
  message?: string;
  confirmLabel?: string;   // default: t('common.confirm')
  cancelLabel?: string;    // default: t('common.cancel')
  onConfirm: () => void;
  onCancel?: () => void;
  isLoading?: boolean;     // pokazuje spinner na przycisku
  children?: React.ReactNode; // dla 'custom' i 'input'
}
```

### 3.3. Obowiązkowe modały potwierdzenia (destructive)

Każda z poniższych akcji MUSI mieć modal `variant="destructive"` zanim wykona operację:

| Akcja | Treść modala |
|-------|-------------|
| Usunięcie wiadomości | "Usuń tę wiadomość? Tej operacji nie można cofnąć." |
| Usunięcie konta | "Czy na pewno chcesz usunąć konto? Wszystkie Twoje dane zostaną trwale usunięte." |
| Opuszczenie klasy | "Opuścić klasę [nazwa]? Aby dołączyć ponownie, będziesz potrzebować kodu zaproszenia." |
| Zbanowanie ucznia | "Zbanować Jana Kowalskiego? Nie będzie mógł ponownie dołączyć bez Twojej zgody." |
| Archiwizacja klasy | "Zarchiwizować klasę [nazwa]? Uczniowie nie będą mogli wysyłać nowych wiadomości." |
| Odwołanie zaufanego urządzenia | "Usunąć urządzenie [nazwa]? Zostaniesz wylogowany na tym urządzeniu." |
| Odrzucenie wiadomości w moderacji | "Odrzucić wiadomość? Nadawca otrzyma powiadomienie o naruszeniu zasad." |
| Wyczyszczenie logów | "Wyczyścić wszystkie logi? Tej operacji nie można cofnąć." |

### 3.4. Globalny ModalProvider

```typescript
// src/contexts/ModalContext.tsx
// Używany przez cały app — nie tworzyć modali lokalnie w komponentach

interface ModalContextValue {
  showModal: (config: ModalConfig) => Promise<boolean>;
  // Promise<true> = potwierdzone, Promise<false> = anulowane
}

// Użycie:
const { showModal } = useModal();

const handleDelete = async () => {
  const confirmed = await showModal({
    variant: 'destructive',
    title: t('message.delete.title'),
    message: t('message.delete.message'),
    confirmLabel: t('common.delete'),
  });
  if (!confirmed) return;
  // wykonaj akcję
};
```

---

## 4. Logowanie błędów — rozszerzony model

### 4.1. Poziomy logów i ich znaczenie

| Poziom | Kiedy używać | Widoczność |
|--------|-------------|-----------|
| `logger.debug()` | Szczegóły działania w DEV mode | Tylko konsola DEV, strippowany w produkcji |
| `logger.info()` | Kluczowe akcje użytkownika bez PII | DEV konsola + Sentry breadcrumb |
| `logger.warn()` | Fallback użyty, coś niepełnego | DEV konsola + Sentry warning + in-app log |
| `logger.error()` | Błąd operacji, wyjątek złapany | DEV konsola + Sentry error + in-app log + Supabase |
| `logger.critical()` | Błąd aplikacji uniemożliwiający działanie | Jak error + natychmiastowy flush do Supabase |

### 4.2. In-app logi (Settings → Logi aplikacji)

Logi `warn` i `error` są zapisywane lokalnie w `SecureStore` (maks. 100 wpisów, rotacja FIFO):

```typescript
// src/lib/errors/inAppLog.ts
interface InAppLogEntry {
  id: string;
  level: 'warn' | 'error' | 'critical';
  message: string;
  code?: string;           // ErrorCode z AppError
  timestamp: string;       // ISO 8601
  context?: string;        // JSON string — BEZ PII, tylko kody i ID
}

// Wyświetlane w Settings → Logi aplikacji:
// [2026-06-10 14:32] ⚠️ warn — OCR fallback użyty (Tesseract niedostępny)
// [2026-06-10 14:30] ❌ error — UPLOAD_TOO_LARGE — plik: 6.2 MB
// [2026-06-10 13:55] ❌ error — AUTH_SESSION_EXPIRED — deviceId: abc123
```

### 4.3. Raportowanie błędów do autora — Supabase endpoint

Tabela `error_reports` dostępna wyłącznie przez service role (tylko Edge Function pisze):

```sql
-- supabase/migrations/0006_error_reports.sql
CREATE TABLE error_reports (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  app_version   text NOT NULL,
  platform      text NOT NULL,          -- 'ios' | 'android' | 'web'
  error_code    text NOT NULL,
  error_message text NOT NULL,
  stack_trace   text,
  context       jsonb,                  -- BEZ PII: tylko kody, stany, flagi
  user_hash     text,                   -- SHA-256(user_id) — nie da się odwrócić
  session_actions jsonb,                -- ostatnie 10 akcji użytkownika (breadcrumbs)
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- Tylko Edge Function może pisać (service role)
-- Brak RLS SELECT dla użytkowników (dane tylko dla autora)
ALTER TABLE error_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "no_user_access" ON error_reports FOR ALL USING (false);
```

Edge Function `report-error`:
```typescript
// supabase/functions/report-error/index.ts
// Wywoływana przez logger.error() i logger.critical() w aplikacji
// Zbiera: error_code, platform, app_version, ostatnie 10 breadcrumbs (bez treści wiadomości)
// Haszuje user_id przez SHA-256 (RODO: nie przechowuje ID użytkownika)
```

### 4.4. Przycisk "Wyślij raport błędu" w Settings

```
Settings → Logi aplikacji → [Wyślij raport do autora]
    │
    ├── Modal info: "Raport zawiera kody błędów i informacje techniczne.
    │   Nie zawiera Twoich wiadomości ani danych osobowych.
    │   [Anuluj] [Wyślij]"
    │
    ├── Po potwierdzeniu: wywołaj Edge Function report-error
    │   z zawartością in-app logów (ostatnie 50 wpisów)
    │
    └── Toast: "Raport wysłany. Dziękujemy za pomoc w ulepszaniu aplikacji."
```

### 4.5. Debug mode — krok po kroku

W trybie `DEBUG_MODE=true` każda operacja loguje swój przebieg:

```
[DEBUG] useMessages.sendMessage() — START
[DEBUG] moderateMessage() — wywołanie Edge Function
[DEBUG] moderateMessage() — odpowiedź: { decision: 'approve' } (124ms)
[DEBUG] supabase.messages.insert() — START
[DEBUG] supabase.messages.insert() — SUCCESS — id: abc-123 (45ms)
[DEBUG] Realtime broadcast — channel: xyz-456
[DEBUG] useMessages.sendMessage() — END — total: 169ms
```

W trybie produkcyjnym — tylko `warn` i `error` do Sentry + Supabase. Brak `debug` i `info`.

---

## 5. Rozszerzone schema DB — brakujące tabele

### Tabela: `reminders` (patrz sekcja 2.1 powyżej)

### Tabela: `error_reports` (patrz sekcja 4.3 powyżej)

### Tabela: `user_sort_preferences` — alternatywa do JSONB

Zamiast przechowywać sortowanie w `profiles.settings` JSONB, można użyć osobnej tabeli (łatwiej indeksować):

```sql
-- Opcja alternatywna — do decyzji przed implementacją
CREATE TABLE user_ui_preferences (
  profile_id        uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  channel_list_sort text DEFAULT 'alphabetical',
  member_list_sort  text DEFAULT 'alphabetical',
  class_list_sort   text DEFAULT 'last_activity',
  note_list_sort    text DEFAULT 'updated_desc',
  dm_list_sort      text DEFAULT 'last_message',
  updated_at        timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE user_ui_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_prefs" ON user_ui_preferences FOR ALL
USING (profile_id = auth.uid())
WITH CHECK (profile_id = auth.uid());
```

**Decyzja:** Użyć JSONB w `profiles.settings` dla MVP (mniejsza złożoność). Przenieść do osobnej tabeli jeśli preferencji będzie > 20.
