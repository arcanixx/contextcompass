# 14 — Risk Register
# Path: docs/14_risk_register.md
# Purpose: Top ryzyk projektowych + mitigacja + właściciel + priorytet
# Depends on: docs/00_PROJECT_OVERVIEW.md, docs/01_ARCHITECTURE.md, docs/05_LEGAL_COMPLIANCE.md
# Status: MVP v0.1 (Phase 1)

---

# KlassMate — Risk Register

> **Wersja:** 0.1.0-draft  
> **Ostatnia aktualizacja:** 2025-06-11  
> **Metodologia:** Prawdopodobieństwo (1–5) × Wpływ (1–5) = Wskaźnik ryzyka (1–25).  
> **Priorytet natychmiastowy:** Wskaźnik ≥ 15 LUB prawdopodobieństwo ≥ 4 z wpływem ≥ 4.

---

## 1. Format wpisu

Każde ryzyko opisane wg szablonu:

| Pole | Opis |
|------|------|
| **ID** | Unikalny identyfikator (R01, R02...) |
| **Nazwa** | Krótki opis ryzyka |
| **Kategoria** | Prawne / Techniczne / Bezpieczeństwo / Produkt / Biznesowe / Operacyjne |
| **Prawdopodobieństwo** | 1 (bardzo małe) – 5 (prawie pewne) |
| **Wpływ** | 1 (marginalny) – 5 (katastrofalny) |
| **Wskaźnik** | P × W (max 25) |
| **Mitigacja** | Co robimy, żeby zmniejszyć prawdopodobieństwo lub wpływ |
| **Plan awaryjny** | Co robimy, gdy ryzyko się zmaterializuje |
| **Właściciel** | Kto odpowiada za monitorowanie i mitigację |
| **Status** | Aktywne / Zmaterializowane / Zamknięte |

---

## 2. Rejestr ryzyk

---

### R01: Nieodpowiednie treści w wiadomościach (hejt, cyberbullying, spam)

| Pole | Wartość |
|------|---------|
| **Kategoria** | Bezpieczeństwo / Prawne |
| **Prawdopodobieństwo** | 4 (wysokie — szkoły to środowisko podatne na hejt) |
| **Wpływ** | 5 (katastrofalny: reputacja, ban w sklepach, odpowiedzialność karna, RODO) |
| **Wskaźnik** | **20** 🔴 |
| **Mitigacja** | 1. Moderacja przed zapisem (Edge Function) — rule-based profanity PL+EN.<br>2. Human-in-the-loop queue dla borderline content.<br>3. Admin może reject / trim.<br>4. DM auto-moderacja (brak human review, auto-reject).<br>5. User reporting („Zgłoś wiadomość”).<br>6. Audit log wszystkich decyzji moderacyjnych.<br>7. Community Guidelines wymagane przy rejestracji. |
| **Plan awaryjny** | 1. Natychmiastowe zawieszenie konta nadawcy.<br>2. Powiadomienie admina klasy + superadmina.<br>3. Wycofanie wiadomości z kanału (soft delete).<br>4. Dokumentacja incydentu w audit_log.<br>5. W przypadku poważnego incydentu — konsultacja prawnicza. |
| **Właściciel** | Product Owner + Backend Lead |
| **Status** | Aktywne |

---

### R02: Naruszenie RODO / brak zgody rodzica dla użytkowników <16 lat

| Pole | Wartość |
|------|---------|
| **Kategoria** | Prawne |
| **Prawdopodobieństwo** | 4 (wysokie — wiele użytkowników będzie <16, RODO Art. 8 jest surowy) |
| **Wpływ** | 5 (kary finansowe do 20M EUR lub 4% obrotu, zamknięcie projektu, ban w sklepach) |
| **Wskaźnik** | **20** 🔴 |
| **Mitigacja** | 1. Age gate przy rejestracji (birth_year).<br>2. Parental consent flow (email link) dla <16.<br>3. Konto w stanie `pending_consent` — zero dostępu do app.<br>4. Przechowywanie timestampu zgody i metody w DB.<br>5. DPA z Supabase podpisane.<br>6. Privacy Policy + ToS napisane i dostępne w app.<br>7. Konsultacja z prawnikiem przed publicznym launch. |
| **Plan awaryjny** | 1. Natychmiastowe zawieszenie kont dzieci bez zgody.<br>2. Wysłanie emaila do rodziców z prośbą o retroaktywną zgodę.<br>3. Jeśli odmowa — usunięcie danych (Edge Function `delete-user-data`).<br>4. Powiadomienie UODO (polski regulator) w ciągu 72h w przypadku wycieku. |
| **Właściciel** | Legal / Compliance Lead |
| **Status** | Aktywne |

---

### R03: Utrata danych użytkowników (brak backupu / awaria Supabase)

| Pole | Wartość |
|------|---------|
| **Kategoria** | Techniczne / Operacyjne |
| **Prawdopodobieństwo** | 2 (niskie — Supabase ma backup, ale awarie się zdarzały) |
| **Wpływ** | 5 (utrata zaufania, odejście użytkowników, odpowiedzialność za dane szkolne) |
| **Wskaźnik** | **10** 🟡 |
| **Mitigacja** | 1. Supabase Point-in-Time Recovery (PITR) — włączone.<br>2. Ręczny eksport JSON (przycisk w ustawieniach).<br>3. Phase 2: auto-backup do Google Drive / iCloud.<br>4. Test przywracania co kwartał.<br>5. Soft delete zamiast hard delete — możliwość odzyskania. |
| **Plan awaryjny** | 1. Przywrócenie z PITR do ostatniego healthy snapshot.<br>2. Komunikat do użytkowników: „Przerwa techniczna, dane są bezpieczne”.<br>3. Jeśli PITR zawiedzie — przywrócenie z ręcznego backupu (jeśli user go robił). |
| **Właściciel** | DevOps / Backend Lead |
| **Status** | Aktywne |

---

### R04: Niska adopcja / brak użytkowników (konkurencja: Teams, Classroom, Librus)

| Pole | Wartość |
|------|---------|
| **Kategoria** | Biznesowe / Produkt |
| **Prawdopodobieństwo** | 3 (średnie — konkurencja jest silna, ale nasz USP to moderacja + privacy) |
| **Wpływ** | 4 (projekt upada, strata czasu i pieniędzy) |
| **Wskaźnik** | **12** 🟡 |
| **Mitigacja** | 1. Program beta z 5 szkołami (darmowy rok).<br>2. Viral loop: join code → cała klasa instaluje.<br>3. Content marketing: blog dla nauczycieli, TikTok/IG dla uczniów.<br>4. Integracja z Librus (czytanie planu lekcji) — jeśli API istnieje.<br>5. Import z Google Classroom (Google Takeout) — Phase 2.<br>6. Open source część kodu — buduje zaufanie. |
| **Plan awaryjny** | 1. Pivot do B2B (School Plan) — sprzedaż bezpośrednia do dyrektorów.<br>2. Zmiana modelu: freemium → darmowy dla szkół publicznych, płatny tylko dla prywatnych.<br>3. White-label — sprzedaż platformy pod inną marką. |
| **Właściciel** | Product Owner |
| **Status** | Aktywne |

---

### R05: Błąd w synchronizacji offline (konflikty, utrata wiadomości)

| Pole | Wartość |
|------|---------|
| **Kategoria** | Techniczne |
| **Prawdopodobieństwo** | 3 (średnie — przy wielu urządzeniach i słabym zasięgu) |
| **Wpływ** | 3 (frustracja użytkownika, utrata części danych, ale nie krytyczne) |
| **Wskaźnik** | **9** 🟢 |
| **Mitigacja** | 1. Last-write-wins z timestampem (zawsze bezpieczne dla wiadomości).<br>2. Offline queue max 20 wiadomości — ograniczenie skali konfliktu.<br>3. Przy konflikcie — pokazanie użytkownikowi obu wersji do wyboru (tylko dla notatek).<br>4. Logi konfliktów do `sync_conflicts` (do analizy).<br>5. Testy offline w CI (Playwright z wyłączoną siecią). |
| **Plan awaryjny** | 1. Ręczne retry z UI („Spróbuj ponownie”).<br>2. Jeśli wiadomość zaginęła — użytkownik może przepisać (zły UX, ale nie utrata danych krytycznych).<br>3. Hotfix w ciągu 24h. |
| **Właściciel** | Frontend Lead |
| **Status** | Aktywne |

---

### R06: Admin klasy nie moderuje (nauczyciele / uczniowie nie chcą sprawdzać kolejki)

| Pole | Wartość |
|------|---------|
| **Kategoria** | Produkt / Bezpieczeństwo |
| **Prawdopodobieństwo** | 4 (wysokie — nauczyciele są przeciążeni, uczniowie-admini mogą ignorować) |
| **Wpływ** | 4 (spam i hejt niekontrolowany, utrata zaufania rodziców) |
| **Wskaźnik** | **16** 🔴 |
| **Mitigacja** | 1. Automatyczna filtracja 80% oczywistych wulgaryzmów (regex + word lists) — nie wymaga admina.<br>2. Auto-approve po 1h jeśli admin nie zareagował (z flagą `auto_approved`).<br>3. Powiadomienia push dla admina — tylko gdy queue > 0 (nie spamujemy).<br>4. Raport tygodniowy: „X wiadomości zatwierdzono automatycznie, Y czeka”.<br>5. Opcja „zaufani uczniowie” jako asystenci moderatorzy (Phase 2).<br>6. Gamification: badge „Strażnik” dla aktywnych adminów. |
| **Plan awaryjny** | 1. Jeśli queue rośnie > 24h — superadmin dostaje alert.<br>2. Możliwość tymczasowego włączenia „auto-approve all” w sytuacji kryzysowej (z logiem w audit_log).<br>3. W skrajnych przypadkach — superadmin może przejąć moderację klasy. |
| **Właściciel** | Product Owner + UX Lead |
| **Status** | Aktywne |

---

### R07: Atak na endpointy (DDoS, brute force, scraping)

| Pole | Wartość |
|------|---------|
| **Kategoria** | Bezpieczeństwo |
| **Prawdopodobieństwo** | 2 (niskie — mały projekt nie jest celem, ale dziecięca app może być celem trolli) |
| **Wpływ** | 4 (niedostępność, utrata zaufania, koszty Supabase) |
| **Wskaźnik** | **8** 🟢 |
| **Mitigacja** | 1. Rate limiting na Edge Functions (Supabase ma domyślne + custom per function).<br>2. Cloudflare (wersja darmowa) przed Supabase.<br>3. Blokada IP po 5 nieudanych próbach logowania.<br>4. reCAPTCHA v3 przy rejestracji.<br>5. RLS — nawet przy przepełnieniu requestów, dane są chronione. |
| **Plan awaryjny** | 1. Włączenie „Under Attack Mode” w Cloudflare.<br>2. Tymczasowe wyłączenie rejestracji (maintenance mode).<br>3. Kontakt z Supabase support w przypadku dużego DDoS. |
| **Właściciel** | Security / DevOps |
| **Status** | Aktywne |

---

### R08: Awaria Supabase (outage eu-central-1)

| Pole | Wartość |
|------|---------|
| **Kategoria** | Techniczne / Operacyjne |
| **Prawdopodobieństwo** | 1 (bardzo niskie — Supabase ma SLA, ale awarie się zdarzały) |
| **Wpływ** | 5 (cała aplikacja offline, użytkownicy nie mogą komunikować się o zadaniach) |
| **Wskaźnik** | **5** 🟢 |
| **Mitigacja** | 1. Supabase ma multi-region replication (opcjonalnie włączyć).<br>2. Strona statyczna „Serwis w naprawie” (hostowana na Vercel/Netlify, niezależna od Supabase).<br>3. Backup bazy co godzinę do S3 (opcjonalnie).<br>4. Status page (statuspage.io lub instatus.com) — transparentność. |
| **Plan awaryjny** | 1. Komunikat na stronie statycznej + social media.<br>2. Jeśli outage > 4h — rozważyć tymczasowy fallback do Firebase (kosztowne, ale działa).<br>3. Po przywróceniu — auto-flush offline queue. |
| **Właściciel** | DevOps |
| **Status** | Aktywne |

---

### R09: Użytkownik zapomni hasła / straci dostęp do emaila

| Pole | Wartość |
|------|---------|
| **Kategoria** | Produkt |
| **Prawdopodobieństwo** | 4 (częste — dzieci zapominają hasła, zmieniają email) |
| **Wpływ** | 2 (łatwe do rozwiązania, ale frustrujące) |
| **Wskaźnik** | **8** 🟢 |
| **Mitigacja** | 1. Reset hasła przez email (Supabase built-in).<br>2. Logowanie przez Google OAuth (nie trzeba pamiętać hasła).<br>3. Biometryczne odblokowanie (Face ID / fingerprint) — szybki powrót.<br>4. Trusted device — sesja nie wygasa (nie trzeba pamiętać hasła). |
| **Plan awaryjny** | 1. Support manualny — weryfikacja tożsamości przez support@ (last resort).<br>2. W przypadku utraty emaila — zmiana emaila wymaga obecnego hasła + weryfikacji nowego. |
| **Właściciel** | Auth / Frontend Lead |
| **Status** | Aktywne |

---

### R10: Wyciek danych osobowych (breach)

| Pole | Wartość |
|------|---------|
| **Kategoria** | Bezpieczeństwo / Prawne |
| **Prawdopodobieństwo** | 2 (niskie — RLS, zero direct DB access, ale błąd ludzki zawsze możliwy) |
| **Wpływ** | 5 (kary RODO, utrata zaufania, media, zamknięcie projektu) |
| **Wskaźnik** | **10** 🟡 |
| **Mitigacja** | 1. RLS na każdej tabeli — zero implicit access.<br>2. Service role key NIGDY na kliencie.<br>3. Edge Functions walidują JWT przed każdą operacją.<br>4. Sentry — PII stripped (`beforeSend` usuwa email/username).<br>5. Regularne review RLS policies (co sprint).<br>6. Penetration test przed publicznym launch.<br>7. Encryption at rest (AES-256, Supabase default).<br>8. TLS 1.3 in transit. |
| **Plan awaryjny** | 1. Natychmiastowe wyłączenie endpointu / funkcji powodującej wyciek.<br>2. Powiadomienie UODO w ciągu 72h.<br>3. Email do wszystkich użytkowników z informacją o incydencie i krokach.<br>4. Forensic analysis — co wyciekło, kto miał dostęp.<br>5. Wsparcie prawnicze. |
| **Właściciel** | Security / Legal |
| **Status** | Aktywne |

---

### R11: Niezgodność z DSA (Digital Services Act) — brak transparentności moderacji

| Pole | Wartość |
|------|---------|
| **Kategoria** | Prawne |
| **Prawdopodobieństwo** | 3 (średnie — DSA wymaga mechanizmów, które mamy, ale raportowanie jest opcjonalne do pewnej skali) |
| **Wpływ** | 4 (kary, ograniczenia działalności w EU) |
| **Wskaźnik** | **12** 🟡 |
| **Mitigacja** | 1. „Zgłoś wiadomość” — każdy user może zgłosić.<br>2. Moderation queue z human review.<br>3. Powiadomienie do nadawcy o decyzji (transparency).<br>4. Audit log wszystkich decyzji.<br>5. Appeal process w ToS („Jeśli nie zgadzasz się z decyzją, napisz do...”).<br>6. Phase 2: Transparency Report (roczny). |
| **Plan awaryjny** | 1. Szybkie wdrożenie brakującego mechanizmu DSA.<br>2. Konsultacja z prawnikiem specjalizującym się w DSA. |
| **Właściciel** | Legal / Product Owner |
| **Status** | Aktywne |

---

### R12: Problem z OCR (Tesseract.js za duży, OCR.space limit)

| Pole | Wartość |
|------|---------|
| **Kategoria** | Techniczne / Produkt |
| **Prawdopodobieństwo** | 3 (średnie — Tesseract WASM to ~10 MB, może być problem na słabszych telefonach) |
| **Wpływ** | 2 (frustracja, ale notatki to Phase 2, nie MVP) |
| **Wskaźnik** | **6** 🟢 |
| **Mitigacja** | 1. Lazy loading Tesseract — ładowany tylko gdy user otworzy Notes.<br>2. OCR.space fallback (500 req/day/IP, free tier).<br>3. Kompresja obrazka przed OCR (max 3 MB).<br>4. Phase 2: rozważyć server-side Tesseract (Edge Function) zamiast client-side. |
| **Plan awaryjny** | 1. Wyłączenie OCR tymczasowo — notatki tekstowe nadal działają.<br>2. Komunikat: „OCR tymczasowo niedostępne. Wpisz tekst ręcznie.” |
| **Właściciel** | Frontend Lead |
| **Status** | Aktywne |

---

### R13: Zarzuty o kopiowanie pomysłu / patent infringement

| Pole | Wartość |
|------|---------|
| **Kategoria** | Biznesowe / Prawne |
| **Prawdopodobieństwo** | 1 (bardzo niskie — wiele podobnych aplikacji, brak unikalnych patentów w tej przestrzeni) |
| **Wpływ** | 2 (strata czasu na obronę, koszty prawnicze) |
| **Wskaźnik** | **2** 🟢 |
| **Mitigacja** | 1. Unikalna funkcja: moderacja przed wysłaniem (human-in-the-loop) — nasz USP.<br>2. Open source część kodu (buduje zaufanie i transparentność).<br>3. Dokumentacja procesu tworzenia (daty, commity, decyzje architektoniczne).<br>4. Nie kopiujemy UI/UX z konkurencji 1:1. |
| **Plan awaryjny** | 1. Konsultacja prawnicza.<br>2. Jeśli zarzut jest bezzasadny — publiczna odpowiedź z dokumentacją. |
| **Właściciel** | Product Owner / Legal |
| **Status** | Aktywne |

---

### R14: Brak chętnych do testów beta (nie możemy znaleźć 1 klasy)

| Pole | Wartość |
|------|---------|
| **Kategoria** | Biznesowe |
| **Prawdopodobieństwo** | 3 (średnie — potrzebna 1 klasa, ale trzeba kogoś przekonać) |
| **Wpływ** | 3 (opóźnienie feedback loop, ale nie zabija projektu) |
| **Wskaźnik** | **9** 🟢 |
| **Mitigacja** | 1. Zacząć od własnej klasy / znajomych (dogfooding).<br>2. Oferta: darmowy rok Premium dla pierwszych 5 klas.<br>3. Kontakt z nauczycielami-influencerami (Instagram/TikTok edu).<br>4. Program ambasadorski: uczeń dostaje Premium za zaproszenie 5 kolegów. |
| **Plan awaryjny** | 1. Zmiana targetu: zamiast szkoły publicznej — szkoła prywatna / korepetycje online.<br>2. Zmiana modelu: B2B (sprzedaż do dyrektora) zamiast B2C. |
| **Właściciel** | Product Owner |
| **Status** | Aktywne |

---

### R15: Zmiana polityki Supabase (ceny, limitów, wycofanie free tier)

| Pole | Wartość |
|------|---------|
| **Kategoria** | Biznesowe / Techniczne |
| **Prawdopodobieństwo** | 2 (niskie — Supabase jest stabilne, ale startupy zmieniają ceny) |
| **Wpływ** | 4 (koszty, migracja, downtime) |
| **Wskaźnik** | **8** 🟢 |
| **Mitigacja** | 1. Architektura oparta na PostgreSQL — łatwa migracja do Neon, AWS RDS, self-hosted.<br>2. Brak vendor lock-in — standardowe SQL, standardowe JWT.<br>3. Monitorowanie zużycia (alert przy 80% limitu).<br>4. Plan finansowy: zakładamy płatny tier Supabase Pro przy >1000 users. |
| **Plan awaryjny** | 1. Migracja do Neon.tech (Frankfurt) lub PocketBase (self-hosted na Hetzner/OVH).<br>2. Eksport danych przez `pg_dump` — przygotowany skrypt migracyjny. |
| **Właściciel** | DevOps / Product Owner |
| **Status** | Aktywne |

---

## 3. Matryca ryzyk (wizualizacja)

```
Wpływ ↑
  5 │  R01   R02   R03   R08   R10
  4 │  R04   R06   R07   R11
  3 │  R05   R14
  2 │  R09   R12   R13
  1 │
    └────────────────────────────────
      1    2    3    4    5    → Prawdopodobieństwo
```

**Strefa krytyczna (P≥4, W≥4):** R01, R02, R06  
**Strefa wysokiego ryzyka (Wskaźnik ≥ 12):** R01, R02, R04, R06, R11  
**Strefa monitorowania (Wskaźnik 8–11):** R03, R05, R07, R09, R10, R12, R14, R15  
**Strefa akceptowalna (Wskaźnik ≤ 7):** R08, R13

---

## 4. Priorytet mitigacji (co najpierw)

| Kolejność | Ryzyko | Akcja | Termin |
|-----------|--------|-------|--------|
| 1 | **R01** (moderacja) | Wdrożyć `moderate-message` Edge Function + word lists PL+EN + moderation queue UI | Sprint 1 |
| 2 | **R02** (RODO / zgoda rodzica) | Wdrożyć age gate + parental consent flow + DPA z Supabase | Sprint 1 |
| 3 | **R06** (brak moderatorów) | Auto-approve po 1h + gamification + weekly report | Sprint 2 |
| 4 | **R10** (wyciek danych) | Penetration test RLS + review Sentry PII stripping | Sprint 2 |
| 5 | **R04** (niska adopcja) | Przygotować listę 5 szkół do beta + content plan | Sprint 3 |
| 6 | **R11** (DSA) | Dodać appeal process do ToS + transparency report template | Phase 2 |

---

## 5. Changelog

| Data | Wersja | Zmiana | Autor |
|------|--------|--------|-------|
| 2025-06-11 | 0.1.0 | Initial risk register — 15 risks identified, 3 critical | AI Analysis |
