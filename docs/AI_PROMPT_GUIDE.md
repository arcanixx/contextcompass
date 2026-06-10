# AI_PROMPT_GUIDE.md — ContextCompass

> Instrukcja dla modeli AI (Claude, Gemini, GPT) pracujących nad tym projektem.  
> Przeczytaj ten plik **zanim** wygenerujesz lub edytujesz jakikolwiek kod.

---

## Kontekst projektu

**ContextCompass** to aplikacja do zarządzania kontekstem rozmów z różnymi osobami.  
Składa się z:
- Plugin Chrome/Edge (Manifest V3, TypeScript)
- PWA — React 18 + Vite + TailwindCSS
- Backend — Supabase (Edge Functions w Deno/TypeScript)
- Pakiet `shared` — wspólna logika dla wszystkich platform

Pełna architektura: `docs/DEVELOPMENT_PLAN.md`  
Zasady kodu: `docs/CODING_STANDARDS.md`  
Bezpieczeństwo: `docs/SECURITY.md`

---

## Przed wygenerowaniem kodu — obowiązkowe

1. **Przeczytaj** `CODING_STANDARDS.md` — znasz zasady nagłówków, limitów, importów
2. **Sprawdź** czy zadanie nie nakłada się na istniejący plik (zapytaj o strukturę)
3. **Określ** do którego pakietu należy kod: `shared`, `web`, `extension`, `mobile`
4. **Zaplanuj** jak podzielić kod jeśli byłby > 150 linii

---

## Obowiązkowe elementy każdego wygenerowanego pliku

### 1. Nagłówek (zawsze pierwszy)

```typescript
/*
 * File:       nazwaPliku.ts
 * Path:       packages/web/src/hooks/nazwaPliku.ts
 * Exports:    exportedFn1, ExportedType
 * Depends on: react, shared/services/supabaseClient, ../types/contact
 * Purpose:    Jeden zdanie opisujące funkcję pliku
 */
```

### 2. Try/catch w każdej async funkcji

```typescript
// ✅ Wzorzec obowiązkowy
async function fetchSomething(id: string): Promise<Result | null> {
  try {
    const data = await someAsyncOperation(id);
    return data;
  } catch (err) {
    captureError(err instanceof Error ? err : new Error(String(err)), {
      action: 'fetchSomething',
      extra: { id },
    });
    return null;
  }
}
```

### 3. Żadnych hardcoded stringów UI

```typescript
// ✅ Dobrze
const { t } = useTranslation();
toast.error(t('common.error_generic'));

// ❌ Źle
toast.error('Coś poszło nie tak');
```

### 4. Typy TypeScript — strict, no any

```typescript
// ✅ Dobrze
function processContact(contact: Contact): ProcessedContact { ... }

// ❌ Źle
function processContact(contact: any): any { ... }
```

---

## Wzorce UX — obowiązkowe w komponentach

### Pole tekstowe z przyciskiem czyszczenia

```typescript
// Każde <input> i <textarea> musi mieć ten wzorzec
interface ClearableInputProps {
  value: string;
  onChange: (val: string) => void;
  onClear: () => void;
  label: string;
  placeholder?: string;
  helpText?: string;
}

function ClearableInput({ value, onChange, onClear, label, placeholder, helpText }: ClearableInputProps) {
  const { t } = useTranslation();
  return (
    <div className="flex flex-col gap-1">
      <label className="text-sm font-medium text-gray-700 dark:text-gray-300">{label}</label>
      <div className="relative">
        <input
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          className="w-full px-3 py-2 pr-8 border rounded-lg focus:ring-2 focus:ring-primary-500 dark:bg-gray-800"
        />
        {value.length > 0 && (
          <button
            type="button"
            onClick={onClear}
            aria-label={t('common.clear_field')}
            className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
          >
            <XMarkIcon className="w-4 h-4" />
          </button>
        )}
      </div>
      {helpText && <p className="text-xs text-gray-500 dark:text-gray-400">{helpText}</p>}
    </div>
  );
}
```

### Przycisk z loading state

```typescript
interface LoadingButtonProps {
  isLoading: boolean;
  loadingText?: string;
  onClick: () => void;
  children: React.ReactNode;
  variant?: 'primary' | 'danger' | 'secondary';
  disabled?: boolean;
}

function LoadingButton({ isLoading, loadingText, onClick, children, variant = 'primary', disabled }: LoadingButtonProps) {
  const { t } = useTranslation();
  return (
    <button
      onClick={onClick}
      disabled={isLoading || disabled}
      aria-busy={isLoading}
      className={`px-4 py-2 rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed
        ${variant === 'primary' ? 'bg-primary-500 text-white hover:bg-primary-600' : ''}
        ${variant === 'danger' ? 'bg-danger-500 text-white hover:bg-danger-600' : ''}
      `}
    >
      {isLoading ? (
        <span className="flex items-center gap-2">
          <SpinnerIcon className="w-4 h-4 animate-spin" />
          {loadingText ?? t('common.loading')}
        </span>
      ) : children}
    </button>
  );
}
```

### Tooltip (obowiązkowy dla ikon bez tekstu)

```typescript
// Użycie — każda ikona interaktywna musi mieć tooltip
<Tooltip content={t('chat.voice_input.tooltip')}>
  <IconButton
    icon={<MicrophoneIcon className="w-5 h-5" />}
    onClick={startRecording}
    aria-label={t('chat.voice_input.aria')}
  />
</Tooltip>
```

### Toast — wzorzec użycia

```typescript
// Import singletona
import { toast } from 'shared/services/toastService';

// Użycie
toast.success(t('contact.saved'));
toast.error(t('common.error_generic'));
toast.warning(t('hint.fallback_warning', { model: 'Groq' }));
toast.info(t('sync.completed'));
```

### Modal potwierdzenia destruktywnej akcji

```typescript
// Zawsze dla: usuń, wyloguj wszystkie urządzenia, wyczyść historię, usuń konto
<ConfirmDialog
  isOpen={isDeleteModalOpen}
  onClose={() => setIsDeleteModalOpen(false)}
  onConfirm={handleDelete}
  title={t('contact.delete.title')}
  description={t('contact.delete.confirm', { name: contact.name })}
  confirmLabel={t('common.delete')}
  confirmVariant="danger"
/>
```

---

## Wzorce serwisów (shared)

### Serwis z fallback i error handling

```typescript
/*
 * File:       aiService.ts
 * Path:       packages/shared/src/services/aiService.ts
 * Exports:    getAIHint, analyzeConversation, getCurrentModel
 * Depends on: ./supabaseClient, ./logger, ../constants, ../types/ai
 * Purpose:    Abstrakcja nad AI API z automatycznym fallback chain
 */

import { captureError } from './logger';
import { supabase } from './supabaseClient';
import { IS_DEV } from '../constants';
import type { AIHint, AIModel, ConversationAnalysis } from '../types/ai';

// W trybie DEV zwraca mockowe odpowiedzi
const DEV_HINT_MOCK: AIHint[] = [
  { text: 'Przykładowa podpowiedź 1 (mock)', tone: 'casual', why: 'Mock response' },
  { text: 'Przykładowa podpowiedź 2 (mock)', tone: 'formal', why: 'Mock response' },
];

export async function getAIHint(params: {
  contactId: string;
  inputText: string;
  userId: string;
}): Promise<AIHint[]> {
  if (IS_DEV) return DEV_HINT_MOCK;

  try {
    const { data, error } = await supabase.functions.invoke('ai-proxy', {
      body: { ...params, mode: 'hint' },
    });
    if (error) throw error;
    return data.hints as AIHint[];
  } catch (err) {
    captureError(err instanceof Error ? err : new Error(String(err)), {
      action: 'getAIHint',
      extra: { contactId: params.contactId },
    });
    return [];
  }
}
```

---

## Zasady dla Edge Functions (Supabase/Deno)

```typescript
// Wzorzec Edge Function
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req: Request) => {
  // CORS headers
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  try {
    // Weryfikacja autoryzacji
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return new Response('Unauthorized', { status: 401 });

    // Logika funkcji
    const body = await req.json();
    // ...

    return new Response(JSON.stringify({ success: true, data: result }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('[EdgeFunction Error]', err);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
```

---

## Kiedy pytać, a kiedy działać

### Pytaj zawsze gdy

- Nie masz pewności, do którego pakietu (`shared`, `web`, `extension`) należy kod
- Zadanie wymaga zmiany schematu bazy danych
- Masz wątpliwości co do decyzji architektonicznych z `DEVELOPMENT_PLAN.md`
- Funkcja wymagałaby pliku > 150 linii — zaproponuj podział i zapytaj o akceptację

### Działaj bez pytania gdy

- Tworzysz nowy komponent UI według wzorców z tego dokumentu
- Dodajesz testy do istniejącego kodu
- Uzupełniasz klucze i18n w plikach lokalizacyjnych
- Dodajesz nagłówki do istniejących plików
- Naprawiasz błąd TypeScript (strict violations, unused vars)

---

## Najczęstsze błędy AI — czego unikać

| Błąd | Prawidłowe podejście |
|---|---|
| Generowanie pliku > 200 linii | Podziel na moduły, każdy < 150 linii |
| `import * as X from 'react'` | `import { useState, useEffect } from 'react'` |
| `export * from './module'` | Konkretne named exports |
| `any` zamiast typów | Zdefiniuj interface lub użyj `unknown` z type guard |
| Hardcoded `"Zapisz"` w JSX | `{t('common.save')}` |
| `window.alert()` | `<ConfirmDialog>` lub `toast.error()` |
| `localStorage.setItem()` bezpośrednio | `localStore.set()` z pakietu shared |
| Brak `try/catch` w async | Zawsze `try/catch` + `captureError()` |
| Input bez przycisku X | Użyj `<ClearableInput>` |
| Ikona bez tooltipa | Opakuj w `<Tooltip>` |
| Brak ErrorBoundary na stronie | Opakuj `<ErrorBoundary>` |
| Brak nagłówka pliku | Zawsze nagłówek jako pierwsza rzecz |

---

## Środowisko i komendy

```bash
# Uruchomienie dev
pnpm dev:web          # PWA na localhost:5173
pnpm dev:extension    # Build watch dla pluginu

# Testy
pnpm test             # Vitest (unit)
pnpm test:coverage    # Z raportem coverage
pnpm test:e2e         # Playwright (wymaga działającego dev:web)

# Sprawdzenia kodu
pnpm lint             # ESLint + TypeScript
pnpm format           # Prettier

# Skrypty pomocnicze
./scripts/check_headers.sh      # Sprawdź nagłówki plików
./scripts/check_file_lengths.sh # Sprawdź rozmiary plików

# Supabase
npx supabase start    # Lokalna instancja Supabase
npx supabase db push  # Zastosuj migracje
npx supabase functions serve --env-file .env.local  # Edge Functions lokalnie
```
