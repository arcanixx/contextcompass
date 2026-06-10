<!-- =============================================================================
 FILE: CODE_REVIEW_CHECKLIST.md
 PATH: docs/CODE_REVIEW_CHECKLIST.md
 VERSION: 0.1.0
 PURPOSE: Kompletna lista kontrolna Code Review dla ContextCompass – weryfikacja kodu przed każdym mergem do develop/main.
 FUNCTIONS: -
 DEPENDS ON: DEVELOPMENT_PLAN.md, CODING_STANDARDS.md, SECURITY.md, AI_PROMPT_GUIDE.md
 UWAGA: Nie usuwać komentarzy – opisują flow aplikacji. [AUTO] = można sprawdzić skryptem/grep, [MANUAL] = wymaga ręcznej inspekcji.
 ============================================================================= -->

# 📋 CODE REVIEW CHECKLIST — ContextCompass

> **Użycie:** Przed każdym Pull Requestem do `develop` lub `main` przejdź przez poniższe punkty.
> **Dla AI:** Punkty `[AUTO]` mogą być zweryfikowane skryptem lub grepem. `[MANUAL]` wymaga ręcznej inspekcji kodu lub działania aplikacji.
> **Wyniki:** Zapisz wypełnioną checklistę do `logs/code-review-YYYY-MM-DD.md` (patrz sekcja końcowa).

---

## 1. NAGŁÓWKI PLIKÓW I DOKUMENTACJA

### 1.1. Nagłówki

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 1.1.1 | Każdy plik `.ts`/`.tsx`/`.js` zaczyna się od bloku `/* File: ... */` | [AUTO] | `./scripts/check_headers.sh` — zwraca listę plików bez nagłówka |
| 1.1.2 | Pole `File` zawiera samą nazwę pliku (bez ścieżki) | [AUTO] | `grep -r "^ \* File:" packages/ | grep "/"` — powinno zwrócić 0 |
| 1.1.3 | Pole `Path` zawiera ścieżkę od roota repozytorium | [MANUAL] | Sprawdź losowe 5 plików ręcznie |
| 1.1.4 | Pole `Exports` zawiera wszystkie eksportowane symbole z pliku | [AUTO] | `grep -r "^ \* Exports:" packages/ | grep "(none)"` — pliki bez eksportów powinny być only utils/types |
| 1.1.5 | Pole `Depends on` wymienia rzeczywiste importy (nie puste) | [MANUAL] | Sprawdź czy nagłówek zgadza się z `import` na dole pliku |
| 1.1.6 | Pole `Purpose` nie jest puste ani generyczne (`TODO — opisz...`) | [AUTO] | `grep -r "TODO — opisz" packages/` — powinno zwrócić 0 przed mergem |

### 1.2. JSDoc i komentarze

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 1.2.1 | Każda publiczna funkcja (eksportowana) ma komentarz JSDoc `/** */` | [MANUAL] | Dotyczy `packages/shared/src/services/` i `packages/shared/src/utils/` |
| 1.2.2 | Brak zakomentowanego kodu (bloki `// kod...`) bez wyjaśnienia | [AUTO] | `grep -rn "^[[:space:]]*\/\/[[:space:]]*[a-zA-Z]\+(" packages/` — ręczna weryfikacja wyników |
| 1.2.3 | Każde `// TODO` ma autora i datę (`// TODO(@name): opis — YYYY-MM-DD`) | [AUTO] | `grep -rn "TODO" packages/ | grep -v "@"` — powinno zwrócić 0 |
| 1.2.4 | Brak `// FIXME` w kodzie do merge'owania | [AUTO] | `grep -rn "FIXME" packages/` — powinno zwrócić 0 |

---

## 2. STRUKTURA PLIKÓW I ARCHITEKTURA MONOREPO

### 2.1. Pakiety i ich przeznaczenie

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 2.1.1 | `packages/shared/` nie importuje niczego z `packages/web/`, `packages/extension/`, `packages/mobile/` | [AUTO] | `grep -r "from.*packages/web\|from.*packages/extension" packages/shared/` — powinno zwrócić 0 |
| 2.1.2 | `packages/web/` nie importuje bezpośrednio z `packages/extension/` | [AUTO] | `grep -r "from.*packages/extension" packages/web/` — powinno zwrócić 0 |
| 2.1.3 | `packages/shared/src/services/` — tylko logika (brak JSX, brak React hooks) | [AUTO] | `grep -r "useState\|useEffect\|JSX\|React" packages/shared/src/services/` — powinno zwrócić 0 |
| 2.1.4 | `packages/shared/src/types/` — tylko definicje typów (brak funkcji, brak logiki) | [AUTO] | `grep -r "^export function\|^export const.*=.*(" packages/shared/src/types/` — powinno zwrócić 0 |
| 2.1.5 | `packages/shared/src/mocks/` — tylko pliki mock, używane wyłącznie w dev/tests | [MANUAL] | Sprawdź czy mocki nie są importowane w kodzie produkcyjnym poza blokami `IS_DEV` |
| 2.1.6 | `supabase/functions/` — każda Edge Function to osobny folder z `index.ts` | [MANUAL] | `ls supabase/functions/` — brak plików `.ts` w root (tylko podfoldery) |

### 2.2. Rozmiary plików

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 2.2.1 | Żaden komponent React (`components/`) nie przekracza 150 linii | [AUTO] | `./scripts/check_file_lengths.sh` — sekcja `komponenty` |
| 2.2.2 | Żaden hook (`hooks/`) nie przekracza 100 linii | [AUTO] | `./scripts/check_file_lengths.sh` — sekcja `hooki` |
| 2.2.3 | Żaden serwis (`services/`) nie przekracza 150 linii | [AUTO] | `./scripts/check_file_lengths.sh` — sekcja `serwisy` |
| 2.2.4 | Żadna strona (`pages/`) nie przekracza 120 linii (logika w hookach) | [AUTO] | `./scripts/check_file_lengths.sh` — sekcja `strony` |
| 2.2.5 | Żadna Edge Function nie przekracza 150 linii | [AUTO] | `./scripts/check_file_lengths.sh` — sekcja `edge functions` |

### 2.3. Cykliczne zależności

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 2.3.1 | Brak cyklicznych importów w `packages/shared/src/services/` | [AUTO] | `npx madge --circular packages/shared/src/services/` — powinno zwrócić 0 |
| 2.3.2 | Brak cyklicznych importów w `packages/web/src/hooks/` | [AUTO] | `npx madge --circular packages/web/src/hooks/` — powinno zwrócić 0 |
| 2.3.3 | Brak cyklicznych importów między serwisami a hookami | [AUTO] | `npx madge --circular packages/` — wyniki zapisz w PR |

---

## 3. IMPORTY I EKSPORTY

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 3.1 | Importy konkretne (`import { fn }`) — brak `import * as X` | [AUTO] | `grep -rn "import \* as" packages/` — powinno zwrócić 0 (poza generowanymi plikami) |
| 3.2 | Brak barrel re-exportów `export * from` (poza `types/index.ts`) | [AUTO] | `grep -rn "export \* from" packages/` — tylko pliki typów są dopuszczalne |
| 3.3 | Brak nieużywanych importów (`import { X }` bez użycia `X`) | [AUTO] | `pnpm lint` — ESLint `no-unused-vars` zgłosi |
| 3.4 | Kolejność importów: zewnętrzne → shared → lokalne → typy | [MANUAL] | Sprawdź 3 losowe komponenty React |
| 3.5 | Brak importów `any` w deklaracjach typów | [AUTO] | `grep -rn ": any\|as any\|<any>" packages/` — każdy wynik wymaga uzasadnienia w PR |

---

## 4. TYPESCRIPT — JAKOŚĆ TYPÓW

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 4.1 | `pnpm tsc --noEmit` kończy się bez błędów | [AUTO] | Uruchomić w rocie projektu — 0 errorów |
| 4.2 | Brak `any` (użyj `unknown` z type guard lub konkretnego typu) | [AUTO] | `grep -rn ": any\b" packages/ --include="*.ts" --include="*.tsx"` — każdy wynik wymaga komentarza |
| 4.3 | Każda funkcja async ma zadeklarowany typ zwracanej wartości `Promise<T>` | [MANUAL] | Sprawdź `packages/shared/src/services/` — wszystkie exportowane async functions |
| 4.4 | Type guardy (`value is T`) dla walidacji danych z API/Supabase | [MANUAL] | Sprawdź `packages/shared/src/validators.ts` — czy jest `isContact`, `isProfile` etc. |
| 4.5 | Interfejsy zamiast `type` dla obiektów domenowych (Contact, Profile, Message) | [MANUAL] | Sprawdź `packages/shared/src/types/` — preferuj `interface` dla extendowalności |
| 4.6 | `exactOptionalPropertyTypes` — opcjonalne pola oznaczone `?`, nie `| undefined` | [AUTO] | `pnpm tsc` z `strict: true` — wykryje automatycznie |

---

## 5. OBSŁUGA BŁĘDÓW

### 5.1. Try/catch i captureError

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 5.1.1 | Każda funkcja `async` w `packages/shared/src/services/` ma `try/catch` | [AUTO] | `grep -rn "async function\|async (" packages/shared/src/services/ | wc -l` vs `grep -rn "try {" packages/shared/src/services/ | wc -l` — liczby powinny być zbliżone |
| 5.1.2 | Każdy blok `catch` wywołuje `captureError(err, { action: '...' })` | [AUTO] | `grep -rn "catch" packages/ | grep -v "captureError"` — każdy wynik to potencjalny problem |
| 5.1.3 | `captureError` dostaje `instanceof Error ? err : new Error(String(err))` — brak rzucania typem `unknown` | [AUTO] | `grep -rn "captureError(err," packages/` — sprawdź czy nikt nie przekazuje raw `err` bez castowania |
| 5.1.4 | Każdy `useEffect` w komponentach React z `invoke()` ma `try/catch` | [MANUAL] | Sprawdź `packages/web/src/components/` i `packages/web/src/pages/` |
| 5.1.5 | W bloku `catch` — brak pustego `catch {}` bez logowania | [AUTO] | `grep -rn "} catch" packages/ -A 1 | grep "^[[:space:]]*}"` — puste catche |

### 5.2. Edge Functions — Supabase

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 5.2.1 | Każda Edge Function ma `try/catch` na poziomie głównego handlera | [MANUAL] | Sprawdź `supabase/functions/*/index.ts` |
| 5.2.2 | Edge Function zwraca `Response` z odpowiednim statusem HTTP (nie rzuca wyjątku) | [MANUAL] | Wzorzec: `return new Response(JSON.stringify({ error }), { status: 500 })` |
| 5.2.3 | Edge Function obsługuje metody CORS preflight (`OPTIONS`) | [AUTO] | `grep -rn "OPTIONS" supabase/functions/` — powinno być w każdym `index.ts` |
| 5.2.4 | Weryfikacja `Authorization` header przed przetworzeniem logiki | [MANUAL] | Sprawdź czy `ai-proxy` i `analyze-conversation` wymagają tokenu |

### 5.3. Fallbacki AI

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 5.3.1 | `aiService.ts` obsługuje błąd 429 (rate limit) i przełącza na następny model w chain | [MANUAL] | Sprawdź logikę w `packages/shared/src/services/aiService.ts` |
| 5.3.2 | Fallback do szablonu offline gdy wszystkie modele zawiodą — zwraca `TemplateFallback[]`, nie rzuca | [MANUAL] | Sprawdź ostatni element `fallbackChain` w Edge Function `ai-proxy` |
| 5.3.3 | Toast informujący użytkownika o fallbacku jest wywoływany w komponencie (nie w serwisie) | [MANUAL] | Serwis zwraca `{ data, usedModel, isFallback }` — komponent decyduje o toaście |

---

## 6. INTERNACJONALIZACJA (i18n)

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 6.1 | Brak hardcoded stringów w JSX/TSX (żadnych polskich ani angielskich tekstów bezpośrednio) | [AUTO] | `grep -rn '"[A-ZŁÓĄŚĘ][a-ząóśćłź ]\{3,\}"' packages/web/src/` — każdy wynik to błąd |
| 6.2 | Każde wywołanie `t()` ma istniejący klucz w `config/locales/pl.json` | [AUTO] | Uruchomić `pnpm i18n:check` (jeśli skonfigurowane) lub ręcznie sprawdzić nowe klucze |
| 6.3 | `config/locales/pl.json` i `config/locales/en.json` mają identyczne klucze (żaden klucz nie jest tylko w jednym pliku) | [AUTO] | `node scripts/check_locales.js` — skrypt porównuje klucze |
| 6.4 | Nowe sekcje kluczy dodane do obu plików jednocześnie (nie tylko PL) | [MANUAL] | Sprawdź diff pliku `en.json` — jeśli nowe klucze tylko w PL, to błąd |
| 6.5 | Interpolacja zmiennych używa poprawnego formatu `{{variableName}}` | [AUTO] | `grep -rn "t('" packages/web/src/ | grep "{[^{]"` — sprawdź czy nie ma `{variable}` bez `{{` |
| 6.6 | Brak `window.alert()`, `window.confirm()`, `window.prompt()` | [AUTO] | `grep -rn "window\.alert\|window\.confirm\|window\.prompt" packages/web/src/` — powinno zwrócić 0 |
| 6.7 | Komunikaty błędów w `toast.error()` zawsze przekazują klucz przez `t()`, nie string | [MANUAL] | Sprawdź `catch` bloki w komponentach — `toast.error(t('errors.generic'))`, nie `toast.error('Błąd')` |

---

## 7. UX — WZORCE OBOWIĄZKOWE

### 7.1. Pola tekstowe

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 7.1.1 | Każdy `<input type="text">` i `<textarea>` używa komponentu `<ClearableInput>` (lub ma X do czyszczenia) | [MANUAL] | Sprawdź nowe formularze — szukaj `<input` bez `ClearableInput` |
| 7.1.2 | Przycisk X pojawia się **tylko gdy** `value.length > 0` (nie na pustym polu) | [MANUAL] | Sprawdź kondycję `{value.length > 0 && <button...>}` |
| 7.1.3 | Każde pole ma `label` (nie tylko `placeholder`) — dostępność (a11y) | [MANUAL] | Sprawdź czy nowe formularze mają `<label htmlFor="...">` |
| 7.1.4 | Pola z `helpText` wyświetlają go pod polem (szary tekst, rozmiar `text-xs`) | [MANUAL] | Sprawdź nowe komponenty formularzy |

### 7.2. Stany ładowania

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 7.2.1 | Przyciski wywołujące akcję async używają `<LoadingButton>` z `isLoading` | [MANUAL] | Sprawdź nowe przyciski w `pages/` i `components/` — czy nie ma zwykłego `<button onClick={asyncFn}>` |
| 7.2.2 | Listy i karty ładowane z Supabase pokazują skeleton (nie spinner globalny) | [MANUAL] | Sprawdź `ContactList`, `Dashboard` — skeleton powinien mieć zarys kart |
| 7.2.3 | Pełnoekranowy spinner tylko dla: inicjalizacji aplikacji, nawigacji między stronami | [MANUAL] | Sprawdź czy nie pojawia się przy ładowaniu pojedynczych elementów |
| 7.2.4 | Minimalne opóźnienie loaderów 200ms (brak flashowania loaderów przy szybkich responsach) | [MANUAL] | Sprawdź `packages/web/src/hooks/useDelayedLoading.ts` (jeśli istnieje) |

### 7.3. Toasty i powiadomienia

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 7.3.1 | Używamy `toast.*` z `shared/services/toastService` — brak bezpośrednich `alert()` | [AUTO] | `grep -rn "window\.alert" packages/` — powinno zwrócić 0 |
| 7.3.2 | Typy toastów: `success` (zapis), `error` (błąd), `warning` (limit, fallback), `info` (zmiana modelu AI) | [MANUAL] | Sprawdź nowe wywołania `toast.*` czy mają odpowiedni typ |
| 7.3.3 | Toast `error` ma czas wyświetlania 8s (nie domyślne 3s) — użytkownik musi zdążyć przeczytać | [MANUAL] | Sprawdź czy `toast.error` nie nadpisuje domyślnego duration |

### 7.4. Modale i dialogi

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 7.4.1 | Akcje destruktywne (usuń kontakt, usuń konto, wyloguj wszędzie) używają `<ConfirmDialog>` | [MANUAL] | Sprawdź `contacts/ContactCard.tsx`, `settings/account` — czy mają `ConfirmDialog` |
| 7.4.2 | `<ConfirmDialog>` dla usunięcia konta wymaga wpisania słowa potwierdzającego (np. "USUŃ") | [MANUAL] | Sprawdź `settings/AccountSettings.tsx` |
| 7.4.3 | Modale zamykają się przez: kliknięcie tła, przycisk X, klawisz `Escape` | [MANUAL] | Ręczne testy UI — sprawdź 3 modale |
| 7.4.4 | Focus trap wewnątrz modalu (tab nie wychodzi poza modal) | [MANUAL] | Sprawdź czy używamy `@radix-ui/react-dialog` lub `focus-trap-react` |

### 7.5. Tooltips i dostępność

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 7.5.1 | Każda ikona bez etykiety tekstowej ma `<Tooltip>` i `aria-label` | [MANUAL] | Sprawdź `IconButton` — czy każde użycie ma `aria-label` |
| 7.5.2 | `<Tooltip>` na elementach interaktywnych (nie statycznych) — nie dodajemy tooltipów na tekstach | [MANUAL] | Sprawdź nowe ikony w `chat/`, `contacts/`, `settings/` |
| 7.5.3 | Fokus widoczny na interaktywnych elementach (`focus:ring-2 focus:ring-primary-500`) | [AUTO] | `grep -rn "focus:ring" packages/web/src/components/common/Button.tsx` — powinno być |

### 7.6. Wskaźnik offline

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 7.6.1 | `<NetworkBanner>` renderuje się na każdej stronie gdy `!isOnline` | [MANUAL] | Sprawdź `packages/web/src/App.tsx` lub główny layout |
| 7.6.2 | `useNetworkStatus` hook jest używany do blokowania akcji AI gdy offline | [MANUAL] | Sprawdź `HintPanel.tsx` i `AnalysisButton.tsx` — czy sprawdzają `isOnline` |
| 7.6.3 | Toast `info` przy powrocie sieci: "Połączenie przywrócone" | [MANUAL] | Sprawdź `networkMonitor.ts` — `online` event |

---

## 8. BEZPIECZEŃSTWO

### 8.1. Klucze API

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 8.1.1 | Żaden klucz API nie jest w kodzie klienta (brak `GEMINI_KEY`, `GROQ_KEY`, `OPENAI_KEY` w `packages/`) | [AUTO] | `grep -rn "AIzaSy\|sk-\|gsk_\|sk-ant" packages/` — powinno zwrócić 0 |
| 8.1.2 | Zmienne `VITE_*` nie zawierają kluczy AI (tylko `SUPABASE_URL` i `SUPABASE_ANON_KEY`) | [AUTO] | `grep -rn "VITE_GEMINI\|VITE_OPENAI\|VITE_GROQ" packages/` — powinno zwrócić 0 |
| 8.1.3 | Klucze użytkownika (własny OpenAI/Claude) są szyfrowane przez `cryptoService.ts` przed zapisem | [MANUAL] | Sprawdź `packages/web/src/components/settings/AISettings.tsx` — flow zapisu klucza |
| 8.1.4 | `.env.local` jest w `.gitignore` | [AUTO] | `cat .gitignore | grep ".env.local"` — musi być |
| 8.1.5 | `supabase/.env` jest w `.gitignore` | [AUTO] | `cat .gitignore | grep "supabase/.env"` — musi być |

### 8.2. Dane użytkownika i storage

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 8.2.1 | Bezpośrednie wywołania `localStorage.setItem` / `getItem` — zakazane | [AUTO] | `grep -rn "localStorage\.\(set\|get\|remove\)" packages/web/src/ packages/extension/src/` — powinno zwrócić 0 (tylko przez `localStore.ts`) |
| 8.2.2 | Wrażliwe dane (treści rozmów) zapisywane przez `cryptoService.ts` (szyfrowanie AES-GCM) | [MANUAL] | Sprawdź `packages/shared/src/services/localStore.ts` — czy metody zapisu wiadomości używają `cryptoService` |
| 8.2.3 | Token JWT przechowywany przez Supabase Auth — brak własnego przechowywania tokenu w `localStorage` | [AUTO] | `grep -rn "token\|jwt\|bearer" packages/web/src/ | grep "localStorage"` — powinno zwrócić 0 |

### 8.3. Weryfikacja wieku 18+

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 8.3.1 | Template `erotic` niewidoczny w UI dla `verified_18plus === false` (nie tylko disabled — `hidden`) | [MANUAL] | Sprawdź `packages/web/src/components/contacts/ContactForm.tsx` — conditionally render, nie disabled |
| 8.3.2 | Edge Function `ai-proxy` sprawdza `profiles.verified_18plus` z bazy (nie z payload klienta) | [MANUAL] | Sprawdź `supabase/functions/ai-proxy/index.ts` — pobranie profilu z DB |
| 8.3.3 | System prompt zawiera blokadę treści dorosłych dla niezweryfikowanych użytkowników | [MANUAL] | Sprawdź `packages/shared/src/services/promptBuilder.ts` — flaga `isAdultContentAllowed` |

### 8.4. Screenshoty

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 8.4.1 | Nasłuchiwanie PrintScreen w `App.tsx` — blur + toast ostrzeżenia | [MANUAL] | Sprawdź `packages/web/src/App.tsx` useEffect z `keydown` |
| 8.4.2 | Blur klas CSS `.sensitive-content` przy zdarzeniu screenshot | [MANUAL] | Sprawdź `packages/web/src/index.css` — klasa `.screenshot-blur` |

### 8.5. RLS (Row Level Security)

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 8.5.1 | Nowe tabele w migracji SQL mają `ENABLE ROW LEVEL SECURITY` | [MANUAL] | Sprawdź nowe pliki w `supabase/migrations/` |
| 8.5.2 | Każda tabela ma policy `FOR ALL USING (auth.uid() = user_id)` | [MANUAL] | `grep -rn "ENABLE ROW LEVEL" supabase/migrations/` — tyle samo co tabel |
| 8.5.3 | `error_logs` — policy tylko dla `INSERT`, nie `SELECT` dla zwykłych użytkowników | [MANUAL] | Sprawdź migration SQL dla `error_logs` |

---

## 9. SYNCHRONIZACJA I OFFLINE

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 9.1 | Każda operacja zapisu przechodzi przez `syncEngine.ts` (nie bezpośrednio do Supabase) | [MANUAL] | Sprawdź `packages/web/src/hooks/useContacts.ts`, `useConversation.ts` — czy wywołują `syncEngine` czy `supabase.from()` |
| 9.2 | Przy braku sieci operacje trafiają do kolejki `IndexedDB` i nie rzucają błędu | [MANUAL] | Sprawdź `packages/shared/src/services/syncEngine.ts` — obsługa `isOnline === false` |
| 9.3 | Konflikt synchronizacji rozwiązywany przez `lastWriteWins` (timestamp) — z toastem informacyjnym | [MANUAL] | Sprawdź `syncEngine.ts` — metoda `resolveConflict` |
| 9.4 | `IndexedDB` nie przechowuje niezaszyfrowanych treści wiadomości | [MANUAL] | Sprawdź `packages/shared/src/services/localStore.ts` — `saveMessage` |

---

## 10. TESTY

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 10.1 | `pnpm test` przechodzi bez błędów | [AUTO] | Uruchomić przed każdym PR |
| 10.2 | Nowe serwisy w `shared/services/` mają test w `__tests__/` | [MANUAL] | Sprawdź czy dla nowego pliku `xyzService.ts` istnieje `xyzService.test.ts` |
| 10.3 | Nowe hooki w `web/hooks/` mają test z `renderHook` | [MANUAL] | Sprawdź czy dla `useXyz.ts` istnieje `useXyz.test.ts` |
| 10.4 | Testy nie wywołują prawdziwego API (mocki z `shared/mocks/`) | [AUTO] | `grep -rn "supabase.from\|fetch.*api.anthropic\|googleapis" packages/*/src/**/__tests__/` — powinno zwrócić 0 |
| 10.5 | Coverage po zmianach nie spada poniżej 60% dla `shared/`, 50% dla `web/` | [AUTO] | `pnpm test:coverage` — sprawdź raport |
| 10.6 | Testy mocków `IS_DEV` — czy mocki nie wyciekają do produkcji | [MANUAL] | Sprawdź `packages/shared/src/services/aiService.ts` — blok `if (IS_DEV) return mock` |

---

## 11. PLUGIN CHROME/EDGE (Manifest V3)

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 11.1 | `manifest.json` — uprawnienia minimalne (brak uprawnień nieużywanych) | [MANUAL] | Sprawdź `packages/extension/manifest.json` — porównaj z sekcją 6 DEVELOPMENT_PLAN |
| 11.2 | Content script używa Shadow DOM dla overlay (brak ingerencji w CSS strony hosta) | [MANUAL] | Sprawdź `packages/extension/src/content/overlay.ts` |
| 11.3 | Treści AI w overlay renderowane przez `textContent` (nie `innerHTML`) — ochrona XSS | [AUTO] | `grep -rn "innerHTML" packages/extension/src/content/` — powinno zwrócić 0 |
| 11.4 | `window.postMessage` w content script weryfikuje `event.origin` | [MANUAL] | Sprawdź `packages/extension/src/content/index.ts` |
| 11.5 | Komunikacja content script → background używa `chrome.runtime.sendMessage` z typowanym payload | [MANUAL] | Sprawdź czy payload ma interface TypeScript |
| 11.6 | `chrome.storage.local` używany przez `extensionStorage.ts` (nie bezpośrednio) | [AUTO] | `grep -rn "chrome\.storage\.local" packages/extension/src/ | grep -v "extensionStorage"` — powinno zwrócić 0 |

---

## 12. MONETYZACJA I LIMITY

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 12.1 | Limity Free (30 hint/dzień, 3 analizy/tydzień) sprawdzane w Edge Function, nie tylko w UI | [MANUAL] | Sprawdź `supabase/functions/ai-proxy/index.ts` — czy sprawdza `daily_usage` z bazy |
| 12.2 | Komunikat o limicie pokazuje ile zostało + czas odnowienia | [MANUAL] | Sprawdź `packages/web/src/components/hint/HintPanel.tsx` — `LimitReachedMessage` |
| 12.3 | Zablokowana funkcja Premium jest `hidden` (nie `disabled`) — nie kusi disabled przyciskiem | [MANUAL] | Sprawdź komponenty z `requiresPremium` — hidden vs disabled |
| 12.4 | Stripe webhook (`handle-stripe-event`) weryfikuje podpis Stripe | [MANUAL] | Sprawdź `supabase/functions/handle-stripe-event/index.ts` — `stripe.webhooks.constructEvent` |
| 12.5 | `premium_until` sprawdzany server-side (Edge Function), nie tylko w `profiles` z klienta | [MANUAL] | Sprawdź czy `ai-proxy` pobiera `premium_until` bezpośrednio z DB |

---

## 13. DEBUG MODE I ŚRODOWISKO

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 13.1 | Flaga `IS_DEV` pochodzi z `import.meta.env.DEV`, nie hardcoded `true` | [AUTO] | `grep -rn "IS_DEV.*=.*true\b" packages/shared/src/constants.ts` — powinno zwrócić 0 |
| 13.2 | Panel developerski (DEV overlay) renderuje się tylko gdy `IS_DEV === true` | [MANUAL] | Sprawdź `packages/web/src/App.tsx` — `{IS_DEV && <DevPanel />}` |
| 13.3 | Flagi symulacji (`__simulate_offline` etc.) odczytywane tylko gdy `IS_DEV` | [MANUAL] | Sprawdź `packages/shared/src/services/syncEngine.ts` |
| 13.4 | Produkcyjny build nie zawiera referencji do `mocks/` | [AUTO] | `pnpm build` → `grep -rn "from.*mocks" dist/` — powinno zwrócić 0 |

---

## 14. KONWENCJE NAZEWNICTWA

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 14.1 | Komponenty React — `PascalCase`, pliki `.tsx` | [AUTO] | `find packages/web/src/components -name "*.tsx" | grep -v "^[A-Z]"` — 0 wyników |
| 14.2 | Hooki — `camelCase` z prefixem `use`, pliki `.ts` | [AUTO] | `ls packages/web/src/hooks/ | grep -v "^use"` — 0 wyników |
| 14.3 | Serwisy — `camelCase` z sufiksem `Service`, pliki `.ts` | [AUTO] | `ls packages/shared/src/services/ | grep -v "Service\|Engine\|Monitor\|Builder\|Client"` — ręcznie |
| 14.4 | Stałe — `UPPER_SNAKE_CASE` | [MANUAL] | Sprawdź `packages/shared/src/constants.ts` — `IS_DEV`, `APP_VERSION`, limity |
| 14.5 | Typy/Interfejsy — `PascalCase`, pliki w `types/` | [AUTO] | `ls packages/shared/src/types/` — tylko `.ts` bez prefiksów `I` (nie `IContact` — po prostu `Contact`) |

---

## 15. MARTWY KOD I PORZĄDEK

| # | Sprawdzenie | Typ | Polecenie weryfikacji |
|---|-------------|-----|-----------------------|
| 15.1 | Brak plików `.ts`/`.tsx` które nie są importowane nigdzie | [AUTO] | `npx ts-prune packages/` — wyświetla nieużywane eksporty |
| 15.2 | Nieużywane zmienne CSS (klasy w `.css` nieodwoływane z JSX) | [MANUAL] | Sprawdź nowe klasy CSS — czy są rzeczywiście używane |
| 15.3 | `config/locales/pl.json` — brak kluczy zdefiniowanych ale nieużywanych w kodzie | [AUTO] | `node scripts/check_unused_translations.js` (jeśli skonfigurowane) |
| 15.4 | Brak `console.log` (tylko `captureError`/`logger`) | [AUTO] | `grep -rn "console\.log\|console\.warn\|console\.error" packages/` — powinno zwrócić 0 (poza `logger.ts`) |

---

## 📊 PODSUMOWANIE PR (wypełnij przed mergem)

```
Data przeglądu:         YYYY-MM-DD
Reviewer:               @username lub "Claude"
Branch:                 feature/xxx → develop
Commit (HEAD):          abc1234

WYNIKI:
  ✅ Zaliczone:         __/XX
  ⚠️  Ostrzeżenia:      __/XX (opisz poniżej)
  ❌ Błędy (blokujące): __/XX (opisz poniżej)
  ⏭️  N/A:              __/XX

BLOKUJĄCE (wylistuj):
  - [ ] ...

OSTRZEŻENIA (nie blokują, ale warto naprawić):
  - [ ] ...

BACKLOG (do kolejnego PR):
  - [ ] ...

DECYZJA: ✅ MERGE | ⏸️ CHANGES REQUESTED | ❌ BLOCKED
```

> Wyniki zapisz do: `logs/code-review-YYYY-MM-DD.md`
