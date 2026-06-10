<!-- =============================================================================
 FILE: CODE_REVIEW_CHECKLIST.md
 PATH: docs/CODE_REVIEW_CHECKLIST.md
 VERSION: 0.1.0
 PURPOSE: Kompletna lista kontrolna Code Review dla KlassMate – weryfikacja kodu przed mergem do main/develop.
 FUNCTIONS: -
 DEPENDS ON: docs/01_ARCHITECTURE.md, docs/02_CODE_STANDARDS.md, docs/03_AI_RULES.md, docs/04_SECURITY.md
 UWAGA: Nie usuwać komentarzy – opisują flow aplikacji. Wynik przeglądu zapisać w logs/YYYY-MM-DD_code_review.md
 ============================================================================= -->

# 📋 CODE REVIEW CHECKLIST — KlassMate

> **Użycie:** Przed każdym pull requestem lub po większych zmianach przejdź przez poniższe punkty.
> **Dla AI:** Punkty `[AUTO]` można zweryfikować skryptem lub grep. Punkty `[MANUAL]` wymagają inspekcji ludzkiej lub kontekstu.
> **Wynik:** Skopiuj tabelę wyników na końcu i zapisz do `logs/YYYY-MM-DD_code_review.md`.

---

## 1. NAGŁÓWKI PLIKÓW I DOKUMENTACJA

### 1.1. Nagłówek JSDoc w każdym pliku

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 1.1.1 | Każdy plik `.ts` / `.tsx` ma blok `@file`, `@path`, `@description` | [AUTO] | `grep -rL "@file" src/ --include="*.ts" --include="*.tsx"` → powinno zwrócić 0 plików |
| 1.1.2 | Pole `@exports` wymienia wszystkie eksportowane stałe i funkcje | [MANUAL] | Sprawdzić zgodność z kodem |
| 1.1.3 | Pole `@dependsOn` wymienia wszystkie importy (ścieżki) | [MANUAL] | Porównać z sekcją `import` na dole pliku |
| 1.1.4 | Nagłówek nie jest kopiuj-wklej z innego pliku (generyczny opis) | [MANUAL] | Zwłaszcza sprawdzić nowe pliki dodane przez AI |

### 1.2. Komentarze w kodzie

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 1.2.1 | Każda eksportowana funkcja ma komentarz `// ─── nazwa() – opis` | [AUTO] | Brak wymagany dla prostych getterów/setterów |
| 1.2.2 | Brak zakomentowanego kodu bez wyjaśnienia | [AUTO] | `grep -rn "//.*=\|//.*=>" src/` → ręczna weryfikacja |
| 1.2.3 | `// TODO` mają autora i datę: `// TODO(@user): opis — YYYY-MM-DD` | [MANUAL] | Brak daty = stare TODO |
| 1.2.4 | Brak `// FIXME` bez rozwiązania w tym PR | [MANUAL] | FIXME muszą być rozwiązane przed mergem |
| 1.2.5 | Komentarze po polsku lub angielsku (nie mieszać w jednym pliku) | [MANUAL] | Spójność języka w danym pliku |

---

## 2. ARCHITEKTURA PLIKÓW I STRUKTURA

### 2.1. Katalogi i ich przeznaczenie

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 2.1.1 | `src/app/` – tylko ekrany i layouty Expo Router, zero logiki biznesowej | [MANUAL] | Logika → hooki (`src/hooks/`) |
| 2.1.2 | `src/components/` – tylko komponenty UI (brak wywołań Supabase bezpośrednio) | [MANUAL] | Supabase → `src/lib/supabase/queries/` |
| 2.1.3 | `src/hooks/` – wszystkie pliki z prefixem `use`, eksportują hooki | [AUTO] | `ls src/hooks/ \| grep -v "^use"` → powinno zwrócić 0 |
| 2.1.4 | `src/store/` – tylko Zustand stores, brak JSX | [AUTO] | `grep -r "import.*React" src/store/` → powinno zwrócić 0 |
| 2.1.5 | `src/lib/` – logika domenowa, serwisy, klient Supabase | [MANUAL] | Brak JSX, brak hooków React |
| 2.1.6 | `src/utils/` – czyste funkcje (brak side effects, brak hooków) | [AUTO] | `grep -r "useState\|useEffect" src/utils/` → powinno zwrócić 0 |
| 2.1.7 | `src/config/` – tylko stałe konfiguracyjne (brak logiki warunkowej poza feature flagami) | [MANUAL] | Sprawdzić czy nie ma `if/else` poza `FEATURES` |
| 2.1.8 | `src/constants/` – tylko obiekty stałych (brak funkcji) | [MANUAL] | `ICONS`, `COLORS`, `SPACING` – brak logiki |
| 2.1.9 | `supabase/functions/` – każda Edge Function to osobny folder | [MANUAL] | Jeden plik `index.ts` per funkcja |
| 2.1.10 | `src/app/debug/` – dostępny tylko przy `FEATURES.DEBUG_PANEL === true` | [AUTO] | Sprawdzić guard w `_layout.tsx` |

### 2.2. Długość plików

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 2.2.1 | Żaden plik `.ts` / `.tsx` nie przekracza 200 linii | [AUTO] | `find src/ -name "*.ts" -o -name "*.tsx" \| xargs wc -l \| awk '$1 > 200'` |
| 2.2.2 | Jeśli plik zbliża się do 200 linii → sprawdzić czy nie wymaga podziału | [MANUAL] | Propozycja podziału powinna być w komentarzu PR |
| 2.2.3 | Edge Functions nie przekraczają 150 linii | [AUTO] | `find supabase/functions/ -name "index.ts" \| xargs wc -l \| awk '$1 > 150'` |

---

## 3. TYPESCRIPT I TYPY

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 3.1 | Brak użycia `any` | [AUTO] | `grep -rn ": any\|as any\|<any>" src/` → powinno zwrócić 0 |
| 3.2 | Wszystkie parametry funkcji mają typy (brak implicit any) | [AUTO] | `tsc --noEmit` bez błędów |
| 3.3 | Wartości zwracane z async funkcji są typowane (`Promise<Result<T, E>>`) | [MANUAL] | Szczególnie hooki i lib/queries/ |
| 3.4 | Brak `!` (non-null assertion) bez komentarza wyjaśniającego | [MANUAL] | `grep -rn "!\." src/` → ręczna weryfikacja |
| 3.5 | Typy DB generowane przez `supabase gen types` – nie pisane ręcznie | [MANUAL] | Plik `src/lib/supabase/types.ts` pochodzi z generatora |
| 3.6 | Interfejsy props komponentów mają suffix `Props` (`MessageBubbleProps`) | [AUTO] | `grep -rn "interface.*{" src/components/` → sprawdzić nazwy |
| 3.7 | Brak re-exportów z `index.ts` poza wyjątkami (config, types) | [AUTO] | `grep -rn "export \*" src/` → powinno być tylko w `src/config/index.ts` i `src/types/index.ts` |
| 3.8 | `satisfies` używane przy walidacji obiektów konfiguracyjnych | [MANUAL] | Np. `export const FEATURES = { ... } satisfies FeatureFlags` |

---

## 4. OBSŁUGA BŁĘDÓW

### 4.1. Try-catch i Result pattern

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 4.1.1 | Każde wywołanie Supabase opakowane w `try/catch` | [AUTO] | `grep -rn "supabase\." src/lib/ \| grep -v "try\|catch"` → ręczna weryfikacja |
| 4.1.2 | Funkcje async w hookach zwracają `Result<T, AppError>` (nie rzucają) | [MANUAL] | Sprawdzić `src/hooks/useMessages.ts`, `useClass.ts` |
| 4.1.3 | Edge Functions mają `try/catch` na najwyższym poziomie | [AUTO] | `grep -L "try {" supabase/functions/*/index.ts` → powinno zwrócić 0 |
| 4.1.4 | Edge Functions zwracają `{ status: 500 }` przy błędzie (nie rzucają) | [MANUAL] | Sprawdzić każdy `catch` blok |
| 4.1.5 | `AppError` class używana konsekwentnie (nie `new Error()` bezpośrednio) | [AUTO] | `grep -rn "new Error(" src/` → powinno zwrócić 0 (poza `src/lib/errors/types.ts`) |

### 4.2. Logger

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 4.2.1 | Brak `console.log` w kodzie produkcyjnym | [AUTO] | `grep -rn "console\.log\|console\.warn\|console\.error" src/` → powinno zwrócić 0 (poza `src/lib/errors/logger.ts`) |
| 4.2.2 | Każdy `catch` blok z istotną operacją ma `logger.error()` | [MANUAL] | Sprawdzić `src/lib/`, `src/hooks/` |
| 4.2.3 | `logger.debug()` używany dla informacji deweloperskich (strippowany w produkcji) | [MANUAL] | Nie `logger.info()` dla debugowania |
| 4.2.4 | Logger nie zawiera PII (nie loguje treści wiadomości, emaili, nazw) | [MANUAL] | Sprawdzić `logger.error()` w `src/lib/supabase/queries/` |
| 4.2.5 | Sentry `beforeSend` hook usuwa dane osobowe | [AUTO] | Sprawdzić `src/lib/errors/logger.ts` – czy jest `delete event.user?.email` |

---

## 5. I18N — BRAK HARDCODED STRINGÓW

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 5.1 | Brak string literals w JSX (wszystko przez `t()`) | [AUTO] | `grep -rn ">\s*[A-ZŁĄĆĘÓŚŹŻ][a-ząćęóśźżłń]" src/components/` → ręczna weryfikacja polskich stringów |
| 5.2 | Brak `Alert.alert("string")` bez `t()` | [AUTO] | `grep -rn 'Alert\.alert(' src/` → sprawdzić czy używa `t()` |
| 5.3 | Klucze i18n dodane do obu `pl.json` i `en.json` równocześnie | [MANUAL] | Porównać kluczowe sekcje: `diff <(jq 'keys' pl.json) <(jq 'keys' en.json)` |
| 5.4 | Brak pustych wartości w plikach tłumaczeń | [AUTO] | `grep -n '""' src/i18n/pl.json src/i18n/en.json` → powinno zwrócić 0 |
| 5.5 | Pluralizacja przez `t('key', { count })` (nie przez `if/else` z string) | [MANUAL] | Sprawdzić liczby nieodczytane, liczby wiadomości |
| 5.6 | Brak hardcoded nazw ikon — używać `ICONS.xxx` | [AUTO] | `grep -rn "name=\"[a-z]" src/components/` → sprawdzić literały |

---

## 6. BEZPIECZEŃSTWO I AUTH

### 6.1. Supabase RLS

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 6.1.1 | Każda nowa tabela ma `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` | [AUTO] | Sprawdzić nowe migracje: `grep -L "ENABLE ROW LEVEL SECURITY" supabase/migrations/` |
| 6.1.2 | Każda nowa tabela ma co najmniej jedną politykę RLS | [AUTO] | `grep -L "CREATE POLICY" supabase/migrations/` → nowe tabele bez polityki |
| 6.1.3 | Polityki RLS używają `auth.uid()` a nie hardcoded ID | [AUTO] | `grep -rn "= '.*-.*-.*-.*-.*'" supabase/migrations/` → powinno zwrócić 0 |
| 6.1.4 | Service role key (`SUPABASE_SERVICE_ROLE_KEY`) tylko w Edge Functions | [AUTO] | `grep -rn "SERVICE_ROLE" src/` → powinno zwrócić 0 |
| 6.1.5 | Klient Supabase w `src/lib/supabase/client.ts` używa anon key | [MANUAL] | Sprawdzić `createClient()` – musi być `EXPO_PUBLIC_SUPABASE_ANON_KEY` |

### 6.2. Sesje i biometria

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 6.2.1 | Tokeny sesji w `SecureStore` (nie `AsyncStorage`) | [AUTO] | `grep -rn "AsyncStorage" src/lib/auth/` → powinno zwrócić 0 |
| 6.2.2 | Biometryczny re-auth przed wrażliwymi akcjami (zmiana email, export, usunięcie konta) | [MANUAL] | Sprawdzić `src/app/(main)/settings/account.tsx` i `backup.tsx` |
| 6.2.3 | `isBiometricAvailable()` sprawdzane przed pokazaniem opcji biometrii | [MANUAL] | Sprawdzić `src/lib/auth/biometrics.ts` |
| 6.2.4 | Timeout sesji (4h) dla urządzeń niezaufanych zaimplementowany | [MANUAL] | Sprawdzić `src/lib/auth/session.ts` |

### 6.3. Moderacja

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 6.3.1 | Każda wiadomość przechodzi przez Edge Function `moderate-message` przed zapisem | [MANUAL] | Sprawdzić `src/hooks/useMessages.ts` – flow wysyłania |
| 6.3.2 | DM-y NIE pokazują treści flagowanej administratorowi klasy | [MANUAL] | Sprawdzić `src/app/(main)/class/[classId]/moderation.tsx` |
| 6.3.3 | Brak możliwości ominięcia moderacji przez zmianę payload po stronie klienta | [MANUAL] | Edge Function waliduje JWT i nie ufa danym z klienta |

---

## 7. KOMPONENTY I REACT

### 7.1. Wzorce

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 7.1.1 | Komponenty listowe opakowane w `React.memo` | [AUTO] | `grep -rn "React.memo" src/components/` → sprawdzić `MessageBubble`, `MemberListItem`, `ChannelListItem` |
| 7.1.2 | Event handlery przekazywane do list używają `useCallback` | [MANUAL] | Brak `useCallback` → niepotrzebne re-rendery |
| 7.1.3 | Ekrany z listami mają stan loading (Skeleton) | [MANUAL] | Sprawdzić `channel/[channelId].tsx`, `members.tsx` |
| 7.1.4 | Ekrany z listami mają stan pusty (EmptyState) | [MANUAL] | Sprawdzić te same ekrany |
| 7.1.5 | `displayName` ustawiony na komponentach `React.memo` | [AUTO] | `grep -rn "React.memo" src/components/ -A 5 \| grep "displayName"` → sprawdzić |
| 7.1.6 | Brak logiki biznesowej w plikach `src/app/` | [MANUAL] | Logika → hooki. Ekran: tylko UI + hook |

### 7.2. Accessibility

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 7.2.1 | Przyciski mają `accessibilityLabel` | [AUTO] | `grep -rn "<Pressable\|<TouchableOpacity" src/components/ -A 3 \| grep -L "accessibilityLabel"` |
| 7.2.2 | Przyciski ikon mają `accessibilityHint` | [MANUAL] | Sprawdzić przyciski send, attach, voice |
| 7.2.3 | Obrazy mają `accessibilityLabel` lub `accessible={false}` (jeśli dekoracyjne) | [MANUAL] | Sprawdzić `AttachmentPreview`, `Avatar` |

### 7.3. Help system

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 7.3.1 | Każda nowa akcja użytkownika ma Toast feedback | [MANUAL] | Sprawdzić czy `showToast()` wywoływany po: send, upload, save, block, approve, reject |
| 7.3.2 | Nowe nieintuicyjne elementy UI mają tooltip (key w `SeenTooltips`) | [MANUAL] | Sprawdzić `src/config/features.config.ts` → `SeenTooltips` type |
| 7.3.3 | Toast error sugeruje akcję naprawczą (`action` prop) | [MANUAL] | Np. "Brak połączenia" → button "Spróbuj ponownie" |

---

## 8. TESTY

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 8.1 | Nowa funkcja w `src/utils/` ma test jednostkowy | [MANUAL] | Sprawdzić `__tests__/unit/utils/` |
| 8.2 | Nowa funkcja query Supabase ma test integracyjny | [MANUAL] | Sprawdzić `__tests__/integration/queries/` |
| 8.3 | Nowy komponent interaktywny ma test RNTL | [MANUAL] | Sprawdzić `__tests__/components/` |
| 8.4 | Testy używają mock Supabase (nie real client) | [AUTO] | `grep -rn "createClient" __tests__/` → powinno zwrócić 0 (mock w setup) |
| 8.5 | Nowe Edge Functions mają testy Deno | [MANUAL] | `supabase/functions/__tests__/` |
| 8.6 | `npm test` przechodzi bez błędów | [AUTO] | Obowiązkowe przed mergem |
| 8.7 | `tsc --noEmit` przechodzi bez błędów | [AUTO] | Obowiązkowe przed mergem |

---

## 9. PERFORMANCE

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 9.1 | Subskrypcje Supabase Realtime są czyszczone w cleanup `useEffect` | [AUTO] | `grep -rn "\.subscribe(" src/hooks/ -A 20 \| grep "return () =>"` → sprawdzić |
| 9.2 | OCR (Tesseract.js) ładowany leniwie – tylko gdy Notes module otwarty | [MANUAL] | Sprawdzić `src/lib/ocr/tesseract.ts` – czy jest `dynamic import` |
| 9.3 | Obrazy kompresowane przed wysłaniem (nie po) | [MANUAL] | Sprawdzić `src/lib/storage/upload.ts` |
| 9.4 | `setInterval` / `setTimeout` czyszczone w cleanup | [AUTO] | `grep -rn "setInterval\|setTimeout" src/ -A 10 \| grep "clearInterval\|clearTimeout"` |
| 9.5 | Zustand selektory – komponenty subskrybują tylko potrzebny wycinek state | [MANUAL] | Brak `useStore()` bez selektora na komponentach listowych |

---

## 10. KONFIGURACJA I ENV

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 10.1 | Żadna wartość konfiguracyjna nie jest hardcoded – wszystko z `src/config/` | [MANUAL] | Limity, timeouty, URL, klucze – sprawdzić nowe pliki |
| 10.2 | `.env.development` i `.env.production` nie są commitowane (w `.gitignore`) | [AUTO] | `git ls-files .env*` → powinno zwrócić 0 |
| 10.3 | `.env.example` jest aktualny (zawiera klucze z nowych feature'ów) | [MANUAL] | Sprawdzić przy każdym dodaniu nowej zmiennej EXPO_PUBLIC_ |
| 10.4 | Feature flagi DEBUG_ nigdy `true` w `.env.production` | [AUTO] | `grep "DEBUG_MODE=true\|MOCK_=true" .env.production` → powinno zwrócić 0 |
| 10.5 | `LIMITS`, `FEATURES`, `LOCALES` config używane zamiast magic numbers w kodzie | [MANUAL] | `grep -rn "4 \* 60\|5 \* 1024\|200 \*" src/` → sprawdzić magic numbers |

---

## 11. MIGRACJE BAZY DANYCH

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 11.1 | Nowa migracja ma incrementalną nazwę (`0005_...sql`) | [MANUAL] | Sprawdzić czy nie modyfikuje poprzednich migracji |
| 11.2 | Żadna migracja nie zawiera `DELETE FROM` na tabelach z danymi użytkowników | [AUTO] | `grep -rn "^DELETE FROM" supabase/migrations/` → ręczna weryfikacja |
| 11.3 | Migracja ma `updated_at` trigger dla nowych tabel | [AUTO] | `grep -L "updated_at_trigger\|moddatetime" supabase/migrations/*.sql` |
| 11.4 | Nowe indeksy na kolumnach FK i kolumnach WHERE | [MANUAL] | `grep -n "CREATE INDEX" supabase/migrations/` → czy pokrywa nowe FK |
| 11.5 | Seed data tylko w `supabase/seed/dev_seed.sql` (nie w migracjach) | [MANUAL] | Sprawdzić czy w migracjach nie ma `INSERT INTO ... VALUES (...)` z danymi testowymi |

---

## 12. SPECYFICZNE DLA KLASSMATCH

### 12.1. Moderacja

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 12.1.1 | Odrzucona wiadomość NIE jest zapisywana do tabeli `messages` | [MANUAL] | Sprawdzić Edge Function `moderate-message/index.ts` |
| 12.1.2 | Wiadomość `queued_review` NOT widoczna w kanale (tylko adminom) | [MANUAL] | Sprawdzić RLS policy `messages_select` – filtruje `moderation_status` |
| 12.1.3 | Admin może tylko usunąć fragment / odrzucić – nie może edytować treści | [MANUAL] | Sprawdzić `ModerationQueueItem.tsx` i `TrimMessageModal.tsx` |
| 12.1.4 | `original_content` zachowywany przy trim (nie nadpisywany) | [AUTO] | Sprawdzić SQL UPDATE w Edge Function |

### 12.2. Prywatność dzieci

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 12.2.1 | Rejestracja pyta o `birth_year` (nie pełną datę urodzenia) | [MANUAL] | Sprawdzić `src/app/(auth)/register.tsx` |
| 12.2.2 | Użytkownicy < 16 lat nie mogą ukończyć rejestracji bez statusu `consent_pending` | [MANUAL] | Sprawdzić logikę age gate w `register.tsx` |
| 12.2.3 | DM nie pozwala na wysyłanie zdjęć | [MANUAL] | Sprawdzić `src/app/(main)/dm/[conversationId].tsx` – brak `AttachmentButton` |
| 12.2.4 | Logi błędów nie zawierają treści wiadomości | [MANUAL] | Sprawdzić wywołania `logger.error` w hooks i queries |

### 12.3. Backup i dane

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 12.3.1 | Export danych wymaga biometrycznego re-auth | [MANUAL] | Sprawdzić `src/app/(main)/settings/backup.tsx` |
| 12.3.2 | Usunięcie konta: soft delete wiadomości + anonimizacja profilu (nie hard delete) | [MANUAL] | Sprawdzić `delete-user-data` Edge Function |
| 12.3.3 | Archiwizacja klasy: wiadomości zostają (read-only), nie są usuwane | [MANUAL] | Sprawdzić `archive-class` Edge Function |

---

## 🔚 WYNIK CODE REVIEW

> Skopiuj poniższą tabelę i wypełnij w `logs/YYYY-MM-DD_code_review.md`

```markdown
# Code Review — YYYY-MM-DD
## PR / Branch: [nazwa]
## Reviewer: [imię/model AI]

| Sekcja | Punkty łącznie | ✅ OK | ⚠️ Wymaga uwagi | ❌ Blokuje merge | N/D |
|--------|---------------|-------|-----------------|-----------------|-----|
| 1. Nagłówki i dokumentacja | 9 | | | | |
| 2. Architektura i struktura | 13 | | | | |
| 3. TypeScript i typy | 8 | | | | |
| 4. Obsługa błędów | 10 | | | | |
| 5. i18n | 6 | | | | |
| 6. Bezpieczeństwo i auth | 11 | | | | |
| 7. Komponenty i React | 11 | | | | |
| 8. Testy | 7 | | | | |
| 9. Performance | 5 | | | | |
| 10. Konfiguracja i env | 5 | | | | |
| 11. Migracje DB | 5 | | | | |
| 12. KlassMate specyficzne | 12 | | | | |
| **RAZEM** | **102** | | | | |

## Blokujące problemy (❌):
- [ ] ...

## Wymagające uwagi (⚠️):
- [ ] ...

## Decyzja: [ ] Approved  [ ] Changes requested  [ ] Blocked
```
