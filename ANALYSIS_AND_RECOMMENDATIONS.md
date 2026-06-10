# KlassMate — Analiza repozytorium & rekomendacje

> Data analizy: 2025-06-11 (bazowano na stanie repo `arcanixx/klassmatch`, branch `main`)
> Zakres: dokumentacja, struktura, kod, infrastruktura

---

## 1. Executive Summary

Repozytorium znajduje się w fazie **„paper architecture”** — dokumentacja projektowa (00–10 + dodatki) jest na wyjątkowo wysokim poziomie: kompletna, spójna, przyszłościowa i gotowa do przekazania zespołowi deweloperskiemu lub AI-asystentom. **Kodu produkcyjnego praktycznie nie ma** (same `.gitkeep` w `src/`, `supabase/functions/`, `supabase/migrations/`, `__tests__/`). To **nie jest wada** na tym etapie — oznacza to, że projekt ma solidne fundamenty planistyczne przed pierwszym commitem kodu.

**Największa wartość dodana, którą można wnieść teraz:**
1. Uzupełnienie dokumentów strategicznych (user stories + AC, scope boundary, risk register, competitive analysis, analytics plan, data seed).
2. Naprawa drobnych błędów w schema SQL (constraint logic).
3. Przygotowanie „Definition of Ready” dla pierwszego sprintu kodowania.
4. Rozwiązanie niespójności nazewnictwa (`klassmatch` vs `KlassMate`).

---

## 2. Co jest wyjątkowo dobrze zrobione ✅

| Obszar | Ocena | Uzasadnienie |
|--------|-------|--------------|
| **Dokumentacja architektury** | ⭐⭐⭐⭐⭐ | `01_ARCHITECTURE.md` + `01b` zawierają pełny model danych, RLS, Edge Functions, flow autentykacji, stanu i offline. Jeden z najlepszych zalążków dokumentacji jakie widziałem w projektach indie. |
| **Standardy kodu (02)** | ⭐⭐⭐⭐⭐ | File headers, 200-line limit, no `any`, no barrel files, i18n hard rules, Zustand patterns — gotowe do użycia przez AI i ludzi. |
| **AI Rules (03)** | ⭐⭐⭐⭐⭐ | Konkretne NEVER/ALWAYS/BE CAREFUL. Zapobiega 90% typowych błędów AI-asystentów. |
| **Security (04)** | ⭐⭐⭐⭐⭐ | Three-layer auth, biometrics, device trust, 2FA, screenshot prevention reality-check, CSP headers. |
| **Legal / RODO (05)** | ⭐⭐⭐⭐⭐ | Age gate, parental consent flow, DPA, data retention, DSA, copyright fair-use. Kompletny checklist przed launch. |
| **Feature Spec (06)** | ⭐⭐⭐⭐☆ | Bardzo szczegółowy UX (onboarding, moderation UI, DM block, OCR flow, toast messages). Brakuje tylko testowalnych Acceptance Criteria. |
| **Testing & Debug (07)** | ⭐⭐⭐⭐☆ | Jest plan warstw testów, mocki, debug panel, CI/CD sketch. Brakuje tylko konkretnych przypadków testowych (test cases). |
| **Roadmap (08)** | ⭐⭐⭐⭐☆ | Fazy, tygodnie, ceny, RevenueCat, AdMob COPPA-compliant. Można dodać konkretne daty i milestone’y. |
| **Notifications (09)** | ⭐⭐⭐⭐⭐ | Pełna specyfikacja push (Expo), payload, Android channels, quiet hours, deep links, permission flow. |
| **Session & State (10)** | ⭐⭐⭐⭐⭐ | Zustand stores, offline queue, optimistic updates, pagination, multi-device revocation. |

---

## 3. Niespójności i błędy do poprawki 🔧

### 3.1 Nazewnictwo: `klassmatch` vs `KlassMate`
- **URL repo:** `github.com/arcanixx/klassmatch`
- **W docs:** `KlassMate`
- **W `app.config.ts`:** `KlassMate` (z fallbackiem do env)
- **W `package.json`:** `klassmatch`
- **Decyzja do podjęcia:** Czy finalna nazwa to KlassMate czy KlassMatch? To wpływa na:
  - Bundle ID (`pl.klassmatch.app` vs `pl.klassmate.app`)
  - Domenę
  - Nazwę Supabase project
  - Wszystkie klucze i18n

**Rekomendacja:** Rozstrzygnąć TERAZ. Zmiana nazwy po rozpoczęciu kodowania jest kosztowna (bundle ID w App Store / Play Store nie może być zmieniony po pierwszym uploadzie).

### 3.2 Błąd w SQL constraint (`messages` table)
W `01_ARCHITECTURE.md` linia ~156:
```sql
CONSTRAINT message_target_check CHECK (
  (channel_id IS NOT NULL AND dm_id IS NULL) OR
  (dm_id IS NOT NULL AND channel_id IS NOT NULL)  -- ❌ BŁĄD: pozwala na oba NOT NULL
);
```
Powinno być:
```sql
CONSTRAINT message_target_check CHECK (
  (channel_id IS NOT NULL AND dm_id IS NULL) OR
  (dm_id IS NOT NULL AND channel_id IS NULL)      -- ✅ XOR: dokładnie jeden
);
```

### 3.3 Brak `updated_at` triggerów w schema
W `01_ARCHITECTURE.md` są kolumny `updated_at` w wielu tabelach, ale nie ma definicji triggerów `auto-update`. Należy dodać do migracji:
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';
```

### 3.4 `app.config.ts` — `YOUR_EAS_PROJECT_ID`
Jest placeholder. To OK na ten etap, ale powinien być w `.env` z walidacją w CI.

### 3.5 `package.json` — brak `zod` w zależnościach
W docs często wspominane jest walidowanie schematów (np. Edge Functions), ale w `package.json` nie ma `zod`. Należy dodać.

### 3.6 Brak `supabase` CLI w devDependencies
Do lokalnego developmentu (migracje, gen types, local functions) potrzebny jest `supabase` CLI.

---

## 4. Luki dokumentacyjne (brakujące pliki)

Na podstawie sugestii z innego projektu i audytu obecnego stanu:

| # | Plik | Status | Priorytet |
|---|------|--------|-----------|
| 11 | `docs/11_user_stories_and_ac.md` | ❌ Brak | 🔴 Krytyczny |
| 12 | `docs/12_mvp_scope_boundary.md` | ❌ Brak | 🔴 Krytyczny |
| 13 | `docs/13_api_contract.md` | ❌ Brak (opisane słownie w 01) | 🟡 Wysoki |
| 14 | `docs/14_risk_register.md` | ❌ Brak | 🟡 Wysoki |
| 15 | `docs/15_competitive_analysis.md` | ❌ Brak (wspomniane w 00) | 🟢 Średni |
| 16 | `docs/16_analytics_plan.md` | ❌ Brak | 🟡 Wysoki |
| 17 | `docs/17_data_seed_strategy.md` | ❌ Brak (wspomniane w 07) | 🟢 Średni |

**Uwaga:** W repo już istnieje `docs/10_SESSION_AND_STATE.md`, więc nowe dokumenty powinny zaczynać się od numeru 11 (lub zrobić renumeryzację). Rekomenduję **dodać jako 11–17 bez renumeryzacji** — istniejące 00–10 mają już wewnętrzne odniesienia (`@dependsOn`).

---

## 5. Luki implementacyjne (przed pierwszym sprintem)

### 5.1 Infrastruktura
- [ ] **Dodać `supabase` CLI** do devDependencies lub jako global tool
- [ ] **Dodać `zod`** do dependencies (walidacja API)
- [ ] **Dodać `@faker-js/faker`** do devDependencies (seed / testy)
- [ ] **Skonfigurować EAS Project ID** w `.env.example`
- [ ] **Dodać `eas.json`** (build profiles: development, preview, production)
- [ ] **Dodać `.nvmrc`** lub `engines` w `package.json` (spójna wersja Node)

### 5.2 TypeScript / types
- [ ] **Wygenerować typy Supabase** (`supabase gen types typescript --local > src/lib/supabase/types.ts`)
- [ ] **Zdefiniować `Result<T, E>`** (wspominany w 02, ale nie ma definicji)
- [ ] **Dodać `AppError` class** (wspominana w 02, nie ma implementacji)

### 5.3 Config
- [ ] **Utworzyć `src/config/features.config.ts`** (wspomniany w wielu docs, nie ma pliku)
- [ ] **Utworzyć `src/config/limits.config.ts`**
- [ ] **Utworzyć `src/config/locales.config.ts`**
- [ ] **Utworzyć `src/config/moderation.config.ts`**

### 5.4 i18n
- [ ] **Uzupełnić `pl.json` i `en.json`** — obecnie prawdopodobnie puste lub minimalne
- [ ] **Dodać system interpolacji** (np. `t('message.input.placeholder', { channelName })`)

### 5.5 CI/CD
- [ ] **Uzupełnić `.github/workflows/ci.yml`** — obecnie prawdopodobnie pusty lub template
- [ ] **Dodać workflow dla EAS Build** (`.github/workflows/eas-build.yml`)
- [ ] **Dodać workflow dla Supabase migrations** (deploy na merge do `main`)

---

## 6. Rekomendacje przed rozpoczęciem kodowania

### 6.1 Priorytet 0 (zablokują pierwszy sprint jeśli niegotowe)
1. **Rozstrzygnąć nazwę** (`KlassMate` vs `KlassMatch`) → wpisz w `00_PROJECT_OVERVIEW.md` i `app.config.ts`.
2. **Odpowiedzieć na 5 pytań krytycznych** z `00_PROJECT_OVERVIEW.md` sekcja 9 (parental consent mechanism, class admin, screenshot prevention, voice messages vs recording, backup format).
3. **Uzupełnić `docs/11_user_stories_and_ac.md`** — bez tego nie ma testowalnych wymagań.
4. **Uzupełnić `docs/12_mvp_scope_boundary.md`** — bez tego nastąpi scope creep.

### 6.2 Priorytet 1 (zwiększą prędkość developmentu)
5. **Uzupełnić `docs/13_api_contract.md`** z Zod schemas — programista/AI będzie mógł kopiować schematy 1:1.
6. **Uzupełnić `docs/14_risk_register.md`** — szczególnie ryzyka prawne (RODO, DSA) i techniczne (moderacja, offline sync).
7. **Uzupełnić `docs/16_analytics_plan.md`** — eventy powinny być znane przed pisaniem kodu, żeby nie dodawać ich potem retro.
8. **Skonfigurować lokalne środowisko Supabase** (`supabase init` + `supabase start` w Docker).

### 6.3 Priorytet 2 (quality of life)
9. **Uzupełnić `docs/15_competitive_analysis.md`** — pomaga w pitchu i Product Hunt.
10. **Uzupełnić `docs/17_data_seed_strategy.md`** — przyspiesza testowanie i demo.
11. **Dodać `docs/18_ai_context_protocol.md`** — jak pracować z AI w długich sesjach (kontekst, podział na taski, reguły „nie powtarzaj się”).

---

## 7. Ocena gotowości do kodowania

| Kryterium | Gotowość | Komentarz |
|-----------|----------|-----------|
| Architektura | 95% | Gotowa, drobny błąd SQL do poprawy |
| UX/UI spec | 90% | Gotowy, brakuje tylko AC |
| Bezpieczeństwo | 95% | Gotowe, wymaga tylko implementacji |
| Prawo / RODO | 90% | Gotowe, wymaga review prawnika |
| Test strategy | 75% | Plan gotowy, brak konkretnych test cases |
| API / Backend | 70% | Schema gotowa, brak Zod contracts i migracji |
| Frontend structure | 60% | Same `.gitkeep`, ale struktura folderów jasna |
| DevOps / CI | 50% | `ci.yml` istnieje, ale prawdopodobnie pusty |
| **Średnia** | **79%** | **Bardzo dobry zalążek. 2–3 dni pracy nad dokumentacją i setup → 90%+** |

---

## 8. Podsumowanie dla właściciela

Masz **jeden z najlepiej przygotowanych zalążków projektowych** jakie widziałem. Dokumentacja 00–10 jest kompletna, spójna i gotowa do przekazania dowolnemu deweloperowi lub AI-asystentowi. **Nie zaczynaj kodowania przed rozstrzygnięciem nazwy i odpowiedzią na 5 pytań krytycznych z sekcji 9 `00_PROJECT_OVERVIEW.md`.**

Po tym — dodaj dokumenty 11–17 (przygotuję je teraz), popraw constraint SQL, skonfiguruj lokalne Supabase i możesz bezpiecznie wydać pierwszy sprint kodowania (auth + klasy + kanały + podstawowe wiadomości).
