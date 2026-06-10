# ContextCompass

> **AI asystent kontekstu rozmów** — plugin Chrome/Edge + PWA + aplikacja mobilna  
> Wersja dokumentacji: 1.0.0 | Status: Pre-development / Planning

---

## Czym jest ContextCompass?

ContextCompass to narzędzie, które pamięta kontekst Twoich rozmów z konkretnymi osobami i podpowiada Ci, **co i jak odpowiedzieć** — w czasie rzeczywistym, z prawym przyciskiem myszy lub przez wklejenie tekstu. Działa jako:

- **Plugin przeglądarkowy** (Chrome/Edge, Manifest V3) — integracja z WhatsApp Web, Messenger, Discord i innymi
- **PWA** — instalowalna aplikacja webowa (desktop + mobile)
- **Aplikacja mobilna** (React Native, docelowo) — pełen dostęp natywny

Projekt jest skierowany do każdego, kto chce świadomie prowadzić rozmowy: romantyczne, zawodowe, towarzyskie czy erotyczne (dla zweryfikowanych dorosłych).

---

## Najważniejsze funkcje

| Moduł | Opis |
|---|---|
| **Profile rozmówców** | Dodaj osobę, opisz relację, wybierz template (randka, praca, znajomy, 18+) |
| **Własny profil** | Dane osobowe, typ osobowości, cechy — aktualizowane przez AI automatycznie (batch) |
| **Podpowiedzi real-time** | Zaznacz tekst → prawy przycisk → propozycje odpowiedzi z wyjaśnieniem |
| **Analiza rozmowy** | Wklej całą rozmowę → otrzymaj raport: co robisz dobrze, co źle, styl rozmówcy |
| **Nagrywanie głosu** | Dyktowanie notatek, kontekstu lub treści rozmowy (Web Speech API) |
| **Offline-first** | Działa bez internetu; synchronizacja z Supabase w tle |
| **AI fallback chain** | Gemini → Groq → OpenAI (własny klucz) → szablony offline |
| **Weryfikacja 18+** | Aktywuje zaawansowane tryby (romantyczny, erotyczny) |
| **Backup** | Automatyczny export do Google Drive / ZIP |
| **Premium** | 1,99 zł/mies. — nielimitowane AI, zaawansowane analizy, pełne szablony |

---

## Technologie

```
Frontend:     React 18 + Vite + TypeScript + TailwindCSS (PWA)
              Web Components + Manifest V3 (plugin)
              React Native (mobile, docelowo)

Backend:      Supabase (auth, PostgreSQL, storage, edge functions, realtime)

AI:           Google Gemini 1.5 Flash (darmowe, default)
              Groq (fallback)
              OpenAI GPT-4o-mini (własny klucz / premium)

Testy:        Vitest (unit), Playwright (e2e PWA), Puppeteer (plugin)

Monorepo:     pnpm workspaces
```

---

## Struktura repozytorium (monorepo)

```
contextcompass/
├── packages/
│   ├── shared/           # typy TS, serwisy (AI, sync, logger), stałe, moduły
│   ├── web/              # React PWA (Vite)
│   ├── extension/        # Plugin Chrome/Edge (Manifest V3)
│   └── mobile/           # React Native (planowany)
├── supabase/
│   ├── migrations/       # SQL schema
│   ├── seed/             # dane testowe
│   └── functions/        # Edge Functions (ai-proxy, analyze, error-log)
├── config/
│   ├── default.json      # globalne wartości domyślne
│   ├── locales/          # pl.json, en.json
│   └── themes/           # dark.json, light.json (nadpisania Tailwind)
├── docs/                 # dokumentacja (ten folder)
├── scripts/              # narzędzia dev (nagłówki, testy, deploy)
├── .env.example
├── pnpm-workspace.yaml
└── README.md
```

---

## Szybki start (development)

```bash
git clone https://github.com/twoja_nazwa/contextcompass.git
cd contextcompass
pnpm install

# Konfiguracja zmiennych środowiskowych
cp .env.example .env
# Uzupełnij: VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY, GEMINI_API_KEY

# Uruchomienie lokalnej bazy Supabase
npx supabase start

# Uruchomienie PWA (dev)
pnpm dev:web

# Build pluginu i załadowanie do Chrome
pnpm build:extension
# Otwórz chrome://extensions → "Załaduj rozpakowane" → wskaż dist/extension/
```

---

## Dokumentacja

| Plik | Zawartość |
|---|---|
| `docs/DEVELOPMENT_PLAN.md` | Architektura, schemat DB, harmonogram, moduły |
| `docs/CODING_STANDARDS.md` | Zasady kodu, nagłówki, error handling — dla AI i ludzi |
| `docs/AI_PROMPT_GUIDE.md` | Jak komunikować się z Claude/Gemini w kontekście tego projektu |
| `docs/SECURITY.md` | Polityka 18+, auto-logout, szyfrowanie, screenshoty |
| `docs/MONETIZATION.md` | Model freemium, Stripe, limity, roadmapa premium |
| `config/default.json` | Domyślna konfiguracja aplikacji |

---

## Status projektu

- [x] Dokumentacja i planowanie (v1.0)
- [ ] Backend Supabase: schema, auth, RLS, edge functions
- [ ] PWA: routing, i18n, motywy, ekrany bazowe
- [ ] Plugin: manifest, content script, context menu
- [ ] Integracja AI (fallback chain)
- [ ] Logowanie błędów + webhook
- [ ] Testy jednostkowe i E2E
- [ ] Abonament Premium (Stripe)
- [ ] React Native MVP

---

## Licencja

Własna licencja komercyjna — wszelkie prawa zastrzeżone.  
Kontakt: [twój@email.pl]
