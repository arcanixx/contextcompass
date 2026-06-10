# 11 — User Stories & Acceptance Criteria
# Path: docs/11_user_stories_and_ac.md
# Purpose: Testowalne historyjki użytkownika z Acceptance Criteria per MVP feature
# Depends on: docs/00_PROJECT_OVERVIEW.md, docs/01_ARCHITECTURE.md, docs/06_FEATURES_SPEC.md
# Status: MVP v0.1 (Phase 1)

---

# KlassMate — User Stories & Acceptance Criteria (MVP v0.1)

> **Wersja:** 0.1.0-draft  
> **Ostatnia aktualizacja:** 2025-06-11  
> **Zakres:** Phase 1 (Foundation) — wszystko oznaczone `[P0]` musi być zaimplementowane przed pierwszym beta testem.

---

## Legenda priorytetów

| Oznaczenie | Znaczenie | Kiedy implementować |
|------------|-----------|-------------------|
| `[P0]` | Must have — blokuje wydanie MVP | Sprint 1–2 |
| `[P1]` | Should have — znacząco poprawia UX | Sprint 3 (jeśli czas) |
| `[P2]` | Nice to have — może poczekać do Phase 2 | Phase 2 |
| `[2FA]` | Wymaga konfiguracji 2FA (TOTP) — dotyczy tylko adminów w MVP | Sprint 2 |

---

## US-01: Rejestracja i logowanie

**Jako** uczeń lub nauczyciel  
**Chcę** założyć konto i zalogować się  
**Żeby** móc korzystać z aplikacji

### Acceptance Criteria — Rejestracja
- [ ] `[P0]` Użytkownik może zarejestrować się przez email + hasło (min. 8 znaków, 1 wielka litera, 1 cyfra).
- [ ] `[P0]` Po rejestracji wysyłany jest email weryfikacyjny — konto jest nieaktywne do czasu kliknięcia linku.
- [ ] `[P0]` Formularz rejestracji zawiera pole `birth_year` (rok urodzenia, nie pełna data) — wymagane do oceny wieku.
- [ ] `[P0]` Jeśli `current_year - birth_year < 16` — wymagana zgoda rodzica (email z linkiem) przed aktywacją konta.
- [ ] `[P0]` Konto w stanie `pending_consent` nie może logować się do aplikacji (pokazuje ekran oczekiwania).
- [ ] `[P0]` Rejestracja przez Google OAuth (opcjonalna, ale gotowa w MVP).
- [ ] `[P1]` Rejestracja przez Apple OAuth (iOS only).
- [ ] `[P1]` Wskaźnik siły hasła (słabe / średnie / mocne) w czasie rzeczywistym.
- [ ] `[P2]` Logowanie przez magic link (zamiast hasła).

### Acceptance Criteria — Logowanie
- [ ] `[P0]` Logowanie przez email + hasło.
- [ ] `[P0]` Opcja „Zapamiętaj mnie” — sesja ważna 30 dni na zaufanym urządzeniu.
- [ ] `[P0]` Wylogowanie po 4h bezczynności na **niezaufanym** urządzeniu.
- [ ] `[P0]` Przy pierwszym logowaniu na nowym urządzeniu — ekran „Czy to Twoje urządzenie?” (trust / no-trust).
- [ ] `[P0]` Przy logowaniu na niezaufanym urządzeniu — brak biometrii, 4h timeout aktywny.
- [ ] `[P1]` Biometryczne odblokowanie (Face ID / Touch ID / Fingerprint) oferowane po pierwszym udanym logowaniu.
- [ ] `[P1]` Przy 3 nieudanych próbach biometrii — fallback do hasła.
- [ ] `[2FA]` Dla kont z rolą `admin` w klasie — wymuszona konfiguracja 2FA (TOTP) przed uzyskaniem uprawnień admina.

---

## US-02: Onboarding (pierwsze uruchomienie)

**Jako** nowy użytkownik  
**Chcę** zobaczyć krótkie wprowadzenie do aplikacji  
**Żeby** wiedzieć, jak działa KlassMate

### Acceptance Criteria
- [ ] `[P0]` 4 slajdy onboarding (splash → kanały → moderacja → notatki), przesuwane palcem, z przyciskiem „Pomiń”.
- [ ] `[P0]` Onboarding wyświetlany tylko raz — flaga zapisana w `SecureStore`.
- [ ] `[P0]` Po onboarding (lub pominięciu) — przekierowanie do ekranu głównego (lista klas) lub tworzenia klasy, jeśli użytkownik nie należy do żadnej.
- [ ] `[P1]` Tooltipy kontekstowe przy pierwszej interakcji z elementem UI (trackowane w `profiles.settings.seen_tooltips`).

---

## US-03: Tworzenie i dołączanie do klasy

**Jako** uczeń  
**Chcę** utworzyć klasę lub dołączyć do istniejącej  
**Żeby** komunikować się z kolegami z klasy

### Acceptance Criteria — Tworzenie klasy
- [ ] `[P0]` Użytkownik może utworzyć klasę z nazwą (2–100 znaków), opcjonalną nazwą szkoły i rokiem szkolnym (np. „2025/2026”).
- [ ] `[P0]` System generuje unikalny kod zaproszenia (6 znaków alfanumerycznych, np. `KM-4F2X`).
- [ ] `[P0]` Twórca klasy automatycznie staje się `admin` w `class_members`.
- [ ] `[P0]` Admin może regenerować kod zaproszenia (stary natychmiast unieważniany).
- [ ] `[P0]` Admin może ustawić: czy dołączenie wymaga akceptacji admina (domyślnie: tak).
- [ ] `[P1]` Admin może edytować nazwę klasy, nazwę szkoły, rok szkolny.
- [ ] `[P1]` Admin może archiwizować klasę (zamrożenie — tylko odczyt, brak nowych wiadomości).
- [ ] `[P2]` Admin może ustawić limit członków klasy.

### Acceptance Criteria — Dołączanie do klasy
- [ ] `[P0]` Użytkownik może dołączyć przez wpisanie kodu zaproszenia.
- [ ] `[P0]` Jeśli klasa wymaga akceptacji — użytkownik trafia do `class_members` ze statusem `pending`.
- [ ] `[P0]` Jeśli klasa NIE wymaga akceptacji — użytkownik od razu ma status `approved`.
- [ ] `[P0]` Użytkownik widzi listę swoich klas na ekranie głównym.
- [ ] `[P0]` Użytkownik może opuścić klasę (z potwierdzeniem w modalu destructive).

---

## US-04: Zarządzanie członkami klasy (Admin)

**Jako** admin klasy  
**Chcę** zatwierdzać, odrzucać lub usuwać uczniów  
**Żeby** mieć kontrolę nad tym, kto jest w klasie

### Acceptance Criteria
- [ ] `[P0]` Admin widzi listę oczekujących (`pending`) w sekcji „Prośby o dołączenie”.
- [ ] `[P0]` Admin może zatwierdzić — status zmienia się na `approved`, użytkownik dostaje powiadomienie push.
- [ ] `[P0]` Admin może odrzucić — status `rejected`, użytkownik dostaje powiadomienie push.
- [ ] `[P0]` Admin może usunąć (ban) zatwierdzonego członka — status `banned`, nie może dołączyć ponownie bez nowej akceptacji.
- [ ] `[P0]` Admin widzi pełną listę członków z rolami i statusami.
- [ ] `[P1]` Admin może mianować innego członka na admina (wymaga potwierdzenia w modalu).
- [ ] `[P1]` Admin może degradować admina do zwykłego członka.
- [ ] `[P2]` Admin może zobaczyć datę dołączenia każdego członka.

---

## US-05: Kanały przedmiotowe

**Jako** członek klasy  
**Chcę** widzieć kanały przypisane do przedmiotów  
**Żeby** wiedzieć, gdzie napisać o danym zadaniu

### Acceptance Criteria
- [ ] `[P0]` Każda klasa ma domyślny kanał „Ogłoszenia” (tworzony automatycznie przy tworzeniu klasy).
- [ ] `[P0]` Admin może tworzyć kanały (nazwa 1–80 znaków, opcjonalny opis, emoji przedmiotu).
- [ ] `[P0]` Kanały wyświetlane w sidebarze w określonej kolejności (`position`).
- [ ] `[P0]` Admin może edytować nazwę, opis, emoji i kolejność kanałów.
- [ ] `[P0]` Admin może archiwizować kanał (read-only, widoczny w sekcji „Archiwum”).
- [ ] `[P1]` Użytkownik może wyciszyć kanał (brak powiadomień push, ale wiadomości widoczne).
- [ ] `[P1]` Użytkownik może przypiąć kanał (wyświetlany na górze listy).
- [ ] `[P2]` Użytkownik może sortować kanały: alfabetycznie, ostatnia aktywność, nieodczytane na górze.

---

## US-06: Wysyłanie i przeglądanie wiadomości w kanale

**Jako** członek klasy  
**Chcę** pisać i czytać wiadomości w kanałach  
**Żeby** wymieniać informacje o zadaniach domowych

### Acceptance Criteria — Wysyłanie
- [ ] `[P0]` Użytkownik może wysłać wiadomość tekstową (max 2000 znaków, licznik widoczny).
- [ ] `[P0]` Pusta wiadomość lub same białe znaki — przycisk „Wyślij” zablokowany.
- [ ] `[P0]` Każda wiadomość przed zapisem do DB przechodzi przez Edge Function `moderate-message`.
- [ ] `[P0]` Jeśli moderacja = `approve` — wiadomość zapisana, broadcast przez Realtime.
- [ ] `[P0]` Jeśli moderacja = `review` — wiadomość zapisana ze statusem `queued_review`, NIE broadcastowana, admin dostaje powiadomienie.
- [ ] `[P0]` Jeśli moderacja = `reject` — wiadomość NIE zapisywana, użytkownik widzi toast „Wiadomość narusza zasady”.
- [ ] `[P0]` Optymistyczna aktualizacja UI — wiadomość pojawia się natychmiast (dimmed + spinner), potwierdzana / cofana po odpowiedzi serwera.
- [ ] `[P0]` Offline: wiadomość trafia do kolejki lokalnej, wysyłana po reconnect.
- [ ] `[P1]` Wzmianka `@nazwa_użytkownika` — podświetlona, powiadomienie push dla wspomnianego.
- [ ] `[P1]` Odpowiedź w wątku (long press → „Odpowiedz w wątku”).
- [ ] `[P2]` Wiadomość głosowa (nagrywanie, odtwarzanie, waveform).
- [ ] `[P2]` Załącznik obrazka (kompresja, max 5 MB).

### Acceptance Criteria — Przeglądanie
- [ ] `[P0]` Użytkownik widzi wiadomości tylko z klas, do których należy ze statusem `approved`.
- [ ] `[P0]` Wiadomości z `moderation_status = 'approved'` lub `'trimmed'` są widoczne.
- [ ] `[P0]` Wiadomości z `deleted_at IS NOT NULL` są ukryte.
- [ ] `[P0]` Wiadomości ładowane z paginacją (cursor-based, 50 na stronę, infinite scroll).
- [ ] `[P0]` Własne wiadomości: wyrównane do prawej, kolor primary. Cudze: do lewej, avatar + nazwa.
- [ ] `[P0]` Long press na wiadomość → menu: Kopiuj tekst / Zgłoś / Usuń (tylko własne, soft delete).
- [ ] `[P1]` Auto-oznaczanie kanału jako przeczytany po 2s bez przewijania + scroll do końca.
- [ ] `[P1]` Wyszukiwanie w kanale (full-text search po `content`).

---

## US-07: Moderacja treści (Admin)

**Jako** admin klasy  
**Chcę** zatwierdzać, odrzucać lub przycinać wiadomości w kolejce  
**Żeby** utrzymać bezpieczne środowisko

### Acceptance Criteria — Kolejka moderacji
- [ ] `[P0]` Admin widzi ikonę tarczy z czerwonym badge'm (liczba oczekujących) w sidebarze.
- [ ] `[P0]` Lista wiadomości w kolejce: nadawca, kanał, treść (3 linie), powód flagi, pewność AI.
- [ ] `[P0]` Admin może „Zatwierdź” — `moderation_status` = `approved`, broadcast do kanału.
- [ ] `[P0]` Admin może „Odrzucić” — `moderation_status` = `rejected`, nadawca dostaje powiadomienie.
- [ ] `[P0]` Admin może „Przytnij” — zaznacza fragment do usunięcia, podgląd przyciętej wersji, zatwierdza. `moderation_status` = `trimmed`, oryginał zachowany w `original_content`.
- [ ] `[P0]` Nadawca przyciętej wiadomości dostaje toast: „Fragment Twojej wiadomości został usunięty przez moderatora”.
- [ ] `[P0]` Admin NIE może edytować treści wiadomości (tylko usuwać fragmenty).
- [ ] `[P0]` Admin NIE widzi treści DM (moderacja DM jest automatyczna).
- [ ] `[P1]` Filtracja kolejki: wszystkie / tylko zgłoszone przez użytkowników / tylko AI-flagged.
- [ ] `[P1]` Sortowanie kolejki: data wpłynięcia / pewność AI malejąco.

---

## US-08: Powiadomienia push i in-app

**Jako** użytkownik  
**Chcę** dostawać powiadomienia o nowych wiadomościach, wzmiankach i moderacji  
**Żeby** niczego nie przegapić

### Acceptance Criteria
- [ ] `[P0]` Powiadomienie push przy nowej wiadomości w kanale (jeśli użytkownik nie wyciszył kanału/klasy).
- [ ] `[P0]` Powiadomienie push przy @wzmiance — zawsze, chyba że globalnie wyłączone.
- [ ] `[P0]` Powiadomienie push dla admina przy nowej wiadomości w kolejce moderacji.
- [ ] `[P0]` Powiadomienie push przy zatwierdzeniu / odrzuceniu prośby o dołączenie.
- [ ] `[P0]` In-app badge na ikonie dzwonka (liczba nieprzeczytanych powiadomień).
- [ ] `[P0]` In-app toast gdy aplikacja jest otwarta i nadejdzie nowa wiadomość.
- [ ] `[P0]` Kliknięcie powiadomienia (push lub in-app) → deep link do odpowiedniego kanału / DM / ekranu moderacji.
- [ ] `[P0]` Uprawnienia push proszone w kontekście (po dołączeniu do pierwszej klasy), NIE przy starcie aplikacji.
- [ ] `[P0]` Jeśli użytkownik odmówi uprawnień systemowych — nie ponownie prosi przez 7 dni.
- [ ] `[P1]` Ciche godziny (konfigurowalne od–do) — push wyciszony, ale in-app badge nadal działa.
- [ ] `[P1]` Podgląd powiadomienia na ekranie blokady — domyślnie OFF (prywatność).
- [ ] `[P2]` Powiadomienie o wygasającej sesji (30 min przed timeout na niezaufanym urządzeniu).

---

## US-09: Wiadomości prywatne (DM)

**Jako** członek klasy  
**Chcę** pisać prywatne wiadomości do innego członka tej samej klasy  
**Żeby** zapytać o coś bez rozgłosu

### Acceptance Criteria
- [ ] `[P0]` DM dostępne tylko między `approved` członkami tej samej klasy.
- [ ] `[P0]` Tworzenie DM: wybór z listy członków klasy (bez adminów jako osobna kategoria).
- [ ] `[P0]` DM zawiera tylko tekst i wiadomości głosowe (brak obrazków — ochrona prywatności).
- [ ] `[P0]` Każda DM przechodzi przez ten sam Edge Function moderacji, ale wynik jest automatyczny (reject / allow). Brak kolejki do admina.
- [ ] `[P0]` Użytkownik może zablokować drugą stronę — bilateral block, obaj przestają widzieć wiadomości.
- [ ] `[P0]` Zablokowanie wymaga potwierdzenia w modalu destructive.
- [ ] `[P0]` Lista zablokowanych użytkowników w Ustawieniach → Prywatność.
- [ ] `[P1]` Powiadomienie push przy nowej DM (jeśli włączone).
- [ ] `[P1]` Oznaczanie DM jako przeczytane.
- [ ] `[P2]` Raportowanie DM do superadmina (anonymised, hash treści).

---

## US-10: Notatki osobiste (z OCR)

**Jako** uczeń  
**Chcę** tworzyć prywatne notatki i skanować zdjęcia zeszytu do tekstu  
**Żeby** zapisywać swoje uwagi

### Acceptance Criteria
- [ ] `[P0]` Widok „Moje notatki” dostępny z głównego ekranu / bottom tab.
- [ ] `[P0]` Tworzenie notatki: tytuł (opcjonalny), treść (rich text: bold, italic, listy).
- [ ] `[P0]` Notatki prywatne — nawet admin/nauczyciel nie ma do nich dostępu.
- [ ] `[P0]` Notatka może być powiązana z klasą / kanałem (opcjonalnie, dla kontekstu).
- [ ] `[P0]` OCR: użytkownik robi zdjęcie strony z zeszytu → Tesseract.js (client-side) rozpoznaje tekst.
- [ ] `[P0]` OCR result jest edytowalny przed zapisem — użytkownik widzi ekran „Sprawdź i popraw tekst”.
- [ ] `[P0]` Zdjęcie źródłowe NIE jest przechowywane na serwerze — tylko wyekstraktowany tekst.
- [ ] `[P0]` Fallback OCR: jeśli Tesseract zawiedzie → OCR.space API (Edge Function proxy).
- [ ] `[P1]` Wyszukiwanie notatek po treści.
- [ ] `[P1]` Sortowanie: data edycji ↓, alfabetycznie, według przedmiotu.
- [ ] `[P2]` Eksport notatki do clipboard / share sheet.

---

## US-11: Ustawienia i personalizacja

**Jako** użytkownik  
**Chcę** zarządzać swoim kontem, powiadomieniami i wyglądem aplikacji  
**Żeby** dostosować aplikację do siebie

### Acceptance Criteria — Konto
- [ ] `[P0]` Edycja nazwy wyświetlanej (2–50 znaków) i avatara (upload zdjęcia, kompresja).
- [ ] `[P0]` Zmiana hasła (wymaga bieżącego hasła lub biometrii).
- [ ] `[P0]` Zmiana emaila (wymaga weryfikacji nowego adresu).
- [ ] `[P0]` Usunięcie konta — modal destructive, wymaga biometrii/hasła, Edge Function `delete-user-data`.
- [ ] `[P0]` Eksport danych (RODO: prawo dostępu) — generuje JSON z profilu, klas, wiadomości, notatek.

### Acceptance Criteria — Powiadomienia
- [ ] `[P0]` Master toggle ON/OFF dla push.
- [ ] `[P0]` Per-klasa: wyciszenie całej klasy.
- [ ] `[P0]` Per-kanał: tryb „Wszystkie” / „Tylko wzmianki” / „Wyłączone”.
- [ ] `[P0]` DM: toggle ON/OFF.
- [ ] `[P0]` Dźwięki i wibracje: toggles.
- [ ] `[P1]` Ciche godziny: time pickery od–do.
- [ ] `[P1]` Podgląd na ekranie blokady: toggle (domyślnie OFF).

### Acceptance Criteria — Wygląd
- [ ] `[P0]` Tryb jasny / ciemny / systemowy (sync z `prefers-color-scheme`).
- [ ] `[P0]` Wszystkie komponenty obsługują oba motywy (NativeWind `dark:` prefixes).
- [ ] `[P1]` Custom theme colour (premium-only, Phase 3).

### Acceptance Criteria — Urządzenia zaufane
- [ ] `[P0]` Lista zarejestrowanych urządzeń (nazwa, system, ostatnie logowanie).
- [ ] `[P0]` Odwołanie zaufanego urządzenia — wymaga biometrii, natychmiastowe unieważnienie sesji.
- [ ] `[P0]` Przy odwołaniu — urządzenie wylogowane przy następnym foreground check.

---

## US-12: Tryb offline i synchronizacja

**Jako** użytkownik z słabym zasięgiem  
**Chcę** pisać wiadomości bez internetu  
**Żeby** nie być zależnym od połączenia

### Acceptance Criteria
- [ ] `[P0]` Wykrywanie stanu sieci (NetInfo) — banner „Brak połączenia” na górze ekranu.
- [ ] `[P0]` Wiadomość napisana offline trafia do `offlineQueue` w Zustand + `SecureStore`.
- [ ] `[P0]` Po reconnect — automatyczne wysyłanie kolejki (flush) w kolejności FIFO.
- [ ] `[P0]` Jeśli wysyłka z kolejki zawiedzie — pozostaje w kolejce, retry przy następnym reconnect.
- [ ] `[P0]` Max 20 wiadomości w offline queue (żeby nie przepełnić SecureStore).
- [ ] `[P0]` Odczyt wiadomości działa offline (cache z Supabase Realtime / ostatni fetch).
- [ ] `[P1]` Paginacja historycznych wiadomości działa offline (cache lokalny).
- [ ] `[P2]` Pełny sync dwukierunkowy (serwer → klient przy reconnect).

---

## US-13: Backup i eksport danych

**Jako** użytkownik  
**Chcę** zrobić kopię zapasową swoich danych  
**Żeby** nie stracić pracy w razie awarii

### Acceptance Criteria
- [ ] `[P0]` Ręczny eksport JSON (Settings → Konto → „Pobierz swoje dane”) — zawiera profil, klasy, wiadomości, notatki.
- [ ] `[P0]` Eksport generowany przez Edge Function `export-backup` — link ważny 1h.
- [ ] `[P1]` Eksport do ZIP z czytelnym README.txt.
- [ ] `[P2]` Auto-backup do Google Drive (Phase 2, premium-only).
- [ ] `[P2]` Auto-backup do iCloud (Phase 2, iOS premium-only).

---

## US-14: Logi aplikacji i raportowanie błędów

**Jako** użytkownik  
**Chcę** zobaczyć logi błędów i wysłać raport do autora  
**Żeby** pomóc w naprawie problemu

### Acceptance Criteria
- [ ] `[P0]` Logi `warn` / `error` / `critical` zapisywane lokalnie w `SecureStore` (max 100 wpisów, FIFO).
- [ ] `[P0]` Widok logów w Settings → „Logi aplikacji” — czytelna lista z poziomami i timestampami.
- [ ] `[P0]` Przycisk „Wyślij raport do autora” — wymaga potwierdzenia modal info.
- [ ] `[P0]` Raport wysyłany przez Edge Function `report-error` — zawiera kody błędów, platformę, wersję app, ostatnie 10 breadcrumbs (bez PII).
- [ ] `[P0]` User ID haszowany SHA-256 w raporcie (RODO-safe).
- [ ] `[P1]` W trybie DEV — dodatkowy ekran debug z mockami, seed data, resetami.

---

## US-15: Analityka (privacy-first)

**Jako** właściciel aplikacji  
**Chcę** zbierać zagregowane statystyki  
**Żeby** rozumieć użycie bez naruszania prywatności

### Acceptance Criteria
- [ ] `[P0]` Tylko zagregowane dane (liczby, nie treści).
- [ ] `[P0]` Eventy: `app_open`, `class_created`, `channel_message_sent`, `dm_sent`, `member_approved`, `moderation_decision`, `backup_exported`, `account_deleted`.
- [ ] `[P0]` Brak trackingu indywidualnych użytkowników (nie ma user_id w eventach analitycznych).
- [ ] `[P0]` Użytkownik może wyłączyć analitykę w Settings → Prywatność.
- [ ] `[P1]` Funnel: onboarding completion rate, class creation → first message time.
- [ ] `[P1]` Retention: D1, D7, D30 (anonimowo, na podstawie `app_open` events).

---

## Definition of Done (DoD) — obowiązuje każdy US

Przed oznaczeniem US jako „done”:

- [ ] Kod napisany zgodnie z `02_CODE_STANDARDS.md` (file header, <200 linii, no `any`, i18n).
- [ ] Unit testy dla nowych funkcji w `src/utils/` i `src/lib/` (min. 1 test per public function).
- [ ] Integration test dla nowych zapytań Supabase w `__tests__/integration/queries/`.
- [ ] Component test dla nowych komponentów UI w `__tests__/components/`.
- [ ] Edge Function test w `supabase/functions/__tests__/` (jeśli dotyczy).
- [ ] Acceptance Criteria spełnione — przetestowane manualnie na iOS Simulator + Android Emulator + Web.
- [ ] RLS policies napisane i przetestowane dla każdej nowej tabeli.
- [ ] i18n keys dodane do `pl.json` i `en.json`.
- [ ] Toast / error handling / empty states / loading states zaimplementowane.
- [ ] Accessibility labels (`accessibilityLabel`, `accessibilityHint`) na interaktywnych elementach.
- [ ] Dokumentacja zaktualizowana (jeśli US zmienia architekturę lub flow).
- [ ] Brak `console.log` w kodzie produkcyjnym (tylko `logger.debug()` w DEV).
- [ ] CI przechodzi (typecheck, lint, test:unit, test:components).

---

## Mapowanie US → Phase (Roadmap)

| US | Phase 1 (MVP) | Phase 2 | Phase 3 |
|----|---------------|---------|---------|
| US-01 (Auth) | ✅ P0 | 2FA dla memberów | — |
| US-02 (Onboarding) | ✅ P0 | Tooltipy kontekstowe | — |
| US-03 (Klasy) | ✅ P0 | Archiwizacja, limity | — |
| US-04 (Członkowie) | ✅ P0 | Promocja/degradacja | — |
| US-05 (Kanały) | ✅ P0 | Wyciszenie, przypięcie | Sortowanie |
| US-06 (Wiadomości) | ✅ P0 (tekst) | Wątki, wzmianki | Głos, obrazki |
| US-07 (Moderacja) | ✅ P0 | Filtry kolejki | — |
| US-08 (Powiadomienia) | ✅ P0 | Ciche godziny | Sesja expiring |
| US-09 (DM) | ❌ — Phase 2 | ✅ P0 Phase 2 | Raportowanie |
| US-10 (Notatki + OCR) | ❌ — Phase 2 | ✅ P0 Phase 2 | Eksport |
| US-11 (Ustawienia) | ✅ P0 (konto, theme, notif) | Custom colour | — |
| US-12 (Offline) | ✅ P0 | Paginacja offline | Full sync |
| US-13 (Backup) | ✅ P0 (JSON) | ZIP, Google Drive | iCloud |
| US-14 (Logi) | ✅ P0 | Debug panel | — |
| US-15 (Analityka) | ✅ P0 (aggregated) | Funnel, retention | — |
