<!-- =============================================================================
 FILE: README.md
 PATH: docs/README.md
 VERSION: 0.1.0
 PURPOSE: Indeks i przewodnik po dokumentacji projektu KlassMate.
 FUNCTIONS: -
 DEPENDS ON: (root document)
 ============================================================================= -->

# KlassMate — Dokumentacja projektu

> **Aplikacja dla klas szkolnych:** bezpieczna, moderowana wymiana informacji o zadaniach domowych.
> Stack: React Native + Expo · Supabase (Frankfurt) · TypeScript · Zustand

---

## Jak czytać tę dokumentację

Czytaj w kolejności numerycznej przy onboardingu. Każdy plik wskazuje pliki od których zależy (`@dependsOn`).
Przy codziennej pracy — sięgaj do konkretnego dokumentu wg tabeli poniżej.

| Plik | Zawartość | Kto czyta |
|------|-----------|-----------|
| `00_PROJECT_OVERVIEW.md` | Cel, stack, analiza rynku, **pytania do właściciela** | Wszyscy — NAJPIERW |
| `01_ARCHITECTURE.md` | Schema DB, struktura plików, przepływy auth i moderacji | Backend, fullstack |
| `01b_ARCHITECTURE_SUPPLEMENT.md` | Sortowanie, modały, logi in-app, tabela reminders | Backend, fullstack |
| `02_CODE_STANDARDS.md` | Nagłówki plików, nazewnictwo, długość, TypeScript | Każdy piszący kod |
| `03_AI_RULES.md` | **CZYTAJ NAJPIERW jeśli jesteś modelem AI** — co robić, czego nie | Modele AI |
| `04_SECURITY.md` | Biometria, sesje, 2FA, screenshot prevention, moderacja | Security, fullstack |
| `05_LEGAL_COMPLIANCE.md` | RODO, zgoda rodziców <16 lat, prawa autorskie, DSA | Właściciel, prawnik |
| `06_FEATURES_SPEC.md` | Help system, onboarding, toast messages, UX flows, OCR | Frontend, design |
| `07_TESTING_AND_DEBUG.md` | Testy, debug panel, mocki, seed data, Sentry | QA, fullstack |
| `08_ROADMAP_AND_MONETISATION.md` | Fazy, MVP, RevenueCat, freemium 1.99 PLN | Właściciel, PM |
| `09_NOTIFICATIONS_AND_REMINDERS.md` | Push, in-app, reminder CRON, permission flow | Backend, fullstack |
| `CODE_REVIEW_CHECKLIST.md` | 102-punktowy przegląd przed mergem → wynik do `logs/` | Reviewer, AI |
| `AUDIT_CHECKLIST.md` | 86-punktowy audyt przed release → wynik do `logs/` | Lead, AI |
| `UI_UX_MOCKUP.html` | Interaktywny mockup HTML (zamiast Figmy) — 8 ekranów | Frontend, design |
| `GRAPHICS_PLAN.md` | Plan grafik P0/P1/P2, prompty AI, fallbacki, narzędzia | Designer, właściciel |

---

## Pliki poza `docs/`

| Plik | Opis |
|------|------|
| `CHANGELOG.md` | Historia zmian projektu (Keep a Changelog format) |
| `.env.example` | Szablon zmiennych środowiskowych — skopiuj do `.env.development` |
| `logs/YYYY-MM-DD_code_review_*.md` | Wyniki przeglądów kodu |
| `logs/YYYY-MM-DD_audit_*.md` | Wyniki audytów projektu |

---

## Kluczowe decyzje architektoniczne

| Decyzja | Wybór | Powód |
|---------|-------|-------|
| Stack mobilny | React Native + Expo SDK 52 | Jeden kod na iOS + Android + Web (PWA) |
| Backend | Supabase, region `eu-central-1` (Frankfurt) | EU data residency, RLS, Realtime, Auth OAuth |
| Moderacja | Server-side Edge Function (Deno) | Klient nie jest zaufany — moderacja przed zapisem do DB |
| Tokeny sesji | `expo-secure-store` (Keychain/Keystore) | Nie AsyncStorage — OS-level encryption |
| OCR | Tesseract.js (offline) + OCR.space fallback | Zero kluczy API dla 10-letniego użytkownika |
| Modały | Własny `Modal` komponent | Zero `window.alert/confirm/prompt` i `Alert.alert` |
| Sortowanie | Persystowane w `profiles.settings` JSONB | Sync między urządzeniami bez osobnej tabeli |
| Błędy zdalne | Sentry (EU) + Supabase `error_reports` | RODO-safe: hash user_id, bez PII, bez treści wiadomości |
| Subskrypcje | RevenueCat | Obsługuje App Store + Google Play w jednym SDK |
| Reklamy | AdMob child-directed NPA | COPPA/GDPR-K compliant dla aplikacji dla dzieci |

---

## Otwarte pytania (wymagają odpowiedzi właściciela)

Pełna lista w `00_PROJECT_OVERVIEW.md` sekcja 9. Najważniejsze 3:

1. **Mechanizm zgody rodziców** — wariant A (email link) / B (konto rodzica) / C (admin vouch)?
2. **Kto może być Class Admin** — każdy uczeń / tylko nauczyciel / uczeń zatwierdzony przez nauczyciela?
3. **Nazwa aplikacji** — wpływa na bundle ID, domenę, projekt Supabase

---

## Quick Start dla dewelopera

```bash
# 1. Klonuj repo
git clone https://github.com/[owner]/klassmatch.git && cd klassmatch

# 2. Zainstaluj zależności
npm install

# 3. Skopiuj i uzupełnij env
cp .env.example .env.development
# Uzupełnij: EXPO_PUBLIC_SUPABASE_URL, EXPO_PUBLIC_SUPABASE_ANON_KEY

# 4. Resetuj lokalną bazę (ładuje też dev_seed.sql z danymi testowymi)
npx supabase db reset

# 5. Włącz tryb debug (opcjonalne)
echo "EXPO_PUBLIC_DEBUG_MODE=true" >> .env.development
echo "EXPO_PUBLIC_MOCK_MODERATION=true" >> .env.development

# 6. Uruchom
npx expo start

# 7. Uruchom testy
npm test                        # Jest (unit + component)
deno test supabase/functions/   # Edge Functions
npm run typecheck               # tsc --noEmit
```

Przycisk 🐛 **Debug** pojawia się w dolnej nawigacji przy `DEBUG_MODE=true`.

---

## Jak uruchamiać Code Review i Audit

```bash
# Code Review — przed każdym merge do main/develop
# 1. Otwórz docs/CODE_REVIEW_CHECKLIST.md
# 2. Przejdź przez punkty dla zmienionych plików
# 3. Skopiuj tabelę wyników z końca dokumentu
# 4. Zapisz jako: logs/YYYY-MM-DD_code_review_BRANCH-NAME.md

# Audit — przed każdym release lub końcem sprintu
# 1. Otwórz docs/AUDIT_CHECKLIST.md
# 2. Przejdź przez wszystkie sekcje
# 3. Skopiuj tabelę podsumowania z końca dokumentu
# 4. Zapisz jako: logs/YYYY-MM-DD_audit_SPRINT-NAME.md

# Przykładowe wypełnione raporty:
# logs/2026-06-10_code_review_feat-auth-biometrics.md
# logs/2026-06-10_audit_sprint1_pre-beta.md
```

---

## Aktualizacja mockupu UI/UX

`docs/UI_UX_MOCKUP.html` aktualizowany jest **na końcu każdego sprintu**:

1. Przejrzyj commity sprintu (`git log --oneline sprint-start..HEAD`)
2. Zaktualizuj ekrany które się zmieniły
3. Dodaj nowe ekrany dla nowych features
4. Oznacz nieaktywne features jako "Wkrótce" (szary label)
5. Zaktualizuj komentarz `<!-- VERSION -->` i datę w nagłówku pliku

