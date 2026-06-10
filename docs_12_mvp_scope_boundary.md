# 12 — MVP Scope Boundary
# Path: docs/12_mvp_scope_boundary.md
# Purpose: Jasne określenie co wchodzi w v0.1 (MVP), a co jest celowo poza zakresem
# Depends on: docs/00_PROJECT_OVERVIEW.md, docs/11_user_stories_and_ac.md
# Status: MVP v0.1 (Phase 1 — Foundation)

---

# KlassMate — MVP Scope Boundary (v0.1)

> **Wersja:** 0.1.0-draft  
> **Ostatnia aktualizacja:** 2025-06-11  
> **Cel:** Zapobieganie scope creep. Każda funkcja spoza tej listy wymaga osobnej decyzji product ownera i aktualizacji tego dokumentu.

---

## 1. Filozofia MVP

MVP (Minimum Viable Product) dla KlassMate to **jedna klasa, 5–10 uczniów, 4 tygodnie użytkowania bez incydentów bezpieczeństwa**. Wszystko, co nie jest absolutnie niezbędne do osiągnięcia tego celu, jest celowo wyłączone z Phase 1.

**Złota zasada:** Lepiej zrobić 10 funkcji perfekcyjnie niż 30 funkcji średnio.

---

## 2. ✅ W ZAKRESIE MVP (Must Have — Phase 1)

### 2.1 Backend (Supabase)

| # | Funkcja | Uzasadnienie |
|---|---------|--------------|
| 1 | Autoryzacja email + hasło + weryfikacja email | Podstawa — bez tego nie ma użytkowników |
| 2 | Google OAuth (rejestracja / logowanie) | Redukcja friction, alternatywa dla hasła |
| 3 | Profile użytkowników (display_name, avatar, birth_year, role) | RODO age gate, identyfikacja w klasie |
| 4 | Parental consent flow (email link) dla <16 lat | Wymóg prawny — bez tego nie można launchować w EU |
| 5 | Tabela `classes` (CRUD, kod zaproszenia, join) | Core value proposition |
| 6 | Tabela `class_members` (pending / approved / rejected / banned) | Kontrola dostępu do klasy |
| 7 | Tabela `channels` (per klasa, CRUD admina) | Organizacja komunikacji przedmiotowej |
| 8 | Tabela `messages` (tekst, moderation_status, soft delete) | Podstawowa funkcja aplikacji |
| 9 | Edge Function `moderate-message` (profanity filter, rule-based) | Bezpieczeństwo — bez tego nie ma zaufania rodziców |
| 10 | Tabela `moderation_queue` + widok admina | Human-in-the-loop dla borderline content |
| 11 | RLS policies na WSZYSTKICH tabelach | Zero trust — każdy wiersz musi być chroniony |
| 12 | Tabela `notifications` + push via Expo | Engagement — użytkownik musi wiedzieć, że coś się dzieje |
| 13 | Tabela `devices` (trust, push_token, last_seen) | Device trust model, multi-device support |
| 14 | Edge Function `delete-user-data` (RODO erasure) | Prawo — musi być gotowe od dnia 1 |
| 15 | Tabela `audit_log` (append-only) | Accountability — kto i kiedy moderował |
| 16 | `updated_at` triggers na wszystkich tabelach | Data integrity |
| 17 | Soft delete (`deleted_at`) na user content | Nigdy nie tracimy danych bez śladu |

### 2.2 Frontend (React Native + Expo Web)

| # | Ekran / Funkcja | Uzasadnienie |
|---|-----------------|--------------|
| 1 | Splash screen + 4-slajdowy onboarding | First impression, wyjaśnienie value prop |
| 2 | Rejestracja (email, hasło, birth_year, ToS) | Konwersja — musi być płynna |
| 3 | Logowanie (email, hasło, Google OAuth) | Retencja — łatwy powrót |
| 4 | Ekran „Czekamy na zgodę rodzica” | Compliance — niezbędny dla <16 |
| 5 | Ekran główny — lista klas (ClassCard) | Core navigation |
| 6 | Tworzenie klasy (nazwa, szkoła, rok) + kod zaproszenia | Viral loop — admin tworzy, reszta dołącza |
| 7 | Dołączanie do klasy (kod) | Viral loop — reszta dołącza |
| 8 | Widok klasy — lista kanałów (sidebar) | Organization |
| 9 | Widok kanału — lista wiadomości (MessageBubble, infinite scroll) | Core feature |
| 10 | MessageInput (tekst, licznik znaków, send) | Core interaction |
| 11 | Moderation queue screen (admin only) | Safety — bez tego nie ma zaufania |
| 12 | Admin actions: approve / reject / trim message | Safety |
| 13 | Powiadomienia push (Expo) + in-app badge | Engagement |
| 14 | Ustawienia — konto (edycja profilu, zmiana hasła, usunięcie konta) | RODO, user control |
| 15 | Ustawienia — powiadomienia (master toggle, per-class, per-channel) | UX, privacy |
| 16 | Ustawienia — theme (light / dark / system) | Accessibility, modern standard |
| 17 | Ustawienia — urządzenia zaufane (lista, revoke) | Security |
| 18 | Toast system (success / error / info / warning) | Feedback — użytkownik musi wiedzieć, co się stało |
| 19 | Offline banner + offline queue (SecureStore) | Reliability — szkoły mają słaby zasięg |
| 20 | Optymistyczne aktualizacje UI (pending messages) | Perceived performance |
| 21 | i18n — język polski (domyślny) + angielski | Accessibility, future expansion |
| 22 | Accessibility labels na wszystkich interaktywnych elementach | Inclusive design |

### 2.3 Infrastruktura & DevOps

| # | Element | Uzasadnienie |
|---|---------|--------------|
| 1 | Supabase project (Frankfurt, eu-central-1) | RODO data residency |
| 2 | Lokalne środowisko dev (Supabase CLI + Docker) | Szybki development, testy |
| 3 | CI/CD GitHub Actions (typecheck, lint, test:unit, test:components) | Quality gate |
| 4 | `.env.example` z wszystkimi wymaganymi zmiennymi | Onboarding nowego dewelopera |
| 5 | Sentry (EU) — error tracking, stripped PII | Observability |
| 6 | Dokumentacja API (OpenAPI / Swagger z Zod) | Maintainability |

---

## 3. ❌ POZA ZAKRESEM MVP (Phase 2+)

### 3.1 Funkcjonalności (celowo nie w Phase 1)

| Funkcja | Dlaczego poza MVP | Kiedy (Phase) |
|---------|-------------------|---------------|
| **Voice messages** | Zwiększa złożoność UI (waveform, player, permissions), nie jest blokery dla „homework info sharing” | Phase 2 |
| **Image attachments** | Kompresja, storage limits, moderacja obrazków (OCR / AI vision), copyright concerns | Phase 2 |
| **Direct Messages (DM)** | Wymaga osobnego UI, osobnej logiki moderacji (auto-only), block system — dużo kodu | Phase 2 |
| **Personal notes + OCR** | Tesseract.js to ~10 MB WASM, osobny moduł UI, notatki to „nice to have” nie „must have” | Phase 2 |
| **Wątki (threads)** | Zwiększa złożoność UI i DB (thread replies, thread list), nie blokują podstawowej komunikacji | Phase 2 |
| **Wzmianki (@username)** | Wymaga parsera, powiadomień per-wzmianka, highlight UI — można dodać później | Phase 2 |
| **Ciche godziny (quiet hours)** | Konfiguracja czasowa, logika po stronie Edge Function — nie blokująca | Phase 2 |
| **Archiwizacja klasy** | End-of-year feature, nie potrzebna przy pierwszym semestrze użycia | Phase 2 |
| **Custom theme colours** | Premium-only, nie wpływa na core UX | Phase 3 |
| **Google Drive / iCloud backup** | OAuth scope, ZIP generation, upload — dużo pracy, JSON export wystarczy na start | Phase 2 (ZIP), Phase 3 (Drive) |
| **Premium subscriptions (RevenueCat)** | Wymaga App Store / Play Store setup, sandbox testing, webhooki — nie na MVP | Phase 3 |
| **Reklamy (AdMob)** | Wymaga COPPA-compliant config, review, nie generuje znaczących przychodów przy <1000 users | Phase 3 |
| **School Plan (teacher dashboard)** | B2B sales, osobny UI, nie na start | Phase 3 |
| **Online status / presence** | RODO concern (tracking), opt-in complexity, nie blokująca | Phase 2 |
| **Screenshot prevention (iOS detection)** | iOS nie pozwala na blokadę, tylko detection — marginal value | Phase 2 |
| **2FA dla zwykłych użytkowników** | Wymagane tylko dla adminów w MVP, dla memberów overkill | Phase 2 |
| **Magic link login** | Redundancy — mamy email+hasło i Google OAuth | Phase 2 |
| **Web Authn / biometryka na web** | Web to PWA secondary target, biometria to mobile-first | Phase 2 |
| **Full-text search wiadomości** | Wymaga Postgres `tsvector` lub Algolia — nie na start | Phase 2 |
| **Reakcje na wiadomości (👍)** | Social feature, nie core | Phase 2 |
| **Polls / głosowania** | Nie core do homework info | Phase 3 |
| **Kalendarz / plan lekcji** | Integracja z Librus/Synergia nie istnieje (brak API), ręczny plan to osobny produkt | Phase 3+ |
| **Integracja z Google Classroom / MS Teams** | API exists, ale wymaga OAuth scopes, sync logic, mapping — dużo pracy | Phase 3+ |
| **Aplikacja natywna (Swift / Kotlin)** | Expo obsługuje iOS/Android natively, osobne apki nie na start | Never (chyba że Expo okaże się niewystarczające) |

### 3.2 Techniczne (po MVP)

| Element | Dlaczego poza MVP | Kiedy |
|---------|-------------------|-------|
| **Rate limiting na Edge Functions** | Supabase ma domyślne, wystarczy na start | Phase 2 |
| **CDN dla assetów** | Supabase Storage ma CDN built-in | Phase 2 (custom CDN) |
| **Migracja z Supabase do self-hosted** | Skala >10k users, Supabase Pro może być drogi | Phase 3+ |
| **Webhooki dla zewnętrznych systemów** | Brak integracji na start | Phase 3 |
| **Load testing (>1000 concurrent)** | Niepotrzebne przy 1 klasie beta | Phase 2 |
| **Multi-region deployment** | Frankfurt wystarcza na EU | Phase 3 |

### 3.3 Prawne / Compliance (po MVP)

| Element | Dlaczego poza MVP | Kiedy |
|---------|-------------------|-------|
| **Certyfikat RODO compliance audit** | Kosztowny, wymagany dopiero przy scale / B2B | Phase 2 (przed publicznym launch) |
| **Umowa z placówką oświatową** | B2B School Plan | Phase 3 |
| **DPA z Sentry** | Review dokumentacji wystarczy na start | Phase 2 |
| **COPPA audit (US)** | Tylko jeśli launchujemy w US App Store | Phase 2 |
| **Copyright takedown process (DMCA-style)** | Potrzebne dopiero gdy ktoś faktycznie zgłosi | Phase 2 |

---

## 4. 🟡 DECYZJE DO PODJĘCIA PRZED PIERWSZYM SPRINTEM

Te decyzje wpływają na architekturę i są drogie do zmiany później:

### 4.1 Nazwa produktu
- **Opcja A:** `KlassMate` (obecna w docs) → bundle ID: `pl.klassmate.app`
- **Opcja B:** `KlassMatch` (obecna w URL repo) → bundle ID: `pl.klassmatch.app`
- **Decyzja:** Wybrać TERAZ. Bundle ID w App Store / Play Store jest niezmienny.

### 4.2 Parental consent mechanism
- **Opcja A:** Email link (najprostsza, legally borderline)
- **Opcja B:** Parent account (najbezpieczniejsza, więcej friction)
- **Opcja C:** Admin (teacher) vouches (przesuwa liability)
- **Decyzja:** MVP = Opcja A (email link) z jasnym disclaimerem w Privacy Policy. Phase 2 = rozważyć Opcję B.

### 4.3 Class Admin — kto może nim być?
- **Opcja A:** Dowolny uczeń (self-organized, viral)
- **Opcja B:** Tylko zweryfikowany nauczyciel (więcej trust, mniej viral)
- **Opcja C:** Uczeń, ale teacher musi approve class creation (hybrid)
- **Decyzja:** MVP = Opcja A (dowolny uczeń) — to jest core viral loop. Dodać „Report class” dla abuse.

### 4.4 Screenshot prevention — jak komunikować?
- **Opcja A:** Implementować best-effort (Android FLAG_SECURE, iOS detection) + jasny disclaimer
- **Opcja B:** Nie implementować wcale, skupić się na moderacji jako główny mechanizm bezpieczeństwa
- **Decyzja:** MVP = Opcja A, ale z miękkim językiem („Staramy się chronić prywatność”).

### 4.5 Demo publiczne bez logowania?
- **Opcja A:** Tak — tryb „gość” z read-only demo class (nie zapisuje danych)
- **Opcja B:** Nie — wymagane konto od pierwszego ekranu
- **Decyzja:** MVP = Opcja B (mniej friction w development, więcej privacy). Phase 2 = rozważyć demo.

### 4.6 Launch na Product Hunt / Hacker News?
- **Opcja A:** Od razu po MVP (ryzyko: duży ruch, nieprzetestowana moderacja)
- **Opcja B:** Po 2 tygodniach beta z 1 klasą (bezpieczniej)
- **Decyzja:** Opcja B. Product Hunt z nieprzetestowaną moderacją dzieci = reputacyjne samobójstwo.

---

## 5. 📊 Kryteria gotowości MVP (Definition of Ready dla v0.1)

Aby oznaczyć MVP jako „gotowe do beta testu”:

| # | Kryterium | Jak zweryfikować |
|---|-----------|------------------|
| 1 | Wszystkie US oznaczone `[P0]` w `docs/11_user_stories_and_ac.md` są zaimplementowane | Checklist w tym dokumencie |
| 2 | Testy E2E przechodzą dla głównego flow: rejestracja → utworzenie klasy → zaproszenie 2 uczniów → wysłanie wiadomości → moderacja → odpowiedź | Playwright / Detox test |
| 3 | Moderacja Edge Function przechodzi testy: profanity PL+EN, borderline queue, approve/reject/trim | Unit tests w Deno |
| 4 | RLS policies przechodzą penetration test (próba odczytu wiadomości z innej klasy, próba odczytu DM przez admina) | SQL testy w CI |
| 5 | Parental consent flow przetestowany end-to-end (fake email, klik link, aktywacja konta) | Manual test |
| 6 | Account deletion (RODO erasure) przetestowany — wszystkie dane usera usunięte / zanonimizowane | Manual test + DB query |
| 7 | Offline mode przetestowany: wyłącz Wi-Fi, napisz wiadomość, włącz Wi-Fi, wiadomość wysłana | Manual test |
| 8 | Push notifications działają na iOS Simulator + Android Emulator + Web | Manual test |
| 9 | CI przechodzi: typecheck, lint, unit tests, component tests | GitHub Actions green |
| 10 | Lighthouse / performance audit: web < 3s TTI na 3G | Lighthouse CI |
| 11 | Accessibility audit: wszystkie przyciski mają `accessibilityLabel`, kontrast > 4.5:1 | axe-core / manual |
| 12 | Security headers (CSP, X-Frame-Options) na web build | HTTP header check |
| 13 | 0 critical bugs, <5 known minor bugs w trackerze | Bug triage |
| 14 | Dokumentacja API (OpenAPI) wygenerowana i zweryfikowana | `zod-to-openapi` + Swagger UI |
| 15 | Privacy Policy i Terms of Service napisane (prawnik review opcjonalny przed beta, wymagany przed public launch) | Document review |

---

## 6. Anti-Scope-Creep Checklist

Gdy ktoś (Ty, AI-asystent, współpracownik) proponuje dodać funkcję do MVP, zadaj te pytania:

1. **Czy ta funkcja jest wymagana, żeby 1 klasa używała app przez 4 tygodnie?**
   - Jeśli NIE → Phase 2.
2. **Czy ta funkcja zwiększa bezpieczeństwo dzieci lub compliance?**
   - Jeśli TAK → rozważ MVP, ale sprawdź czy nie da się prościej.
3. **Czy ta funkcja wymaga nowej tabeli / Edge Function / third-party API?**
   - Jeśli TAK → prawdopodobnie Phase 2.
4. **Czy ta funkcja jest „taka sama jak w Classroom/Teams/Librus”?**
   - Jeśli TAK → nie konkurujemy feature-to-feature. Nasz USP to moderacja + privacy.
5. **Czy da się ją dodać w 1 dniu pracy?**
   - Jeśli TAK → rozważ MVP. Jeśli NIE → Phase 2.

---

## 7. Changelog tego dokumentu

| Data | Wersja | Zmiana | Autor |
|------|--------|--------|-------|
| 2025-06-11 | 0.1.0 | Initial version | AI Analysis |
