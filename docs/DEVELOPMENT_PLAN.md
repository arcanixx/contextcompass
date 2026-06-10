# DEVELOPMENT_PLAN.md — ContextCompass

> Plan architektoniczny i implementacyjny. Przeznaczony dla programistów i modeli AI pracujących nad projektem.  
> Ostatnia aktualizacja: v1.0.0

---

## Spis treści

1. [Decyzje architektoniczne](#1-decyzje-architektoniczne)
2. [Stos technologiczny — uzasadnienie](#2-stos-technologiczny--uzasadnienie)
3. [Backend — Supabase](#3-backend--supabase)
4. [Synchronizacja i offline-first](#4-synchronizacja-i-offline-first)
5. [Moduł AI — fallback chain](#5-moduł-ai--fallback-chain)
6. [Plugin Chrome/Edge (Manifest V3)](#6-plugin-chromeedge-manifest-v3)
7. [PWA (React + Vite)](#7-pwa-react--vite)
8. [Aplikacja mobilna (React Native)](#8-aplikacja-mobilna-react-native)
9. [Moduły funkcjonalne — szczegóły](#9-moduły-funkcjonalne--szczegóły)
10. [Bezpieczeństwo i prywatność](#10-bezpieczeństwo-i-prywatność)
11. [Logowanie błędów](#11-logowanie-błędów)
12. [Monetyzacja — implementacja](#12-monetyzacja--implementacja)
13. [Struktura plików — pełna mapa](#13-struktura-plików--pełna-mapa)
14. [Harmonogram MVP — 6 tygodni](#14-harmonogram-mvp--6-tygodni)
15. [Otwarte pytania i decyzje](#15-otwarte-pytania-i-decyzje)

---

## 1. Decyzje architektoniczne

Poniżej zebrane ostateczne decyzje projektowe wraz z uzasadnieniem.

| Decyzja | Wybór | Uzasadnienie |
|---|---|---|
| Synchronizacja | Supabase + IndexedDB (offline-first) | Supabase = źródło prawdy, IndexedDB = cache lokalny; działa bez sieci |
| Domyślny AI | Google Gemini 1.5 Flash | 1500 req/dzień za darmo, dobra jakość, szybki |
| AI fallback | Gemini → Groq → własny klucz → szablon | Minimalne zakłócenia dla użytkownika; zmiana transparentna |
| Plugin zasięg | Wszystkie strony + dedykowane domeny czatów | Elastyczność: domyślnie lista czatów, opcja "wszystko" w ustawieniach |
| Logowanie błędów | Tabela Supabase `error_logs` + webhook POST | Centralnie, bez dodatkowych usług; webhook dla alertów real-time |
| Mobilne — start | PWA (bez React Native) | Szybszy start, współdzielony kod z web; natywne RN gdy potrzeba screenshots lock |
| Aktualizacja profilu | Batch co 5–10 rozmów, jeden modal z listą zmian | Minimalna liczba potwierdzeń; nie przeszkadza w prowadzeniu rozmowy |
| Klucze API | Tylko w Edge Functions (serwer) | Żadnego klucza w kodzie klienta ani w config repo |
| Screenshoty | Alert (web/PWA) + `FLAG_SECURE` (React Native) | Web nie może zablokować 100%; alert odstrasza; natywne blokuje |
| Abonament | Stripe (1,99 zł/mies.) | Prosty checkout, obsługuje PLN, łatwa integracja webhooków |

---

## 2. Stos technologiczny — uzasadnienie

### Frontend wspólny
- **React 18** — ekosystem, hooks, Suspense, concurrent rendering
- **TypeScript** — wymagane; zero `any`, strict mode
- **TailwindCSS** — utility-first; motyw jasny/ciemny bez osobnych plików CSS
- **Vite** — szybki HMR, świetna obsługa PWA przez `vite-plugin-pwa`
- **i18next** — obsługa wielu języków (pl, en); klucze, nie stringi w kodzie

### Monorepo
- **pnpm workspaces** — szybki, efektywny, natywne linki pakietów
- Wspólny package `shared` zawiera: typy, serwisy, stałe, mocki — importowany przez `web`, `extension`, `mobile`

### Backend
- **Supabase** — auth (JWT), PostgreSQL, Storage, Realtime, Edge Functions (Deno)
- Row Level Security (RLS) — każdy użytkownik widzi tylko swoje dane; zero custom middleware autoryzacji

### AI
- **Google AI SDK** (`@google/generative-ai`) — dla Gemini
- **Groq SDK** — dla Groq Llama
- **OpenAI SDK** — dla własnych kluczy użytkownika
- Wszystkie wywołania AI **wyłącznie przez Edge Function `ai-proxy`** — klucze nie wyciekają

### Testy
- **Vitest** — testy jednostkowe (pakiet `shared` i `web`)
- **Playwright** — E2E testy PWA (Chrome, Firefox)
- **Puppeteer** — testy pluginu (załadowanie do Chrome, content script)

---

## 3. Backend — Supabase

### Schema bazy danych

```sql
-- =============================================================
-- TABELA: profiles (rozszerza auth.users Supabase)
-- =============================================================
CREATE TABLE profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  full_name       TEXT,
  display_name    TEXT,           -- nazwa wyświetlana w UI
  age             INT CHECK (age >= 13 AND age <= 120),
  city            TEXT,
  height_cm       INT CHECK (height_cm BETWEEN 50 AND 300),
  weight_kg       NUMERIC(5,1) CHECK (weight_kg BETWEEN 20 AND 500),
  personality_type TEXT,          -- np. INTJ, ENFP, lub opis własny
  gender          TEXT,           -- 'male', 'female', 'non_binary', 'other', null
  ai_insights     JSONB DEFAULT '[]',  -- [{trait: string, confidence: 0-1, source: 'auto'|'manual'}]
  verified_18plus BOOLEAN DEFAULT FALSE,
  premium_until   TIMESTAMPTZ,
  trusted_devices JSONB DEFAULT '[]',  -- [{device_id, name, last_used, user_agent}]
  settings        JSONB DEFAULT '{}',  -- {theme, language, notifications, voiceInput, ...}
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Automatyczne wypełnienie profilu po rejestracji
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO profiles (id, display_name)
  VALUES (NEW.id, SPLIT_PART(NEW.email, '@', 1));
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();


-- =============================================================
-- TABELA: contacts (profile rozmówców)
-- =============================================================
CREATE TABLE contacts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles ON DELETE CASCADE,
  name            TEXT NOT NULL,
  nickname        TEXT,
  context         TEXT,           -- opis relacji z tą osobą (co wiadomo, jaki cel)
  template_type   TEXT DEFAULT 'general',  -- 'general', 'romantic', 'work', 'friend', 'erotic' (18+)
  tags            TEXT[] DEFAULT '{}',
  style_prefs     JSONB DEFAULT '{}',  -- {tone: 'casual'|'formal', humor: bool, ...}
  summary         TEXT,           -- podsumowanie AI, aktualizowane co 10 wymian
  summary_updated TIMESTAMPTZ,
  is_archived     BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);


-- =============================================================
-- TABELA: conversation_messages
-- =============================================================
CREATE TABLE conversation_messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id      UUID NOT NULL REFERENCES contacts ON DELETE CASCADE,
  role            TEXT NOT NULL CHECK (role IN ('user', 'other')),  -- user = ja, other = rozmówca
  content         TEXT NOT NULL,
  source          TEXT DEFAULT 'text',  -- 'text', 'voice', 'paste'
  ai_note         TEXT,           -- opcjonalna adnotacja AI (np. "tu byłeś agresywny")
  created_at      TIMESTAMPTZ DEFAULT NOW()
);


-- =============================================================
-- TABELA: analysis_reports (pełne analizy rozmów)
-- =============================================================
CREATE TABLE analysis_reports (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id      UUID NOT NULL REFERENCES contacts ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles ON DELETE CASCADE,
  strengths       TEXT,           -- co robię dobrze
  weaknesses      TEXT,           -- co robię źle
  other_insights  TEXT,           -- styl i preferencje rozmówcy
  recommendations TEXT,           -- konkretne sugestie na przyszłość
  sentiment_score NUMERIC(4,3),   -- -1 do 1 (opcjonalne, premium)
  raw_input_hash  TEXT,           -- hash wklejonej rozmowy (nie przechowujemy raw)
  created_at      TIMESTAMPTZ DEFAULT NOW()
);


-- =============================================================
-- TABELA: ai_suggestions (historia podpowiedzi)
-- =============================================================
CREATE TABLE ai_suggestions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id      UUID NOT NULL REFERENCES contacts ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles ON DELETE CASCADE,
  input_text      TEXT,           -- fragment, na który zapytano o podpowiedź
  suggestions     JSONB,          -- [{text, tone, confidence}]
  chosen_index    INT,            -- który wariant użytkownik wybrał (null = żaden)
  created_at      TIMESTAMPTZ DEFAULT NOW()
);


-- =============================================================
-- TABELA: error_logs
-- =============================================================
CREATE TABLE error_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES profiles,  -- null = anonimowy
  error_message   TEXT NOT NULL,
  error_code      TEXT,
  stack_trace     TEXT,
  context         JSONB,          -- {url, version, platform, action}
  app_version     TEXT,
  platform        TEXT,           -- 'web', 'extension', 'mobile'
  resolved        BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);


-- =============================================================
-- TABELA: profile_update_proposals (batch aktualizacje profilu)
-- =============================================================
CREATE TABLE profile_update_proposals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles ON DELETE CASCADE,
  proposals       JSONB NOT NULL,  -- [{trait, value, reason, confidence}]
  source_contacts UUID[],          -- z których rozmów wyciągnięto wnioski
  status          TEXT DEFAULT 'pending',  -- 'pending', 'accepted', 'rejected'
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
```

### Row Level Security (RLS)

```sql
-- Włączenie RLS na wszystkich tabelach
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE analysis_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_update_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;

-- profiles: użytkownik widzi i edytuje tylko swój profil
CREATE POLICY "Own profile only" ON profiles
  FOR ALL USING (auth.uid() = id);

-- contacts: tylko własne
CREATE POLICY "Own contacts" ON contacts
  FOR ALL USING (auth.uid() = user_id);

-- conversation_messages: przez contact_id
CREATE POLICY "Own messages" ON conversation_messages
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM contacts c
      WHERE c.id = contact_id AND c.user_id = auth.uid()
    )
  );

-- error_logs: INSERT dla wszystkich zalogowanych, SELECT tylko service_role
CREATE POLICY "Insert own errors" ON error_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);
```

### Edge Functions

#### `supabase/functions/ai-proxy/index.ts`
Przyjmuje `{messages, contactId, mode}` gdzie `mode` to `hint|analysis|profile_update`.
- Odczytuje kontekst użytkownika (profil + summary kontaktu)
- Buduje prompt systemowy
- Wywołuje AI według fallback chain
- Zwraca ustrukturyzowaną odpowiedź JSON

#### `supabase/functions/analyze-conversation/index.ts`
Uruchamiana ręcznie lub przez klienta.
- Przyjmuje `{contactId, rawConversation}`
- Generuje pełny raport analityczny
- Zapisuje do `analysis_reports`

#### `supabase/functions/log-error/index.ts`
Publiczny endpoint (bez auth) do przyjmowania błędów.
- Zapisuje do `error_logs`
- Opcjonalnie wysyła webhook do autora (POST na skonfigurowany URL)

#### `supabase/functions/update-contact-summary/index.ts`
Cron lub wyzwalany po 10 nowych wiadomościach.
- Bierze ostatnie N wiadomości dla `contactId`
- Generuje nowe podsumowanie AI
- Aktualizuje `contacts.summary`

---

## 4. Synchronizacja i offline-first

### Strategia

```
[Akcja użytkownika]
        ↓
[IndexedDB — zapis lokalny, natychmiastowy]
        ↓
[Kolejka synchronizacji (SyncQueue)]
        ↓
[Sieć dostępna?]
   Tak → POST/PATCH do Supabase → oznacz jako zsynchronizowane
   Nie → zostaje w kolejce; retry przy powrocie sieci
```

### Obsługa konfliktów
- **Strategia**: Last Write Wins (LWW) na podstawie `updated_at`
- Przy konflikcie wyświetl toast: "Znaleziono zmiany z innego urządzenia — użyto najnowszej wersji"
- Brak per-field merge na start (zbyt złożone dla MVP)

### Wskaźnik sieci
- Globalny hook `useNetworkStatus` nasłuchuje na `online`/`offline` events przeglądarki
- W UI: czerwona ikona + toast "Brak połączenia — pracujesz offline"
- Supabase Realtime automatycznie wznawia połączenie po powrocie sieci

### Implementacja — kluczowe pliki

```
packages/shared/services/
├── syncEngine.ts       # SyncEngine class — kolejka, retry, konflikty
├── localStore.ts       # Abstrakcja nad IndexedDB (używa idb library)
├── supabaseClient.ts   # Singleton klienta Supabase
└── networkMonitor.ts   # useNetworkStatus hook + EventEmitter
```

---

## 5. Moduł AI — fallback chain

### Kolejność wyboru modelu (priorytet)

```
1. Własny klucz OpenAI (jeśli użytkownik podał w ustawieniach)
2. Własny klucz Claude (jeśli podał)
3. Premium abonament → nasz klucz OpenAI GPT-4o-mini
4. Gemini 1.5 Flash (darmowy tier — 1500 req/dzień, 60 req/min)
5. Groq Llama 3.1 70B (darmowy, limit 30 req/min)
6. Szablon offline (regex + słownik bez AI) — z komunikatem dla użytkownika
```

### Implementacja w Edge Function `ai-proxy`

```typescript
// Logika wyboru modelu (pseudokod)
async function selectModel(userId: string): Promise<AIProvider> {
  const profile = await getProfile(userId);
  const usage = await getDailyUsage(userId);

  if (profile.settings.openai_key) return new OpenAIProvider(profile.settings.openai_key);
  if (profile.settings.claude_key) return new ClaudeProvider(profile.settings.claude_key);
  if (isPremium(profile)) return new OpenAIProvider(env.OUR_OPENAI_KEY);
  if (usage.gemini_today < 1500) return new GeminiProvider(env.GEMINI_KEY);
  if (usage.groq_today < 1000) return new GroqProvider(env.GROQ_KEY);
  return new TemplateFallbackProvider();
}
```

### Informowanie użytkownika o fallbacku

- Toast nieagresywny: "Używamy teraz Groq (darmowy limit Gemini wyczerpany)"
- W ustawieniach: widoczny wykres dziennego zużycia limitów
- Przy fallbacku do szablonu: wyraźna informacja i przycisk "Kup Premium"

### Budowniciel promptów

```
packages/shared/services/promptBuilder.ts
```

Odpowiada za:
- Wstrzyknięcie profilu użytkownika (cechy, styl, wiek)
- Wstrzyknięcie kontekstu rozmówcy (summary + template type)
- Wstrzyknięcie ostatnich N wiadomości (max. 20, żeby nie przekroczyć limitu tokenów)
- Wybór odpowiedniego system promptu dla trybu: `hint` / `analysis` / `profile_update`

### Przykładowy system prompt (tryb `hint`)

```
Jesteś asystentem komunikacji. Znasz profil użytkownika:
- Płeć: [gender], Wiek: [age], Typ osobowości: [personality]
- Cechy komunikacyjne: [ai_insights list]

Znasz kontekst rozmowy z [contact_name]:
- Relacja: [template_type]
- Cel: [context]
- Co wiadomo o tej osobie: [summary]

Na podstawie TYLKO tej rozmowy (ignoruj inne osoby), zaproponuj 2-3 warianty odpowiedzi.
Format: JSON [{text, tone, why_this_works}]
```

---

## 6. Plugin Chrome/Edge (Manifest V3)

### Manifest (kluczowe fragmenty)

```json
{
  "manifest_version": 3,
  "name": "ContextCompass",
  "version": "0.1.0",
  "permissions": ["storage", "activeTab", "contextMenus", "scripting"],
  "optional_permissions": ["<all_urls>"],
  "host_permissions": [
    "*://*.web.whatsapp.com/*",
    "*://*.messenger.com/*",
    "*://teams.microsoft.com/*",
    "*://discord.com/*",
    "*://*.telegram.org/*",
    "*://slack.com/*"
  ],
  "background": {
    "service_worker": "background.js",
    "type": "module"
  },
  "content_scripts": [
    {
      "matches": ["*://*.web.whatsapp.com/*", "*://*.messenger.com/*"],
      "js": ["content.js"],
      "run_at": "document_idle"
    }
  ],
  "action": {
    "default_popup": "popup.html",
    "default_icon": { "32": "icons/icon32.png" }
  }
}
```

### Komunikacja (architektura pluginu)

```
[Content Script]          [Service Worker (background)]          [Popup]
      │                              │                               │
      │ chrome.runtime.sendMessage   │                               │
      │ ──────────────────────────►  │                               │
      │ {type:'GET_HINT',text,url}    │                               │
      │                              │ wywołuje Edge Function        │
      │                              │ ◄─────────────────────────── │
      │                              │ (lub z chrome.storage)        │
      │ ◄──────────────────────────  │                               │
      │ {hints: [...]}               │                               │
      │                              │                               │
[UI Overlay na stronie]    [Dane ↔ chrome.storage.local]     [Popup UI (React)]
```

### Content Script — co robi

1. Nasłuchuje zdarzenia `contextmenu` (prawy przycisk) na zaznaczonym tekście
2. Dodaje pozycję "ContextCompass — podpowiedź" do menu kontekstowego (przez `background.js`)
3. Po kliknięciu: zbiera tekst, wysyła do `background.js`, wyświetla overlay z wynikiem
4. Long press (mobile): `touchstart` + timer 600ms → ten sam flow

### Overlay UI

- Minimalistyczny panel (shadow DOM, żeby nie kolidować z CSS strony)
- Zamykany kliknięciem poza nim lub `Escape`
- Wyświetla 2–3 propozycje odpowiedzi + przycisk "Kopiuj"
- Opcja "Pełna analiza" → otwiera popup lub PWA

### Synchronizacja z PWA

- `chrome.storage.local` jako lokalny store dla pluginu
- `SyncEngine` z pakietu `shared` synchronizuje plugin ↔ Supabase co 30s
- Użytkownik zalogowany raz (popup) — token trzymany w `chrome.storage.local`

---

## 7. PWA (React + Vite)

### Routing

```
/                     → Dashboard (lista kontaktów)
/contacts/:id         → Widok rozmowy z osobą
/contacts/new         → Dodaj nową osobę
/profile              → Własny profil użytkownika
/profile/edit         → Edycja profilu
/analysis/:contactId  → Raport analizy rozmowy
/settings             → Ustawienia (AI, backup, powiadomienia, motyw, 18+)
/settings/subscription → Abonament Premium
/login                → Logowanie / rejestracja
/onboarding           → Onboarding (1–3 krok)
```

### Onboarding (3 ekrany)

1. **Powitalny** — logo, nazwa, tagline, przycisk "Zacznijmy"
2. **Profil bazowy** — imię, płeć, wiek (+ weryfikacja 18+ jeśli >17), miasto (opcjonalne)
3. **Pierwsza osoba** — nazwa rozmówcy, template (randka / praca / znajomy), kontekst

Po onboardingu → Dashboard.

### Komponenty UI (architektura)

```
packages/web/src/
├── components/
│   ├── common/
│   │   ├── Button.tsx            # Button, IconButton, LoadingButton
│   │   ├── Modal.tsx             # Modal bazowy
│   │   ├── Toast.tsx             # System powiadomień
│   │   ├── NetworkBanner.tsx     # Baner "Offline"
│   │   └── ConfirmDialog.tsx     # Modalne potwierdzenie (zamiast alert())
│   ├── contacts/
│   │   ├── ContactCard.tsx       # Karta osoby w liście
│   │   ├── ContactForm.tsx       # Dodaj / edytuj osobę
│   │   └── ContactList.tsx       # Lista wszystkich osób
│   ├── chat/
│   │   ├── MessageBubble.tsx     # Bąbelek wiadomości
│   │   ├── ChatInput.tsx         # Input + mikrofon
│   │   ├── HintPanel.tsx         # Panel z podpowiedziami AI
│   │   └── AnalysisButton.tsx    # Przycisk "Analizuj całą rozmowę"
│   ├── profile/
│   │   ├── ProfileForm.tsx       # Edycja profilu
│   │   ├── InsightsList.tsx      # Lista cech wyciągniętych przez AI
│   │   └── UpdateProposalModal.tsx  # Modal "AI proponuje aktualizacje"
│   └── settings/
│       ├── AISettings.tsx        # Klucze API, wybór modelu
│       ├── BackupSettings.tsx    # Google Drive, ręczny export
│       └── NotificationSettings.tsx
├── hooks/
│   ├── useAuth.ts
│   ├── useContacts.ts
│   ├── useConversation.ts
│   ├── useAI.ts
│   ├── useNetworkStatus.ts
│   └── useProfile.ts
├── pages/
│   ├── Dashboard.tsx
│   ├── Chat.tsx
│   ├── Profile.tsx
│   ├── Analysis.tsx
│   ├── Settings.tsx
│   ├── Login.tsx
│   └── Onboarding.tsx
└── App.tsx
```

---

## 8. Aplikacja mobilna (React Native)

### Strategia wdrożenia

**Faza 1 (MVP):** PWA instalowalna na iOS/Android — wystarczy.  
Zalety: współdzielony kod z web, szybki deploy.  
Wady: brak blokady screenshotów, ograniczony mikrofon w tle.

**Faza 2 (po MVP):** React Native z Expo.  
Kiedy: gdy liczba użytkowników mobilnych > 30% lub zgłoszone problemy z PWA.  
Dodaje: `FLAG_SECURE` (Android), `allowScreenCapture: false` (iOS), lepszy Speech-to-Text.

Kod backendowy i serwisy z pakietu `shared` są identyczne dla obu wersji.

---

## 9. Moduły funkcjonalne — szczegóły

### 9.1. Zarządzanie kontaktami

**Dodawanie osoby:**
- Formularz: nazwa (wymagane), pseudonim (opcjonalne), template (wymagane), kontekst tekstowy (opcjonalne, do 2000 znaków)
- Templates dostępne (z locales):
  - `general` — ogólna rozmowa
  - `friend` — znajomy/koleżanka
  - `romantic` — relacja romantyczna
  - `work` — zawodowa
  - `erotic` — TYLKO dla `verified_18plus` (jeśli nie — modal wyjaśniający)

**Edycja / archiwizacja:**
- Edycja inline kontekstu bez reloadowania strony
- Archiwizacja zamiast usuwania (dane zostają, kontakt znika z głównej listy)
- Modal potwierdzenia przy trwałym usuwaniu

### 9.2. Podpowiedzi (tryb `hint`)

**Przez prawy przycisk (plugin):**
1. Użytkownik zaznacza tekst na stronie czatu
2. Context menu → "ContextCompass — zapytaj o odpowiedź"
3. Overlay pojawia się z loaderem → 2–3 propozycje
4. Kliknij propozycję → kopiuje do schowka + zamyka overlay

**Przez wklejenie w aplikacji:**
1. Otwórz rozmowę z osobą
2. W `ChatInput` wklej lub wpisz tekst
3. Kliknij "Podpowiedź" → panel `HintPanel` otwiera się z prawej
4. Warianty: casualny / formalny / zabawny (zależnie od profilu i template)

**Kontekst używany do podpowiedzi:**
- Summary kontaktu (ostatnio zaktualizowane przez AI)
- Ostatnie 10–20 wiadomości z tym kontaktem
- Profil własny użytkownika (cechy, styl)
- Treść wklejona / zaznaczona

### 9.3. Analiza całej rozmowy (tryb `analysis`)

**Flow:**
1. W widoku rozmowy z osobą → przycisk "Analizuj całą rozmowę"
2. Modal: "Wklej pełny tekst rozmowy" (textarea) lub "Użyj historii z aplikacji"
3. Spinner z komunikatem "Analizuję..." (może trwać 10–30s)
4. Wynik: strona `/analysis/:contactId` z sekcjami:
   - ✅ Co robisz dobrze
   - ⚠️ Co można poprawić (konkretne przykłady)
   - 🧠 Co wiesz o tej osobie po tej rozmowie
   - 💡 Rekomendacje na przyszłość
5. Wynik zapisywany w `analysis_reports`, dostępny w historii

**Limity:**
- Free: 3 analizy tygodniowo
- Premium: bez limitu

### 9.4. Nagrywanie głosowe

**Technologia:** Web Speech API (SpeechRecognition) — działa w Chrome i Edge natywnie, bez kosztów.

**Fallback:** Jeśli Web Speech API niedostępny (Firefox, starsze przeglądarki) → informacja dla użytkownika + sugestia użycia Chrome/Edge.

**Jak działa:**
- Przycisk mikrofonu w `ChatInput` → start nagrania
- Tekst pojawia się w polu w czasie rzeczywistym (interimResults)
- Po zakończeniu (przycisk stop lub cisza 3s) → tekst w polu gotowy do wysłania/analizy

### 9.5. Aktualizacja profilu przez AI (batch)

**Trigger:** po zaakceptowaniu 5–10 nowych wiadomości z dowolnymi kontaktami (liczy się lokalnie, reset co tydzień).

**Flow:**
1. W tle Edge Function `analyze-for-profile-update` zbiera wnioski
2. Tworzy rekord w `profile_update_proposals`
3. W UI: pulsująca ikonka na awatarze profilu
4. Użytkownik otwiera profil → modal `UpdateProposalModal`:
   - Lista proponowanych cech (np. "Często używasz humoru — dodać do profilu?")
   - Checkbox przy każdej cesze
   - Jeden przycisk "Zaakceptuj zaznaczone"
5. Zaakceptowane cechy trafiają do `profiles.ai_insights`

---

## 10. Bezpieczeństwo i prywatność

### Autentykacja

- Supabase Auth: email/hasło, Google OAuth, Apple OAuth
- 2FA przez TOTP (Google Authenticator) — opcjonalne dla użytkownika, sugerowane przy włączaniu trybu 18+
- Token JWT ważny 1h, refresh token ważny 7 dni (zmiana dla zaufanych urządzeń: 30 dni)

### Urządzenia zaufane

- Przy logowaniu: pytanie modalne "Czy to Twoje prywatne urządzenie?"
- TAK → dodaj do `trusted_devices`, refresh token 30 dni, brak auto-logout
- NIE → sesja 15 min, brak zapamiętania, auto-logout po nieaktywności
- Zarządzanie zaufanymi urządzeniami w Ustawieniach (lista + przycisk "Usuń")

### Screenshoty

- **Web/PWA:** nasłuchiwanie na `keydown` (PrintScreen, Cmd+Shift+3/4) → rozmycie UI + toast ostrzeżenia. Nie jest to pełna blokada (nie da się technicznie w web), ale sygnalizuje użytkownikowi.
- **React Native:** Android: `getWindow().setFlags(FLAG_SECURE)` via React Native module. iOS: `allowScreenCapture = false`.

### Szyfrowanie danych lokalnych

- IndexedDB: szyfrowanie AES-GCM przez WebCrypto API (klucz generowany z hasła użytkownika + sól z Supabase)
- Wrażliwe dane (treści rozmów) szyfrowane przed zapisem do IndexedDB
- W Supabase: szyfrowanie danych w spoczynku (wbudowane w platformę)

### Weryfikacja 18+

**Metoda podstawowa (MVP):**
- Formularz: podaj datę urodzenia + oświadczenie (checkbox "Potwierdzam, że mam 18+ lat")
- Nie jest to twarda weryfikacja, ale spełnia standard prawny dla self-declaration
- Pole `age` zapisywane w profilu

**Metoda rozszerzona (przyszłość):**
- Konto Google/Apple z informacją o wieku (jeśli platforma udostępnia)
- Skan dokumentu przez zewnętrzne API weryfikacji tożsamości (np. Yoti, Veriff) — kosztowne, dla wersji komercyjnej

**Blokady bez weryfikacji 18+:**
- Template `erotic` niedostępny w formularzu kontaktu
- System prompt AI nie może generować treści erotycznych
- Słowa kluczowe blokowane w odpowiedziach AI (lista w `config/adult-keywords.json`)

### RODO / GDPR

- Polityka prywatności (wymagana przy rejestracji)
- Prawo do usunięcia konta (cascade delete w DB)
- Export danych: przycisk "Pobierz moje dane" → ZIP z JSON
- Nie przechowujemy raw treści rozmów (tylko hashe i podsumowania AI)
- Lokalizacja danych: region EU w Supabase

---

## 11. Logowanie błędów

### Architektura

```
[Błąd w aplikacji]
        ↓
[captureError() w shared/logger.ts]
        ↓
     __DEV__?
   Tak → console.error + lokalne mock logi
   Nie → POST do /functions/v1/log-error (Edge Function)
        ↓
[Supabase: INSERT do error_logs]
        ↓
[Opcjonalnie: webhook do autora (email/Slack/Discord)]
```

### `shared/services/logger.ts`

```typescript
interface ErrorContext {
  action?: string;
  platform?: 'web' | 'extension' | 'mobile';
  contactId?: string;
  extra?: Record<string, unknown>;
}

export async function captureError(error: Error, context?: ErrorContext): Promise<void> {
  if (IS_DEV) {
    console.error('[DEV ERROR]', error, context);
    return;
  }

  try {
    await fetch(`${SUPABASE_URL}/functions/v1/log-error`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        error_message: error.message,
        stack_trace: error.stack,
        context: {
          ...context,
          url: window.location.href,
          userAgent: navigator.userAgent,
        },
        app_version: APP_VERSION,
        platform: context?.platform ?? 'web',
      }),
    });
  } catch {
    // Logowanie błędu do logowania — ciche zakończenie
    console.warn('Failed to log error to server');
  }
}
```

### Webhook autora

- Konfiguracja w zmiennej środowiskowej `ERROR_WEBHOOK_URL`
- Payload: `{errorId, message, platform, timestamp, userId?}`
- Sugerowana integracja: Discord webhook (prosty, darmowy) lub email przez Resend

---

## 12. Monetyzacja — implementacja

### Plan freemium

| Funkcja | Free | Premium (1,99 zł/mies.) |
|---|---|---|
| Podpowiedzi AI | 30/dzień | Bez limitu |
| Analizy pełne | 3/tydzień | Bez limitu |
| Kontakty | 10 | Bez limitu |
| Templates | 3 podstawowe | Wszystkie (12+) |
| Template erotyczny (18+) | ❌ | ✅ |
| Analiza sentiment | ❌ | ✅ |
| Wykresy / statystyki | ❌ | ✅ |
| Priorytetowe AI (GPT-4o-mini) | ❌ | ✅ |
| Backup automatyczny | ❌ | ✅ |

### Integracja płatności

- **Stripe** — obsługuje PLN, subskrypcje, webhooks
- Checkout: Stripe Checkout (hosted page) → prosta integracja, bezpieczna
- Webhook Stripe → Edge Function `handle-stripe-event` → aktualizuje `profiles.premium_until`
- Przy wygaśnięciu: powiadomienie push 3 dni przed + 1 dzień przed

### Komunikaty zachęcające (bez reklam)

- Po wyczerpaniu limitu: modal "Wyczerpałeś dzisiejszy limit. Premium = bez limitów"
- Przy próbie użycia zablokowanej funkcji: inline komunikat z przyciskiem "Odblokuj"
- Nigdy agresywny paywall — zawsze można zamknąć modal

---

## 13. Struktura plików — pełna mapa

```
contextcompass/
├── packages/
│   │
│   ├── shared/
│   │   ├── src/
│   │   │   ├── types/
│   │   │   │   ├── profile.ts          # Profile, AIInsight, TrustedDevice
│   │   │   │   ├── contact.ts          # Contact, TemplateType, StylePrefs
│   │   │   │   ├── conversation.ts     # Message, Suggestion, AnalysisReport
│   │   │   │   └── index.ts            # Re-export typów (TYLKO typy, nie serwisów)
│   │   │   ├── services/
│   │   │   │   ├── supabaseClient.ts   # Singleton klienta Supabase
│   │   │   │   ├── aiService.ts        # Abstrakcja AI (wybór modelu, wywołanie)
│   │   │   │   ├── promptBuilder.ts    # Budowanie promptów systemowych
│   │   │   │   ├── syncEngine.ts       # IndexedDB ↔ Supabase sync
│   │   │   │   ├── localStore.ts       # Wrapper nad IndexedDB (idb)
│   │   │   │   ├── logger.ts           # captureError, logInfo
│   │   │   │   ├── networkMonitor.ts   # online/offline events
│   │   │   │   ├── cryptoService.ts    # AES-GCM szyfrowanie IndexedDB
│   │   │   │   └── backupService.ts    # Export ZIP / Google Drive
│   │   │   ├── constants.ts            # IS_DEV, APP_VERSION, limity, endpointy
│   │   │   ├── validators.ts           # Walidatory danych wejściowych
│   │   │   └── mocks/
│   │   │       ├── aiMock.ts           # Mockowe odpowiedzi AI (dev)
│   │   │       ├── supabaseMock.ts     # Mock klienta Supabase (dev)
│   │   │       └── dataMocks.ts        # Przykładowe dane (kontakty, profil)
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   ├── web/
│   │   ├── src/
│   │   │   ├── components/             # (opisane w sekcji 7)
│   │   │   ├── hooks/
│   │   │   ├── pages/
│   │   │   ├── App.tsx
│   │   │   ├── main.tsx
│   │   │   └── sw.ts                   # Service Worker (PWA)
│   │   ├── index.html
│   │   ├── vite.config.ts
│   │   ├── tailwind.config.js
│   │   └── package.json
│   │
│   ├── extension/
│   │   ├── src/
│   │   │   ├── background/
│   │   │   │   ├── index.ts            # Service Worker pluginu
│   │   │   │   ├── contextMenu.ts      # Rejestracja i obsługa context menu
│   │   │   │   └── authHandler.ts      # Obsługa tokena / refresh
│   │   │   ├── content/
│   │   │   │   ├── index.ts            # Entry point content script
│   │   │   │   ├── textSelector.ts     # Wykrywanie zaznaczonego tekstu
│   │   │   │   └── overlay.ts          # Shadow DOM overlay z podpowiedziami
│   │   │   └── popup/
│   │   │       ├── Popup.tsx           # Główny komponent popup
│   │   │       └── popup.html
│   │   ├── manifest.json
│   │   └── package.json
│   │
│   └── mobile/                         # React Native (Expo) — przyszłość
│       └── README.md
│
├── supabase/
│   ├── migrations/
│   │   └── 001_initial_schema.sql
│   ├── seed/
│   │   └── test_data.sql
│   └── functions/
│       ├── ai-proxy/
│       │   └── index.ts
│       ├── analyze-conversation/
│       │   └── index.ts
│       ├── log-error/
│       │   └── index.ts
│       ├── handle-stripe-event/
│       │   └── index.ts
│       └── update-contact-summary/
│           └── index.ts
│
├── config/
│   ├── default.json
│   ├── adult-keywords.json             # Lista słów blokowanych bez 18+
│   ├── locales/
│   │   ├── pl.json
│   │   └── en.json
│   └── themes/
│       ├── light.json
│       └── dark.json
│
├── docs/
│   ├── README.md                       # (ten plik = DEVELOPMENT_PLAN)
│   ├── CODING_STANDARDS.md
│   ├── AI_PROMPT_GUIDE.md
│   ├── SECURITY.md
│   └── MONETIZATION.md
│
├── scripts/
│   ├── generate_headers.sh             # Dodaje nagłówki do plików TS
│   ├── check_file_lengths.sh           # Ostrzega o plikach > 200 linii
│   └── deploy.sh                       # Deploy PWA + Edge Functions
│
├── .env.example
├── .eslintrc.json
├── .prettierrc
├── pnpm-workspace.yaml
├── turbo.json                          # Turborepo (opcjonalne, dla wydajności)
└── package.json
```

---

## 14. Harmonogram MVP — 6 tygodni

### Tydzień 1 — Fundament

- [ ] Inicjalizacja monorepo (pnpm, workspaces, tsconfig, eslint, prettier)
- [ ] Supabase: projekt, schema DB (migracja 001), RLS, auth (email + Google)
- [ ] Edge Function: `ai-proxy` (Gemini, fallback chain szkielet)
- [ ] Pakiet `shared`: typy, supabaseClient, logger, constants
- [ ] PWA szkielet: Vite + React + Tailwind + routing + i18n (pl/en)

### Tydzień 2 — Profil i kontakty

- [ ] Ekran logowania / rejestracji + onboarding (3 kroki)
- [ ] CRUD kontaktów (dodaj, edytuj, archiwizuj)
- [ ] Własny profil (formularz, weryfikacja 18+)
- [ ] IndexedDB + SyncEngine (offline-first szkielet)

### Tydzień 3 — Czat i AI (core feature)

- [ ] Widok rozmowy (ChatInput, MessageBubble, historia)
- [ ] Integracja z `ai-proxy` — podpowiedzi (tryb `hint`)
- [ ] HintPanel z wariantami odpowiedzi
- [ ] Nagrywanie głosowe (Web Speech API)
- [ ] NetworkBanner — wskaźnik offline

### Tydzień 4 — Plugin Chrome

- [ ] Manifest V3 + background service worker
- [ ] Content script: wykrywanie tekstu, context menu
- [ ] Shadow DOM overlay z podpowiedziami
- [ ] Komunikacja plugin ↔ backend (przez background)
- [ ] Popup pluginu (mini wersja dashboardu)

### Tydzień 5 — Analizy i bezpieczeństwo

- [ ] Edge Function: `analyze-conversation`
- [ ] Strona `/analysis/:contactId` z raportem
- [ ] Auto-logout + zaufane urządzenia
- [ ] Aktualizacja profilu przez AI (batch + modal)
- [ ] Logowanie błędów (Edge Function `log-error` + webhook)

### Tydzień 6 — Testy, polish, deploy

- [ ] Testy jednostkowe (Vitest) — core serwisy
- [ ] Testy E2E (Playwright) — happy path PWA
- [ ] Debug mode (`__DEV__`) z mockami
- [ ] Backup (export ZIP)
- [ ] Deploy PWA (Vercel/Netlify) + Edge Functions (Supabase)
- [ ] Submit do Chrome Web Store

### Po MVP (miesiąc 2–3)

- Stripe + abonament Premium
- Pełne szablony (12+)
- React Native (Expo)
- Backup Google Drive
- Statystyki i wykresy (premium)
- Template `erotic` z pełną weryfikacją 18+

---

## 15. Otwarte pytania i decyzje

Poniższe kwestie wymagają decyzji przed implementacją danego modułu:

| # | Pytanie | Sugerowana odpowiedź | Decyzja |
|---|---|---|---|
| 1 | Czy zachowujemy raw treść wklejonych rozmów, czy tylko hash + podsumowanie? | Tylko podsumowanie (RODO) | ❓ |
| 2 | Ile wiadomości wstecz wysyłamy do AI dla podpowiedzi? | 10–20 (konfigurowane) | ❓ |
| 3 | Czy plugin ma działać na **wszystkich** stronach domyślnie? | Nie — tylko lista czatów, opcja "wszystko" w ustawieniach | ❓ |
| 4 | Czy potwierdzenie 18+ to self-declaration, czy twarda weryfikacja? | Self-declaration na MVP | ❓ |
| 5 | Czy historia podpowiedzi (co AI zaproponował) ma być widoczna dla użytkownika? | Tak, w historii rozmowy (szara ikona "AI") | ❓ |
| 6 | Jakie są domyślne limity darmowe? (30 podpowiedzi/dzień, 3 analizy/tydzień) | Zgodnie z dokumentacją | ❓ |
| 7 | Czy udostępniamy API dla developerów (webhook out)? | Nie na MVP | ❓ |
| 8 | Email transakcyjny (rejestracja, reset hasła) — jaka usługa? | Resend (darmowe 3000/mies.) lub Supabase wbudowany | ❓ |
