<!-- =============================================================================
 FILE: AUDIT_CHECKLIST.md
 PATH: docs/AUDIT_CHECKLIST.md
 VERSION: 0.1.0
 PURPOSE: Kompletna lista kontrolna Audytu Projektu ContextCompass – ocena ryzyka, skalowalności, bezpieczeństwa i utrzymywalności. Wykonywany przed każdym release lub przy zmianie zespołu.
 FUNCTIONS: -
 DEPENDS ON: CODE_REVIEW_CHECKLIST.md, DEVELOPMENT_PLAN.md, CODING_STANDARDS.md, SECURITY.md
 UWAGA: [AUTO] = weryfikowalny skryptem/grepem. [MANUAL] = ręczna inspekcja. [DO_WERYFIKACJI] = wymaga decyzji architektonicznej.
 ============================================================================= -->

# 🔍 AUDYT PROJEKTU — ContextCompass

> **Użycie:** Przed każdym release'em (v0.x.0+) lub przy zmianie zespołu/AI pracującego nad projektem.
> Audyt jest głębszy niż Code Review — ocenia ryzyko, koszty utrzymania, skalowalność i compliance całego systemu.
> **Wyniki:** Zapisz do `logs/audit-YYYY-MM-DD.md` (szablon na końcu dokumentu).

---

## 1. BEZPIECZEŃSTWO — GŁĘBOKA ANALIZA

### 1.1. Zależności npm

| # | Sprawdzenie | Typ | Polecenie |
|---|-------------|-----|-----------|
| 1.1.1 | `npm audit --production` — brak podatności `high` i `critical` | [AUTO] | `npm audit --production --json | jq '.metadata.vulnerabilities'` |
| 1.1.2 | Brak przestarzałych pakietów z aktywnymi CVE | [AUTO] | `npm outdated` + ręczna weryfikacja changeloga |
| 1.1.3 | Zależności Supabase SDK są najnowsze (lub ostatnie stabilne) | [AUTO] | `npm outdated @supabase/supabase-js` |
| 1.1.4 | Brak pakietów z `postinstall` skryptami od nieznanych autorów | [MANUAL] | `cat package.json | grep postinstall` + weryfikacja autorów |

### 1.2. Supabase — konfiguracja bezpieczeństwa

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 1.2.1 | RLS włączony na WSZYSTKICH tabelach (nie tylko publicznych) | [AUTO] | `SELECT tablename FROM pg_tables WHERE schemaname='public'` vs lista tabel z RLS |
| 1.2.2 | Żadna tabela nie ma policy `FOR ALL TO anon` (dostęp anonimowy) | [MANUAL] | Sprawdź Supabase Dashboard → Authentication → Policies |
| 1.2.3 | `error_logs` — brak policy `SELECT` dla `authenticated` (tylko `INSERT` + `service_role`) | [MANUAL] | Sprawdź migrację `001_initial_schema.sql` |
| 1.2.4 | Edge Functions nie mają dostępu do tabel innych użytkowników poza `service_role` | [MANUAL] | Sprawdź czy Edge Functions używają `supabaseAdmin` (service_role) tylko tam gdzie niezbędne |
| 1.2.5 | Klucz `service_role` nigdy nie jest w kodzie klienta | [AUTO] | `grep -rn "service_role\|eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" packages/` — powinno zwrócić 0 |
| 1.2.6 | Supabase Storage — buckety z plikami użytkowników mają poprawne policies (private) | [MANUAL] | Sprawdź `supabase/migrations/` — czy storage bucket ma `INSERT` tylko dla właściciela |

### 1.3. AI — klucze i proxy

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 1.3.1 | Klucze AI (`GEMINI_KEY`, `GROQ_KEY`, `OPENAI_KEY`) są wyłącznie w Supabase Secrets | [MANUAL] | Supabase Dashboard → Edge Functions → Secrets — lista powinna zawierać wszystkie klucze |
| 1.3.2 | Edge Function `ai-proxy` rate-limituje zapytania per user (blokuje spam) | [MANUAL] | Sprawdź `supabase/functions/ai-proxy/index.ts` — czy sprawdza liczbę requestów z ostatniej minuty |
| 1.3.3 | Klucze użytkownika (własny OpenAI) szyfrowane AES-GCM przed zapisem do Supabase | [MANUAL] | Sprawdź `cryptoService.ts` + flow `AISettings.tsx` |
| 1.3.4 | System prompt nie może być nadpisany przez payload klienta | [MANUAL] | Sprawdź `ai-proxy` — system prompt budowany server-side z DB, nie z `req.body` |

### 1.4. Autentykacja

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 1.4.1 | Supabase Auth — `emailRedirectTo` wskazuje na własną domenę (nie wildcard) | [MANUAL] | Sprawdź Supabase Dashboard → Authentication → URL Configuration |
| 1.4.2 | OAuth (Google/Apple) — `redirect_uri` ograniczony do znanych domen | [MANUAL] | Sprawdź konfigurację w Google Cloud Console / Apple Developer |
| 1.4.3 | Reset hasła — link jednorazowy (Supabase domyślnie tak robi) | [MANUAL] | Przetestuj flow resetu — drugi klik w link powinien zwrócić błąd |
| 1.4.4 | Auto-logout na niezaufanych urządzeniach działa (15 min) | [MANUAL] | Test manualny: zaloguj się bez „zaufaj urządzeniu", odczekaj 16 min |
| 1.4.5 | Lista zaufanych urządzeń ograniczona do 5 — dodanie 6. usuwa najstarsze | [MANUAL] | Sprawdź logikę w `packages/shared/src/services/supabaseClient.ts` lub w Edge Function |

### 1.5. RODO / GDPR

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 1.5.1 | Przycisk „Usuń konto" — `CASCADE DELETE` usuwa WSZYSTKIE dane użytkownika z DB | [MANUAL] | Sprawdź migration SQL — `ON DELETE CASCADE` na wszystkich tabelach referencing `profiles.id` |
| 1.5.2 | Eksport danych użytkownika (ZIP/JSON) zawiera WSZYSTKIE jego dane | [MANUAL] | Sprawdź `backupService.ts` — pobiera `profiles`, `contacts`, `conversation_messages`, `analysis_reports` |
| 1.5.3 | Supabase region = `eu-central-1` (Frankfurt) | [MANUAL] | Supabase Dashboard → Settings → Infrastructure |
| 1.5.4 | Polityka prywatności dostępna przed rejestracją | [MANUAL] | Sprawdź ekran rejestracji — link do PP musi być klikalny |
| 1.5.5 | Telemetria domyślnie wyłączona (`analyticsEnabled: false` w `default.config.json`) | [AUTO] | `grep "analyticsEnabled" config/default.config.json` — musi być `false` |
| 1.5.6 | Raw treści wklejanych rozmów NIE są zapisywane (tylko hash + podsumowanie AI) | [MANUAL] | Sprawdź `supabase/functions/analyze-conversation/index.ts` — czy `raw_input` trafia do DB |

---

## 2. SKALOWALNOŚĆ I WYDAJNOŚĆ

### 2.1. Limity danych

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 2.1.1 | `conversation_messages` — soft limit 500 wiadomości per kontakt (starsze archiwizowane lub usuwane) | [DO_WERYFIKACJI] | Brak limitu = ryzyko przy aktywnych użytkownikach; dodać `LIMIT_MAX_MESSAGES_PER_CONTACT` w `config/default.config.json` |
| 2.1.2 | `analysis_reports` — limit historii 50 raportów per użytkownik (free) / 200 (premium) | [DO_WERYFIKACJI] | Sprawdź `LIMITS` w `default.config.json` |
| 2.1.3 | `contacts` — limit 10 (free) / bez limitu (premium) sprawdzany server-side | [MANUAL] | Edge Function lub trigger DB przed `INSERT` do `contacts` |
| 2.1.4 | `ai_suggestions` — retencja 30 dni, starsze automatycznie usuwane (Supabase pg_cron) | [DO_WERYFIKACJI] | Dodać `cron` job: `DELETE FROM ai_suggestions WHERE created_at < NOW() - INTERVAL '30 days'` |
| 2.1.5 | `error_logs` — retencja 90 dni | [DO_WERYFIKACJI] | Jw. — cron job |

### 2.2. Wydajność AI

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 2.2.1 | Liczba tokenów wysyłanych do AI per request (max ~4000 tokenów dla kontekstu) | [MANUAL] | Sprawdź `promptBuilder.ts` — `maxTokensEstimate: 4000` w konfiguracji |
| 2.2.2 | Summary kontaktu aktualizowane co 10 wiadomości (nie przy każdej) | [MANUAL] | Sprawdź `supabase/functions/update-contact-summary/index.ts` — warunek triggera |
| 2.2.3 | Profile update batch co 5-10 rozmów (nie per wiadomość) | [MANUAL] | Sprawdź `profileUpdateBatchSize` w `default.config.json` |
| 2.2.4 | Timeout requestów do AI skonfigurowany (15s Gemini, 10s Groq) — nie wisi w nieskończoność | [MANUAL] | Sprawdź `default.config.json` → `api.ai.providers.*.timeoutMs` |

### 2.3. IndexedDB i synchronizacja

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 2.3.1 | Sync interval 30s — czy nie powoduje throttlingu Supabase przy wielu użytkownikach | [DO_WERYFIKACJI] | Dla MVP OK; przy >1000 users rozważyć Realtime subscription zamiast polling |
| 2.3.2 | Kolejka sync nie rośnie bez ograniczeń (max 200 pending operacji?) | [DO_WERYFIKACJI] | Sprawdź `syncEngine.ts` — czy jest limit kolejki |
| 2.3.3 | IndexedDB nie przekracza 50MB per użytkownik (przeglądarka może wyczyścić) | [MANUAL] | Monitoruj rozmiar bazy — dodać alert w `localStore.ts` gdy > 40MB |

### 2.4. Startup i ładowanie

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 2.4.1 | PWA — First Contentful Paint < 2s na 4G | [AUTO] | `npx lighthouse http://localhost:5173 --output json | jq '.audits["first-contentful-paint"]'` |
| 2.4.2 | `React.lazy` dla stron (nie ładuje wszystkich na starcie) | [MANUAL] | Sprawdź `packages/web/src/App.tsx` — czy route'y używają `lazy()` |
| 2.4.3 | Pliki locales ładowane lazy (tylko aktywny język, nie oba) | [MANUAL] | Sprawdź konfigurację `i18next` — `backend.loadPath` |
| 2.4.4 | Plugin — background service worker startuje < 500ms | [MANUAL] | Chrome DevTools → Extensions → background page |

---

## 3. PROCESY I DEVOPS

### 3.1. CI/CD

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 3.1.1 | Pipeline CI uruchamia `pnpm lint` przed mergem | [MANUAL] | Sprawdź `.github/workflows/ci.yml` lub odpowiednik |
| 3.1.2 | Pipeline CI uruchamia `pnpm test` przed mergem | [MANUAL] | Jw. |
| 3.1.3 | Pipeline CI uruchamia `pnpm build` — sprawdza czy build przechodzi | [MANUAL] | Jw. |
| 3.1.4 | `./scripts/check_headers.sh --check-only` w pre-commit hook | [MANUAL] | Sprawdź `.husky/pre-commit` |
| 3.1.5 | `./scripts/check_file_lengths.sh --fail-on-error` w CI | [MANUAL] | Sprawdź pipeline — blokuje merge gdy pliki za długie |
| 3.1.6 | Deploy do Vercel/Netlify automatyczny po merge do `main` | [MANUAL] | Sprawdź konfigurację platformy deploy |

### 3.2. Monitoring błędów produkcyjnych

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 3.2.1 | Edge Function `log-error` aktywna i przyjmuje requesty z aplikacji | [MANUAL] | Sprawdź Supabase Dashboard → Edge Functions → `log-error` → Logs |
| 3.2.2 | Webhook do autora skonfigurowany (`ERROR_WEBHOOK_URL` w Supabase Secrets) | [MANUAL] | Wyślij testowy błąd i sprawdź czy dotarł na webhook |
| 3.2.3 | Alert automatyczny gdy >20 błędów w 5 minut | [MANUAL] | Sprawdź Supabase cron lub zewnętrzny monitor (np. Uptime Robot) |
| 3.2.4 | Tabela `error_logs` — rotacja rekordów starszych niż 90 dni | [DO_WERYFIKACJI] | Dodać cron job |

### 3.3. Backup i recovery

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 3.3.1 | Supabase Point-in-Time Recovery włączony (Plan Pro lub wyżej) | [MANUAL] | Sprawdź Supabase Dashboard → Settings → Database |
| 3.3.2 | Backup eksportu użytkownika (ZIP) działa i zawiera wszystkie tabele | [MANUAL] | Test: zarejestruj konto, dodaj dane, pobierz ZIP, sprawdź zawartość |
| 3.3.3 | Procedura odtworzenia danych opisana w `docs/RECOVERY.md` | [DO_WERYFIKACJI] | Plik `RECOVERY.md` do stworzenia przed release'em |

---

## 4. UTRZYMYWALNOŚĆ

### 4.1. Dokumentacja

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 4.1.1 | `docs/DEVELOPMENT_PLAN.md` aktualny (sekcja „Otwarte pytania" wypełniona) | [MANUAL] | Sprawdź sekcję 15 — czy decyzje z tabeli zostały podjęte |
| 4.1.2 | `docs/CODING_STANDARDS.md` — czy nie ma sprzeczności z aktualnym kodem | [MANUAL] | Sprawdź losowe 5 plików vs zasady z dokumentu |
| 4.1.3 | `docs/UI_MOCKUP.html` — aktualny (ostatnia aktualizacja po każdym sprincie) | [MANUAL] | Sprawdź datę w nagłówku pliku HTML |
| 4.1.4 | `config/locales/pl.json` i `en.json` — identyczne klucze (0 różnic) | [AUTO] | `node scripts/check_locales.js` |
| 4.1.5 | `README.md` — instrukcja `Quick Start` działa od zera (świeże env) | [MANUAL] | Przetestuj na czystym środowisku |

### 4.2. Tech debt

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 4.2.1 | Liczba `// TODO` w całym projekcie | [AUTO] | `grep -rn "TODO" packages/ supabase/ | wc -l` — wpisz wynik w audit |
| 4.2.2 | Pliki przekraczające limit linii | [AUTO] | `./scripts/check_file_lengths.sh` — wpisz liczbę w audit |
| 4.2.3 | Pliki bez nagłówka | [AUTO] | `./scripts/check_headers.sh --check-only` — wpisz liczbę w audit |
| 4.2.4 | Nieużywane eksporty (`ts-prune`) | [AUTO] | `npx ts-prune packages/ | wc -l` — wpisz liczbę |
| 4.2.5 | Coverage testami — aktualny procent | [AUTO] | `pnpm test:coverage` — wpisz % dla `shared/` i `web/` |

### 4.3. Jakość kodu

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 4.3.1 | `pnpm lint` — 0 błędów, ≤5 ostrzeżeń | [AUTO] | Uruchom i zapisz wynik |
| 4.3.2 | `pnpm tsc --noEmit` — 0 błędów TypeScript | [AUTO] | Uruchom i zapisz wynik |
| 4.3.3 | Brak `any` w typach (lub każdy udokumentowany komentarzem) | [AUTO] | `grep -rn ": any\b" packages/ | wc -l` — wpisz liczbę |
| 4.3.4 | Brak `console.log` poza `logger.ts` i `IS_DEV` blokami | [AUTO] | `grep -rn "console\.log" packages/ | wc -l` |

---

## 5. FUNKCJONALNOŚCI — KOMPLETNOŚĆ

### 5.1. Zarządzanie kontaktami

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 5.1.1 | CRUD kontaktów działa (dodaj, edytuj, archiwizuj, usuń z potwierdzeniem) | [MANUAL] | Test manualny — wszystkie 4 operacje |
| 5.1.2 | Sortowanie kontaktów: alfabetycznie (default), po ostatniej aktywności, po typie relacji | [MANUAL] | Sprawdź `packages/web/src/components/contacts/ContactList.tsx` — `SortControls` |
| 5.1.3 | Archiwizacja przenosi kontakt do sekcji „Zarchiwizowane" (nie usuwa) | [MANUAL] | Test manualny |
| 5.1.4 | Wyszukiwanie kontaktów po imieniu/tagu działa | [MANUAL] | Test manualny |
| 5.1.5 | Filtry kontaktów: po typie relacji (template_type) | [MANUAL] | Test manualny |

### 5.2. Podpowiedzi AI (hint)

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 5.2.1 | Podpowiedź generuje się < 8s (Gemini) | [MANUAL] | Test manualny z timerem |
| 5.2.2 | 2-3 warianty odpowiedzi z opisem „dlaczego to działa" | [MANUAL] | Sprawdź format odpowiedzi AI |
| 5.2.3 | Kopiowanie do schowka działa (przycisk + potwierdzenie „Skopiowano!") | [MANUAL] | Test manualny |
| 5.2.4 | Limit dzienny (30 Free) liczy się server-side | [MANUAL] | Wyczyść ciasteczka, zaloguj ponownie — limit powinien pozostać |

### 5.3. Analiza rozmowy

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 5.3.1 | Analiza wklejonej rozmowy zwraca 4 sekcje (mocne, słabe, insights, rekomendacje) | [MANUAL] | Test z przykładową rozmową |
| 5.3.2 | Raport zapisywany w `analysis_reports` | [MANUAL] | Sprawdź Supabase Dashboard po teście |
| 5.3.3 | Historia raportów widoczna w aplikacji | [MANUAL] | Sprawdź `/analysis/:contactId` — lista poprzednich |

### 5.4. Sortowanie i organizacja (lista kontaktów)

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 5.4.1 | Sortowanie **alfabetyczne** (A–Z) — domyślne | [MANUAL] | Sprawdź stan po pierwszym załadowaniu |
| 5.4.2 | Sortowanie **po ostatniej aktywności** (ostatnia wiadomość lub podpowiedź) | [MANUAL] | Przetestuj po dodaniu wiadomości do kontaktu |
| 5.4.3 | Sortowanie **po typie relacji** (template_type: praca, romantyczna...) | [MANUAL] | Test manualny |
| 5.4.4 | Filtr **nieodczytane/nowe** (kontakty z nieodczytaną podpowiedzią lub nową analizą) | [DO_WERYFIKACJI] | Wymaga pola `has_unread` w `contacts` — dodać do schematu? |
| 5.4.5 | Preferencja sortowania zapamiętywana w `profiles.settings` | [MANUAL] | Zmień sortowanie, odśwież — powinno się zapamiętać |

### 5.5. Przypomnienia i zadania

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 5.5.1 | Dodawanie przypomnienia do kontaktu (data + treść) działa | [MANUAL] | Sprawdź `RemindersModal.tsx` |
| 5.5.2 | Push notification przy nadchodzącym przypomnieniu (PWA Service Worker) | [MANUAL] | Test: dodaj przypomnienie na +2 minuty, poczekaj |
| 5.5.3 | Przypomnienia widoczne w widoku kontaktu jako badge/ikona | [MANUAL] | Sprawdź `ContactCard.tsx` — ikona dzwonka z liczbą |
| 5.5.4 | Możliwość oznaczenia przypomnienia jako „wykonane" | [MANUAL] | Test manualny |
| 5.5.5 | Widok listy wszystkich przypomnień (posortowane po dacie) | [MANUAL] | Sprawdź czy jest `/reminders` lub zakładka w Dashboard |

### 5.6. Usuwanie — potwierdzenia

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 5.6.1 | Każda akcja usunięcia otwiera `<ConfirmDialog>` (ZERO `window.confirm()`) | [AUTO] | `grep -rn "window\.confirm" packages/` — powinno zwrócić 0 |
| 5.6.2 | `<ConfirmDialog>` dla usunięcia kontaktu wyświetla imię osoby w treści | [MANUAL] | Sprawdź `ContactCard.tsx` — `t('contact.delete.confirm', { name })` |
| 5.6.3 | `<ConfirmDialog>` dla usunięcia konta wymaga wpisania „USUŃ" | [MANUAL] | Test manualny — sprawdź czy przycisk jest disabled bez wpisania |
| 5.6.4 | Usunięcie wiadomości z historii — `<ConfirmDialog>` z ostrzeżeniem | [MANUAL] | Test manualny |
| 5.6.5 | Żadna akcja nie kasuje danych bez potwierdzenia użytkownika | [MANUAL] | Przejdź przez wszystkie akcje delete/clear w aplikacji |

---

## 6. LOGOWANIE I MONITORING (APLIKACYJNY)

### 6.1. Logger i błędy

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 6.1.1 | `shared/services/logger.ts` eksportuje `logInfo`, `logWarn`, `logError`, `captureError` | [AUTO] | `grep -rn "export" packages/shared/src/services/logger.ts` |
| 6.1.2 | `logError` wywołany w każdym bloku `catch` (nie tylko `console.error`) | [MANUAL] | Sprawdź `packages/shared/src/services/` — każdy serwis |
| 6.1.3 | `logWarn` używany dla sytuacji częściowo poprawnych (fallback AI, sync conflict) | [MANUAL] | Sprawdź `aiService.ts` przy fallbacku, `syncEngine.ts` przy konflikcie |
| 6.1.4 | `logInfo` używany dla kluczowych akcji (login, zapis kontaktu, analiza) | [MANUAL] | Sprawdź hooki — `useAuth`, `useContacts`, `useConversation` |
| 6.1.5 | W trybie `IS_DEV`: logi w konsoli z poziomem i kontekstem | [MANUAL] | Uruchom dev, sprawdź DevTools Console |
| 6.1.6 | W trybie produkcyjnym: błędy wysyłane do Edge Function `log-error` | [MANUAL] | Sprawdź `logger.ts` — blok `!IS_DEV` |

### 6.2. Logi dostępne w aplikacji (Settings → Logi)

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 6.2.1 | Zakładka „Logi" w Ustawieniach wyświetla ostatnie błędy (`error_logs`) z bazy | [MANUAL] | Sprawdź `packages/web/src/components/settings/LogsSettings.tsx` |
| 6.2.2 | Logi filtrowane: wszystkie / tylko błędy / ostrzeżenia / informacje | [MANUAL] | Sprawdź filtry w `LogsSettings` |
| 6.2.3 | Każdy log ma: timestamp, poziom, platforma, kontekst akcji | [MANUAL] | Sprawdź tabelę `error_logs` w Supabase |
| 6.2.4 | Przycisk „Wyczyść logi" z `<ConfirmDialog>` | [MANUAL] | Test manualny |
| 6.2.5 | Przycisk „Wyślij raport błędów" (wysyła ostatnie 10 błędów na webhook) | [DO_WERYFIKACJI] | Dobra feature do wsparcia — rozważyć implementację |
| 6.2.6 | Krytyczne błędy (Edge Function down, Supabase error) pokazują badge w Settings icon | [DO_WERYFIKACJI] | Badge z liczbą nowych błędów na ikonie ustawień |

---

## 7. SPECYFICZNE DLA CONTEXTCOMPASS — RYZYKA

### 7.1. AI — ryzyko i jakość

| # | Ryzyko | Prawdopodobieństwo | Wpływ | Mitygacja |
|---|--------|-------------------|-------|-----------|
| 7.1.1 | Gemini free limit wyczerpany dla wielu użytkowników w tym samym czasie | Wysokie | Wysoki | Fallback chain + komunikat; docelowo własny klucz premium |
| 7.1.2 | AI generuje treści nieodpowiednie dla niezweryfikowanych 18+ | Średnie | Bardzo wysoki | Server-side check `verified_18plus` + blokada w system prompt |
| 7.1.3 | Hallucynacje AI w podpowiedziach (fałszywe fakty o rozmówcy) | Wysokie | Średni | Disclaimery w UI: „AI może się mylić — to tylko sugestia" |
| 7.1.4 | Kontekst za długi dla free modelu (przekroczenie limitu tokenów) | Średnie | Średni | Truncacja w `promptBuilder.ts` + test jednostkowy |

### 7.2. Synchronizacja i dane

| # | Ryzyko | Prawdopodobieństwo | Wpływ | Mitygacja |
|---|--------|-------------------|-------|-----------|
| 7.2.1 | Utrata danych przy konflikcie sync (LastWriteWins) | Niskie | Wysoki | Toast o konflikcie + opcja „cofnij" (soft undo przez 5 minut?) |
| 7.2.2 | IndexedDB wyczyszczone przez przeglądarkę (storage pressure) | Niskie | Wysoki | Sync do Supabase jest source of truth; rebuild lokalny przy potrzebie |
| 7.2.3 | Brak migracji danych przy zmianie schematu IndexedDB | Średnie | Wysoki | Wersjonowanie schematu IndexedDB (`db.version(2).upgrade(...)`) |

### 7.3. Plugin przeglądarkowy

| # | Ryzyko | Prawdopodobieństwo | Wpływ | Mitygacja |
|---|--------|-------------------|-------|-----------|
| 7.3.1 | Manifest V3 service worker unloads po 5 min bezczynności | Wysokie | Średni | Rejestruj `keepAlive` ping lub użyj `chrome.alarms` |
| 7.3.2 | Overlay CSS koliduje z CSS strony hosta | Średnie | Niski | Shadow DOM izoluje — sprawdź na WA, Messenger, Discord |
| 7.3.3 | Review odrzucony przez Chrome Web Store (treści 18+) | Średnie | Wysoki | Plugin nie renderuje treści erotycznych bezpośrednio — overlay jest neutralny |

### 7.4. Mobilne (PWA/React Native)

| # | Ryzyko | Prawdopodobieństwo | Wpływ | Mitygacja |
|---|--------|-------------------|-------|-----------|
| 7.4.1 | iOS Safari ogranicza push notifications dla PWA | Wysokie | Średni | Dodaj native reminder fallback (in-app notification przy otwarciu) |
| 7.4.2 | Web Speech API niedostępne na iOS (Safari) | Wysokie | Niski | Fallback komunikat „Użyj Chrome/Edge dla nagrywania głosowego" |
| 7.4.3 | Brak `FLAG_SECURE` w PWA (screenshoty możliwe) | Wysokie | Średni | Ostrzeżenie użytkownikowi; pełna blokada tylko w React Native |

---

## 8. DOJRZAŁOŚĆ PRODUKTOWA

| # | Obszar | Status | Uwagi |
|---|--------|--------|-------|
| 8.1 | Onboarding (3 kroki) — kompletny i testowalny | [MANUAL] | Test na czystym koncie |
| 8.2 | Splash screen z animacją | [MANUAL] | Sprawdź `packages/web/src/pages/Splash.tsx` |
| 8.3 | Ikona aplikacji we wszystkich rozmiarach (PWA + plugin) | [MANUAL] | Sprawdź `public/icons/` — 16, 32, 48, 128, 192, 512px |
| 8.4 | Motyw ciemny/jasny działa poprawnie na wszystkich stronach | [MANUAL] | Przełącz motyw i sprawdź każdy widok |
| 8.5 | Aplikacja działa offline (basic read — lista kontaktów z IndexedDB) | [MANUAL] | DevTools → Network → Offline — otwórz aplikację |
| 8.6 | PWA instalowalna na iOS/Android | [MANUAL] | Test na urządzeniu mobilnym — „Dodaj do ekranu głównego" |
| 8.7 | `manifest.webmanifest` poprawnie skonfigurowany | [AUTO] | `npx pwa-asset-generator --check` lub Lighthouse PWA audit |
| 8.8 | Lighthouse PWA score > 80 | [AUTO] | `npx lighthouse http://localhost:5173 --preset=desktop` |

---

## 9. PODSUMOWANIE RYZYK

| # | Ryzyko | Prawdopodobieństwo | Wpływ | Priorytet |
|---|--------|-------------------|-------|-----------|
| 1 | Gemini free limit — fallback chain nie działa poprawnie | Wysokie | Wysoki | 🔴 P0 — napraw przed release |
| 2 | Treści 18+ dostępne bez weryfikacji (server-side bypass) | Średnie | Bardzo wysoki | 🔴 P0 |
| 3 | Utrata danych przy sync konflikcie | Niskie | Wysoki | 🟡 P1 — zaimplementuj undo |
| 4 | Manifest V3 service worker unload | Wysokie | Średni | 🟡 P1 |
| 5 | iOS Safari brak push notifications | Wysokie | Niski | 🟢 P2 — fallback in-app |
| 6 | Brak migracji schematu IndexedDB | Średnie | Wysoki | 🟡 P1 — dodaj wersjonowanie |
| 7 | AI hallucynacje w podpowiedziach | Wysokie | Średni | 🟡 P1 — disclaimery w UI |
| 8 | Brak backupu automatycznego (free tier) | Średnie | Średni | 🟢 P2 — premium feature |

---

## 📊 KARTA AUDYTU (wypełnij)

```
Data audytu:            YYYY-MM-DD
Audytor:                @username lub "Claude"
Wersja aplikacji:       x.x.x
Commit (HEAD):          abc1234
Środowisko:             development / staging / production

METRYKI TECHNICZNE:
  pnpm lint errors:             __
  pnpm tsc errors:              __
  Test coverage (shared):       __%
  Test coverage (web):          __%
  Lighthouse PWA score:         __
  Pliki bez nagłówka:           __
  Pliki przekraczające limit:   __
  TODO w kodzie:                __
  Nieużywane eksporty:          __
  Użycia `any`:                 __
  console.log w kodzie:         __

WYNIKI CHECKLISTY:
  ✅ Zaliczone:                 __/XX
  ⚠️  Do poprawy (nie blokują): __/XX
  ❌ Blokujące (P0):            __/XX
  🔄 BACKLOG:                   __/XX
  ⏭️  N/A:                      __/XX

BLOKUJĄCE (P0 — naprawić przed release):
  1. ...

DO POPRAWY (P1 — w następnym sprincie):
  1. ...

BACKLOG (P2 — rozważyć):
  1. ...

DECYZJA: ✅ READY FOR RELEASE | ⏸️ HOLD — FIX P0s | ❌ BLOCKED
```

> Wyniki zapisz do: `logs/audit-YYYY-MM-DD.md`
