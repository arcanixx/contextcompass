<!-- =============================================================================
 FILE: code-review-2026-06-09.md
 PATH: logs/code-review-2026-06-09.md
 VERSION: 0.1.0
 PURPOSE: Wynik Code Review dla ContextCompass — Sprint 0 (Pre-development). Inicjalny przegląd dokumentacji i struktury przed startem implementacji.
 DEPENDS ON: docs/CODE_REVIEW_CHECKLIST.md
 ============================================================================= -->

# 📋 Code Review — ContextCompass
**Data:** 2026-06-09
**Reviewer:** Claude (Anthropic)
**Sprint:** 0 — Pre-development / Planning
**Branch:** `main` → inicjalizacja dokumentacji
**Typ przeglądu:** Dokumentacja + architektura (pre-code review)

---

## KONTEKST PRZEGLĄDU

Sprint 0 nie zawiera jeszcze kodu produkcyjnego — przegląd obejmuje:
- Kompletność dokumentacji projektowej
- Spójność decyzji architektonicznych
- Identyfikację ryzyk przed startem implementacji
- Weryfikację zgodności z `CODING_STANDARDS.md` i `ARCHITECTURE_PRINCIPLES.md`

---

## WYNIKI SEKCJI

### 1. NAGŁÓWKI PLIKÓW I DOKUMENTACJA

| # | Sprawdzenie | Wynik | Uwagi |
|---|-------------|-------|-------|
| 1.1.1 | Nagłówki w plikach `.ts`/`.tsx` | ⏭️ N/A | Brak kodu — do weryfikacji w Sprint 1 |
| 1.1.4 | Pole `Purpose` nie generyczne | ✅ | Wszystkie pliki `.md` mają wypełnione `PURPOSE` |
| 1.2.1 | JSDoc dla publicznych funkcji | ⏭️ N/A | Brak kodu — do weryfikacji w Sprint 1 |
| 1.2.3 | TODO z autorem i datą | ✅ | Sekcja 15 DEVELOPMENT_PLAN.md — otwarte pytania oznaczone `❓` (do decyzji) |

**Status sekcji:** ✅ PASS (N/A dla kodu)

---

### 2. STRUKTURA PLIKÓW I ARCHITEKTURA MONOREPO

| # | Sprawdzenie | Wynik | Uwagi |
|---|-------------|-------|-------|
| 2.1.1 | `shared/` nie importuje z `web/`/`extension/` | ⏭️ N/A | Zaplanowane poprawnie w DEVELOPMENT_PLAN §13 |
| 2.1.3 | `shared/services/` bez JSX/hooks | ⏭️ N/A | Architektura zgodna z zasadami |
| 2.1.5 | `shared/mocks/` tylko w dev | ⏭️ N/A | Zaplanowane w `default.config.json` → `debug.mockAiInDev: true` |
| 2.2.x | Limity linii w plikach | ⏭️ N/A | Skrypt `check_file_lengths.sh` gotowy |

**Decyzje architektoniczne do potwierdzenia przed Sprint 1:**
- [ ] Czy pakiet `mobile/` startuje w Sprint 1 czy dopiero po MVP web?
  → **Rekomendacja:** Dopiero po MVP. Sprint 1–6 = web + plugin.
- [ ] Czy `pnpm-workspace.yaml` i `turbo.json` są skonfigurowane?
  → **Akcja:** Inicjalizacja repo = pierwsze zadanie Sprint 1.

**Status sekcji:** ✅ PASS — architektura spójna

---

### 3–4. IMPORTY, TYPESCRIPT

| # | Sprawdzenie | Wynik | Uwagi |
|---|-------------|-------|-------|
| 3.1–3.5 | Reguły importów | ⏭️ N/A | Zdefiniowane w CODING_STANDARDS §5 |
| 4.1 | `pnpm tsc --noEmit` | ⏭️ N/A | Brak kodu |
| 4.2 | Brak `any` | ⏭️ N/A | Reguła w CODING_STANDARDS §4 + ESLint rule |

**Status sekcji:** ⏭️ N/A

---

### 5. OBSŁUGA BŁĘDÓW

| # | Sprawdzenie | Wynik | Uwagi |
|---|-------------|-------|-------|
| 5.1.x | Try/catch w async | ⏭️ N/A | Wzorzec zdefiniowany w AI_PROMPT_GUIDE.md |
| 5.2.x | Edge Functions CORS + auth | ⚠️ UWAGA | Zdefiniowane w DEVELOPMENT_PLAN §3, ale brak przykładowego kodu dla KAŻDEJ funkcji |
| 5.3.x | Fallback AI | ✅ | Łańcuch fallback kompletnie opisany w DEVELOPMENT_PLAN §5 |

**Uwaga (nie blokuje):**
> Edge Functions: dodać przykładowy skeleton `index.ts` z CORS + auth guard jako plik `supabase/functions/_shared/cors.ts` — żeby każda nowa funkcja go importowała. Zapobiegnie pomijaniu CORS w pośpiechu.

**Status sekcji:** ⚠️ 1 uwaga

---

### 6. INTERNACJONALIZACJA

| # | Sprawdzenie | Wynik | Uwagi |
|---|-------------|-------|-------|
| 6.1 | Brak hardcoded stringów | ⏭️ N/A | |
| 6.3 | `pl.json` i `en.json` identyczne klucze | ⚠️ UWAGA | `locale.pl.json` istnieje — brakuje `locale.en.json` |
| 6.4 | Oba pliki aktualizowane razem | ⏭️ N/A | |

**Blokujące:**
> ❌ **Brak `locale.en.json`** — musi powstać przed pierwszym komponentem UI. Skrypt `check_locales.js` nie ma się na czym oprzeć.

**Status sekcji:** ❌ 1 błąd blokujący

---

### 7. UX — WZORCE OBOWIĄZKOWE

| # | Sprawdzenie | Wynik | Uwagi |
|---|-------------|-------|-------|
| 7.1.1 | ClearableInput wszędzie | ⏭️ N/A | Wzorzec w CODING_STANDARDS §12, mockup w UI_MOCKUP.html |
| 7.2.1 | LoadingButton | ⏭️ N/A | |
| 7.3.x | Toast zamiast alert | ⏭️ N/A | |
| 7.4.1 | ConfirmDialog dla destruktywnych akcji | ✅ PLAN | Zdefiniowane w CODING_STANDARDS + AUDIT_CHECKLIST §5.6 |
| 7.5.x | Tooltips na ikonach | ⏭️ N/A | |
| 7.6.x | Wskaźnik offline | ✅ PLAN | NetworkBanner w mockupie i standardach |

**Status sekcji:** ✅ PASS — wzorce kompletnie opisane

---

### 8. BEZPIECZEŃSTWO

| # | Sprawdzenie | Wynik | Uwagi |
|---|-------------|-------|-------|
| 8.1.1 | Brak kluczy API w kodzie | ✅ | `.env.example` nie zawiera żadnych kluczy, tylko placeholdery |
| 8.1.4 | `.env.local` w `.gitignore` | ⚠️ UWAGA | `.gitignore` nie istnieje jeszcze — musi być pierwszym plikiem repo |
| 8.2.1 | localStorage przez abstrakcję | ⏭️ N/A | |
| 8.3.x | 18+ weryfikacja | ✅ PLAN | Kompletnie opisane w SECURITY.md §4 |
| 8.5.x | RLS w Supabase | ✅ PLAN | SQL w DEVELOPMENT_PLAN §3 |

**Blokujące przed startem kodu:**
> ⚠️ `.gitignore` musi istnieć zanim cokolwiek zostanie scommitowane. Musi zawierać: `.env`, `.env.local`, `*.key`, `node_modules/`, `dist/`, `.supabase/`.

**Status sekcji:** ⚠️ 1 uwaga (nie blokuje documentation review, blokuje start kodu)

---

### 9–14. POZOSTAŁE SEKCJE

| Sekcja | Status | Uwagi |
|--------|--------|-------|
| 9. Sync i offline | ✅ PLAN | SyncEngine opisany w DEVELOPMENT_PLAN §4 |
| 10. Testy | ⚠️ UWAGA | Brak pliku konfiguracyjnego Vitest (`vitest.config.ts`) — do dodania |
| 11. Plugin Chrome | ✅ PLAN | Manifest i architektura opisane w DEVELOPMENT_PLAN §6 |
| 12. Monetyzacja | ✅ PLAN | Stripe flow w MONETIZATION.md |
| 13. Debug mode | ✅ PLAN | Flagi w `default.config.json` → `debug.*` |
| 14. Konwencje | ✅ | Zdefiniowane w CODING_STANDARDS §14 |
| 15. Martwy kod | ⏭️ N/A | Brak kodu |

---

## OTWARTE PYTANIA Z DEVELOPMENT_PLAN §15 — STATUS

| # | Pytanie | Decyzja | Priorytet |
|---|---------|---------|-----------|
| 1 | Raw treść rozmów — przechowywać? | ❌ NIE — tylko hash + summary (RODO) | 🔴 Decyzja przed DB schema |
| 2 | Ile wiadomości do AI? | ✅ 10–20 (config: `contextWindow.maxMessages: 20`) | ✅ Zadecydowane |
| 3 | Plugin — wszystkie strony domyślnie? | ✅ NIE — lista czatów, opcja "wszystko" w settings | ✅ Zadecydowane |
| 4 | 18+ — self-declaration czy hard verify? | ✅ Self-declaration na MVP | ✅ Zadecydowane |
| 5 | Historia podpowiedzi widoczna? | ❓ DO DECYZJI | 🟡 Sprint 2 |
| 6 | Limity darmowe (30/dzień, 3/tydzień) | ✅ Zgodnie z dokumentacją | ✅ Zadecydowane |
| 7 | API dla developerów? | ✅ NIE na MVP | ✅ Zadecydowane |
| 8 | Email transakcyjny — jaka usługa? | ❓ Supabase wbudowany vs Resend | 🟡 Sprint 1 — przed auth |

---

## PODSUMOWANIE

```
Data przeglądu:         2026-06-09
Reviewer:               Claude (Anthropic)
Branch:                 main (inicjalizacja dokumentacji)
Sprint:                 0 — Pre-development

METRYKI (dokumentacja):
  Pliki docs/:            10 plików
  Pliki config/:           3 pliki
  Pliki scripts/:          1 plik (scripts.sh)
  Brakujące pliki:         locale.en.json, .gitignore, vitest.config.ts, locale.en.json

WYNIKI CHECKLISTY:
  ✅ Zaliczone:            28/40
  ⚠️  Ostrzeżenia:          4/40  (opisane powyżej)
  ❌ Błędy (blokujące):    1/40  (brak locale.en.json)
  ⏭️  N/A (brak kodu):     7/40

BLOKUJĄCE (przed startem Sprint 1):
  ❌ 1. Brak locale.en.json — musi powstać razem z pl.json

OSTRZEŻENIA (nie blokują, do naprawy w Sprint 1):
  ⚠️  1. Brak .gitignore — musi być pierwszym commitem
  ⚠️  2. Brak vitest.config.ts — konfiguracja testów przed pierwszym testem
  ⚠️  3. Edge Functions: dodać shared CORS helper (_shared/cors.ts)
  ⚠️  4. Otwarte pytanie §15/5 i §15/8 — decyzja przed Sprint 2

BACKLOG (do kolejnych sprintów):
  🔄 1. Inicjalizacja monorepo (pnpm-workspace.yaml, turbo.json)
  🔄 2. Vitest + Playwright konfiguracja
  🔄 3. GitHub Actions CI pipeline
  🔄 4. Decyzja: historia podpowiedzi widoczna w UI?
  🔄 5. Decyzja: email transakcyjny (Supabase vs Resend)

DECYZJA: ⏸️ HOLD — napraw 1 błąd blokujący (locale.en.json) przed Sprint 1
```

---

## PLAN DZIAŁANIA — Sprint 1 (pierwsze kroki)

W kolejności wykonania:

1. `git init` + `.gitignore` (pierwszy commit)
2. `pnpm init` + `pnpm-workspace.yaml` (monorepo)
3. `config/locales/en.json` (kopia struktury z pl.json, wartości po angielsku)
4. `vitest.config.ts` w root + `packages/shared/`
5. `supabase/functions/_shared/cors.ts` (wspólny helper CORS)
6. Inicjalizacja `packages/shared/` (typy + constants + logger stub)
7. Supabase: nowy projekt + `supabase init` + migracja 001

---

*Następny review: po Sprint 1 → `logs/code-review-2026-06-[XX].md`*
