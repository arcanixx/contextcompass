<!-- =============================================================================
 FILE: AUDIT_CHECKLIST.md
 PATH: docs/AUDIT_CHECKLIST.md
 VERSION: 0.1.0
 PURPOSE: Kompletna lista kontrolna Audytu Projektu KlassMate – ocena ryzyka, skalowalności, bezpieczeństwa i utrzymywalności.
 FUNCTIONS: -
 DEPENDS ON: docs/CODE_REVIEW_CHECKLIST.md, docs/01_ARCHITECTURE.md, docs/05_LEGAL_COMPLIANCE.md
 UWAGA: Audyt wykonywany przed każdym release'em lub zmianą zespołu. Wynik zapisać w logs/YYYY-MM-DD_audit.md
 ============================================================================= -->

# 🔍 AUDYT PROJEKTU — KlassMate

> **Użycie:** Przed głównym release'em każdej fazy lub przy onboardingu nowego dewelopera / modelu AI.
> Audyt jest głębszy niż Code Review — ocenia ryzyko systemowe, koszty utrzymania, skalowalność i compliance.
> **Wynik:** Skopiuj tabelę podsumowania na końcu i zapisz do `logs/YYYY-MM-DD_audit.md`.

---

## 1. BEZPIECZEŃSTWO (GŁĘBOKIE)

### 1.1. Zależności

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 1.1.1 | `npm audit --production` – brak wysokich i krytycznych podatności | [AUTO] | Blokuje release jeśli jest `high` lub `critical` |
| 1.1.2 | `npm outdated` – brak pakietów z deprecated status | [AUTO] | Szczególnie `expo`, `@supabase/supabase-js`, `react-native` |
| 1.1.3 | `expo-local-authentication` na aktualnej wersji (biometria) | [AUTO] | `npm ls expo-local-authentication` |
| 1.1.4 | `expo-secure-store` na aktualnej wersji (keychain) | [AUTO] | Kluczowe dla bezpieczeństwa sesji |
| 1.1.5 | Brak pakietów z nieznanych źródeł (typosquatting) | [MANUAL] | Przejrzeć `package.json` przy każdym `npm install` od AI |

### 1.2. Supabase Security

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 1.2.1 | RLS włączone na wszystkich tabelach | [AUTO] | `SELECT tablename FROM pg_tables WHERE schemaname='public' AND rowsecurity=false` → powinno zwrócić 0 |
| 1.2.2 | Anon key nie ma uprawnień do `service_role` zasobów | [MANUAL] | Sprawdzić Supabase Dashboard → API → Permissions |
| 1.2.3 | Edge Functions walidują JWT przed każdą operacją | [MANUAL] | `supabase.auth.getUser()` w każdej Edge Function |
| 1.2.4 | Storage buckets – czy pliki prywatne mają RLS? | [MANUAL] | Sprawdzić Supabase Dashboard → Storage → Policies |
| 1.2.5 | Supabase DPA (Data Processing Agreement) podpisane | [MANUAL] | Dashboard → Settings → Legal |
| 1.2.6 | Region Supabase projektu: `eu-central-1` (Frankfurt) | [AUTO] | `supabase status` lub Dashboard → Settings → General |

### 1.3. Dane i storage

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 1.3.1 | `SecureStore` używany dla tokenów sesji (nie `AsyncStorage`) | [AUTO] | `grep -rn "AsyncStorage.setItem" src/lib/auth/` → powinno zwrócić 0 |
| 1.3.2 | Brak kluczy API w kodzie źródłowym | [AUTO] | `git log --all -p \| grep -E "eyJ[A-Za-z0-9]+"` → sprawdzić JWT leaks |
| 1.3.3 | `.env.production` w `.gitignore` i nie commitowany | [AUTO] | `git ls-files .env.production` → powinno zwrócić 0 |
| 1.3.4 | Personal notes – NIE wysyłane do serwera bez akcji użytkownika | [MANUAL] | Sprawdzić `src/lib/supabase/queries/` – notatki nie mają auto-sync |
| 1.3.5 | OCR: zdjęcie źródłowe NIE zapisywane na serwerze (tylko wynik tekstu) | [MANUAL] | Sprawdzić `src/lib/ocr/` i Edge Functions |

### 1.4. RODO / Dzieci

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 1.4.1 | Age gate działa dla użytkowników < 16 lat | [MANUAL] | Test manualny z `birth_year = current_year - 15` |
| 1.4.2 | Email consent wysyłany do rodzica (nie do dziecka) | [MANUAL] | Sprawdzić Edge Function i adres email |
| 1.4.3 | Konto `pending_consent` nie ma dostępu do żadnych danych klasy | [MANUAL] | Test RLS z JWT konta `pending_consent` |
| 1.4.4 | `delete-user-data` Edge Function anonimizuje wszystkie dane | [MANUAL] | Test: usunąć testowe konto, sprawdzić czy dane pozostały w DB |
| 1.4.5 | Polityka prywatności dostępna przed rejestracją (w app) | [MANUAL] | Sprawdzić `src/app/(auth)/register.tsx` – link do PP |
| 1.4.6 | Logi nie zawierają treści wiadomości użytkowników | [MANUAL] | Przejrzeć `logger.error/warn/info` w `src/lib/` i `src/hooks/` |

### 1.5. Moderacja – bezpieczeństwo dzieci

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 1.5.1 | Lista słów zabronionych zawiera wyrazy PL i EN | [MANUAL] | Sprawdzić `src/lib/moderation/wordlist.ts` |
| 1.5.2 | Lista słów aktualizowana – nie pochodzi z 2020 roku | [MANUAL] | Sprawdzić datę ostatniej aktualizacji w komentarzu |
| 1.5.3 | Admin klasy nie może zobaczyć treści wiadomości DM | [MANUAL] | Test: zalogować się jako admin, wejść w API bezpośrednio – RLS musi blokować |
| 1.5.4 | Odrzucone wiadomości NIE są dostępne przez API po odrzuceniu | [AUTO] | `SELECT * FROM messages WHERE moderation_status='rejected'` przez anon key → 0 wierszy |

---

## 2. SKALOWALNOŚĆ I WYDAJNOŚĆ

### 2.1. Supabase i baza danych

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 2.1.1 | Indeksy na wszystkich FK i kolumnach używanych w WHERE | [AUTO] | `\d+ messages` w psql – sprawdzić indeksy |
| 2.1.2 | Brak N+1 queries w hookach (jeden fetch zamiast pętla) | [MANUAL] | Sprawdzić `useMessages.ts` – czy pobiera wiadomości i załączniki razem |
| 2.1.3 | Paginacja wiadomości – nie pobierane wszystkie naraz | [MANUAL] | `limit(50).range()` w queries – sprawdzić |
| 2.1.4 | Realtime subscriptions: max 1 per kanał per komponent | [MANUAL] | Sprawdzić czy nie ma duplikatu subskrypcji przy re-renderze |
| 2.1.5 | Storage: kompresja obrazów przed uploadem (nie po) | [MANUAL] | Sprawdzić `src/lib/storage/compress.ts` |
| 2.1.6 | Storage: limit pliku sprawdzany po stronie klienta PRZED uplodem | [MANUAL] | Sprawdzić `src/lib/storage/upload.ts` |

### 2.2. Pamięć i React Native

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 2.2.1 | Subskrypcje Realtime czyszczone przy unmount | [AUTO] | `grep -rn "\.subscribe" src/hooks/ -A 20 \| grep "return () =>"` |
| 2.2.2 | `setInterval` / `setTimeout` czyszczone przy unmount | [AUTO] | `grep -rn "setInterval" src/ -A 10 \| grep "clearInterval"` |
| 2.2.3 | Tesseract.js (OCR, ~10 MB) ładowany leniwie | [MANUAL] | Sprawdzić `import()` dynamiczny w `src/lib/ocr/tesseract.ts` |
| 2.2.4 | FlatList używana zamiast ScrollView+map dla wiadomości | [MANUAL] | Sprawdzić `channel/[channelId].tsx` |
| 2.2.5 | `keyExtractor` unikalne i stabilne na listach | [MANUAL] | `keyExtractor={(item) => item.id}` – sprawdzić wszystkie FlatList |
| 2.2.6 | Zustand store nie przechowuje obrazów / blob (tylko URL) | [MANUAL] | Sprawdzić typy w `messageStore.ts` |

### 2.3. Limity i guardy

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 2.3.1 | `LIMITS.CLASS_STORAGE_FREE` sprawdzany przed każdym uploadem | [MANUAL] | Sprawdzić Edge Function `compress-attachment` |
| 2.3.2 | `LIMITS.VOICE_MAX_DURATION_FREE` egzekwowany w rekorderze | [MANUAL] | Sprawdzić `src/components/message/VoiceRecorder.tsx` |
| 2.3.3 | `LIMITS.MESSAGE_MAX_LENGTH` sprawdzany kliencko (+ walidacja Edge Function) | [MANUAL] | Obie strony muszą walidować |
| 2.3.4 | Historia wiadomości dla free: 90 dni – query z `created_at >= now() - interval '90 days'` | [MANUAL] | Sprawdzić query w `src/lib/supabase/queries/messages.ts` |

---

## 3. LOGOWANIE BŁĘDÓW I OBSERVABILITY

### 3.1. Logger — pokrycie

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 3.1.1 | Każdy `catch` blok w `src/lib/` ma `logger.error()` | [MANUAL] | `grep -rn "catch" src/lib/ -A 3 \| grep -L "logger"` |
| 3.1.2 | Każdy `catch` blok w `src/hooks/` ma `logger.error()` | [MANUAL] | Jak wyżej dla hooks |
| 3.1.3 | Edge Functions logują błędy przez `console.error` (Supabase zbiera logi) | [MANUAL] | Sprawdzić każdy `catch` w `supabase/functions/` |
| 3.1.4 | `logger.warn()` przy fallbackach (np. OCR.space po Tesseract fail) | [MANUAL] | Sprawdzić `src/lib/ocr/ocrspace.ts` |
| 3.1.5 | `logger.info()` przy kluczowych akcjach (send message, join class, approve member) | [MANUAL] | Pomocne przy debug – nie PII |

### 3.2. Sentry / błędy zdalne

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 3.2.1 | Sentry `beforeSend` usuwa PII (email, username) | [AUTO] | Sprawdzić `src/lib/errors/logger.ts` |
| 3.2.2 | `uncaughtException` i `unhandledRejection` przechwycone | [MANUAL] | Sprawdzić inicjalizację Sentry w `src/app/_layout.tsx` |
| 3.2.3 | Sentry environment: `development` vs `production` rozróżnione | [AUTO] | `environment: __DEV__ ? 'development' : 'production'` |
| 3.2.4 | Sentry retention: 90 dni (zgodne z RODO) | [MANUAL] | Sprawdzić ustawienia projektu Sentry |

### 3.3. Logi in-app (Settings → Logi)

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 3.3.1 | Sekcja logów w Settings pokazuje tylko `warn` i `error` (nie `debug`) | [MANUAL] | Sprawdzić filtr w `src/app/(main)/settings/index.tsx` |
| 3.3.2 | Logi in-app nie zawierają treści wiadomości | [MANUAL] | Przejrzeć co `logger.error` loguje jako `context` |
| 3.3.3 | Możliwość wysłania logów błędów do autora przez e-mail / Supabase endpoint | [MANUAL] | Sprawdzić przycisk "Wyślij raport błędu" w Settings |
| 3.3.4 | Logi in-app czyszczone po 30 dniach (rotacja) | [MANUAL] | Sprawdzić czy jest CRON lub threshold |

---

## 4. MODAŁY I UX BEZPIECZEŃSTWO

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 4.1 | Brak `window.alert`, `window.confirm`, `window.prompt` w całym kodzie | [AUTO] | `grep -rn "window\.alert\|window\.confirm\|window\.prompt" src/` → powinno zwrócić 0 |
| 4.2 | Brak `Alert.alert` z React Native (zamiast używamy własnych modali) | [AUTO] | `grep -rn "Alert\.alert" src/` → powinno zwrócić 0 |
| 4.3 | Każda akcja kasowania ma modal potwierdzenia | [MANUAL] | Sprawdzić: usunięcie wiadomości, usunięcie konta, opuszczenie klasy, odwołanie urządzenia |
| 4.4 | Modal potwierdzenia kasowania wymaga wpisania słowa/naciśnięcia przycisku (nie autoclose) | [MANUAL] | Sprawdzić `src/components/ui/Modal.tsx` – brak `autoClose` dla destructive actions |
| 4.5 | Destruktywne przyciski (`Usuń`, `Odrzuć`, `Zbanuj`) mają kolor `danger` (czerwony) | [MANUAL] | Sprawdzić użycie `variant="danger"` w komponentach Button |
| 4.6 | Modał kasowania informuje CO zostanie usunięte (nie tylko "Czy na pewno?") | [MANUAL] | Np. "Usuń wiadomość: 'Matematyka str. 45'?" (truncated) |

---

## 5. SORTOWANIE I FILTROWANIE

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 5.1 | Lista kanałów: domyślnie alfabetycznie, opcja: po aktywności (last message) | [MANUAL] | Sprawdzić `src/app/(main)/class/[classId]/index.tsx` |
| 5.2 | Lista członków klasy: domyślnie alfabetycznie, opcja: online first, rola (admin first) | [MANUAL] | Sprawdzić `src/app/(main)/class/[classId]/members.tsx` |
| 5.3 | Lista klas na home: domyślnie ostatnia aktywność, opcja: alfabetycznie | [MANUAL] | Sprawdzić `src/app/(main)/index.tsx` |
| 5.4 | Lista notatek: domyślnie `updated_at` DESC, opcja: alfabetycznie, po klasie/przedmiocie | [MANUAL] | Sprawdzić `src/app/(main)/notes/index.tsx` |
| 5.5 | Lista DM: domyślnie ostatnia wiadomość, nieodczytane na górze | [MANUAL] | Sprawdzić `src/app/(main)/dm/` |
| 5.6 | Sortowanie persystowane w user settings (nie resetuje się po restarcie) | [MANUAL] | Sprawdzić `settings` JSONB w profilu – klucze sortowania |
| 5.7 | Filtr "Nieodczytane" dostępny dla kanałów i DM | [MANUAL] | Sprawdzić UI – badge + filtr |
| 5.8 | Wyszukiwarka wiadomości – czy działa full-text search przez Supabase? | [MANUAL] | `to_tsvector` na `messages.content` – sprawdzić migrację |

---

## 6. PRZYPOMNIENIA (REMINDERS)

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 6.1 | Tabela `reminders` istnieje w schemacie DB | [AUTO] | `\dt reminders` w psql |
| 6.2 | Reminder można powiązać z klasą, kanałem lub wątkiem | [MANUAL] | Sprawdzić kolumny FK w tabeli `reminders` |
| 6.3 | Przypomnienie wyzwala push notification o wybranej godzinie | [MANUAL] | Sprawdzić Edge Function `send-push-notification` – czy obsługuje typ `reminder` |
| 6.4 | Przypomnienia widoczne w Settings / dedykowanym widoku | [MANUAL] | Sprawdzić routing – gdzie jest lista reminderów |
| 6.5 | Usunięcie reminderu wymaga potwierdzenia modalem | [MANUAL] | Standardowa zasada – żadne kasowanie bez potwierdzenia |
| 6.6 | Reminder nie wysyła powiadomienia jeśli kanał/klasa wyciszona | [MANUAL] | Sprawdzić logikę w `send-push-notification` |

---

## 7. DEVOPS I PROCESY

### 7.1. CI/CD

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 7.1.1 | GitHub Actions: `tsc --noEmit` uruchamiane na każdym PR | [AUTO] | Sprawdzić `.github/workflows/ci.yml` |
| 7.1.2 | GitHub Actions: `npm test` (Jest) uruchamiane na każdym PR | [AUTO] | Sprawdzić pipeline |
| 7.1.3 | GitHub Actions: `deno test` dla Edge Functions | [AUTO] | Sprawdzić pipeline |
| 7.1.4 | GitHub Actions: `npm audit` blokuje przy `high`/`critical` | [MANUAL] | Dodać `npm audit --audit-level=high` do pipeline |
| 7.1.5 | Środowisko `production` oddzielone od `development` (osobny projekt Supabase) | [MANUAL] | Sprawdzić czy dev i prod mają osobne URL/klucze |

### 7.2. Dokumentacja

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 7.2.1 | `docs/` aktualne względem kodu (np. schema DB zgodna z migracjami) | [MANUAL] | Porównać `01_ARCHITECTURE.md` z rzeczywistymi migracjami |
| 7.2.2 | `UI_UX_MOCKUP.html` zaktualizowany po tym sprincie | [MANUAL] | Sprawdzić datę ostatniej modyfikacji |
| 7.2.3 | `CHANGELOG.md` uzupełniony o zmiany w tym PR | [MANUAL] | Format: Keep a Changelog |
| 7.2.4 | `README.md` zawiera aktualną instrukcję uruchomienia | [MANUAL] | `npm install` → Supabase setup → `npx expo start` |

---

## 8. ZGODNOŚĆ Z PRAWEM (COMPLIANCE)

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 8.1 | App Store / Google Play privacy questionnaire aktualny | [MANUAL] | Przy każdej nowej kategorii zbieranych danych |
| 8.2 | Polityka prywatności zaktualizowana przy nowych danych / funkcjach | [MANUAL] | Np. backup do Drive wymaga nowej sekcji w PP |
| 8.3 | Cookie / local storage notice na wersji web/PWA | [MANUAL] | Sprawdzić `src/app/_layout.tsx` – baner przy pierwszym uruchomieniu web |
| 8.4 | AdMob skonfigurowany jako child-directed (NPA) dla free tier | [MANUAL] | Sprawdzić `tagForChildDirectedTreatment: true` w konfiguracji |
| 8.5 | Wszystkie zewnętrzne usługi mają DPA (Supabase, Sentry, RevenueCat) | [MANUAL] | Lista w `05_LEGAL_COMPLIANCE.md` sekcja 7 |

---

## 9. DOJRZAŁOŚĆ PRODUKTOWA

| # | Sprawdzenie | Typ | Uwagi |
|---|-------------|-----|-------|
| 9.1 | Onboarding: 4 slajdy działają, "Pomiń" działa | [MANUAL] | Test manualny na fresh install |
| 9.2 | Splash screen wyświetla się i znika po 2s | [MANUAL] | Test manualny |
| 9.3 | Tryb offline: komunikat "Brak połączenia" zamiast crasha | [MANUAL] | Test: włączyć airplane mode, spróbować wysłać wiadomość |
| 9.4 | Debug panel niedostępny w production build | [AUTO] | Build `--variant production` i sprawdzić czy widoczna zakładka 🐛 |
| 9.5 | Ikona aplikacji ustawiona (wszystkie rozmiary) | [MANUAL] | `assets/icons/` – sprawdzić czy jest `icon.png` 1024x1024 |
| 9.6 | Nazwa aplikacji w nagłówku systemu zgodna z finalną nazwą projektu | [MANUAL] | Sprawdzić `app.config.ts` → `name` i `slug` |

---

## 10. RYZYKA I MITYGACJA — PODSUMOWANIE

| # | Ryzyko | Prawdop. | Wpływ | Status | Mitygacja |
|---|--------|----------|-------|--------|-----------|
| 1 | Wyciek danych dzieci przez błędne RLS | Niskie | Krytyczny | Monitorować | Testy RLS przy każdej migracji |
| 2 | Moderacja ominięta przez manipulację payload | Niskie | Wysoki | Zabezpieczone | JWT walidacja w Edge Function |
| 3 | Supabase poza EU (zmiana regionu) | Bardzo niskie | Wysoki | Zabezpieczone | Frankfurt – sprawdzać przy upgrade |
| 4 | OCR.space API niedostępne (fallback fail) | Średnie | Niski | Akceptowalne | Tesseract.js jako primary (offline) |
| 5 | Brak migracji settings przy nowej strukturze | Średnie | Średni | BACKLOG | Dodać `settings_version` + migrator |
| 6 | Logi in-app zawierają PII przez pomyłkę | Średnie | Wysoki | Monitorować | Code review każdego `logger.error` |
| 7 | RevenueCat webhook opóźniony → błędne uprawnienia | Niskie | Średni | Akceptowalne | Retry + Zustand sync przy foreground |
| 8 | Zbyt duże Zustand store w pamięci (duże klasy) | Niskie | Średni | BACKLOG | Paginacja + wirtualizacja list |
| 9 | Brak testów E2E – regresja niezauważona | Wysokie | Średni | BACKLOG | Playwright po MVP |
| 10 | AdMob odrzucenie aplikacji (children policy) | Średnie | Wysoki | Monitorować | Child-directed NPA od dnia 1 |

---

## 🔚 WYNIK AUDYTU

> Skopiuj poniższą tabelę i zapisz do `logs/YYYY-MM-DD_audit.md`

```markdown
# Audyt Projektu — YYYY-MM-DD
## Wersja: [x.y.z] | Faza: [1/2/3] | Audytor: [imię/model AI]

| Obszar | Punkty | ✅ OK | ⚠️ Do poprawy | ❌ Blokuje release | BACKLOG | N/D |
|--------|--------|-------|--------------|-------------------|---------|-----|
| 1. Bezpieczeństwo głębokie | 21 | | | | | |
| 2. Skalowalność i wydajność | 13 | | | | | |
| 3. Logowanie i observability | 12 | | | | | |
| 4. Modały i UX bezpieczeństwo | 6 | | | | | |
| 5. Sortowanie i filtrowanie | 8 | | | | | |
| 6. Przypomnienia | 6 | | | | | |
| 7. DevOps i procesy | 9 | | | | | |
| 8. Compliance | 5 | | | | | |
| 9. Dojrzałość produktowa | 6 | | | | | |
| **RAZEM** | **86** | | | | | |

## Blokujące release (❌):
- [ ] ...

## Do poprawy przed następnym sprintem (⚠️):
- [ ] ...

## Ryzyka aktywne:
- [ ] ...

## Decyzja: [ ] Release OK  [ ] Release po poprawkach  [ ] Release zablokowany
```
