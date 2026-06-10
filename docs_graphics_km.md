<!-- =============================================================================
 FILE: GRAPHICS_PLAN.md
 PATH: docs/GRAPHICS_PLAN.md
 VERSION: 0.1.0
 PURPOSE: Plan grafik aplikacji KlassMate — co wygenerować, gdzie, w jakich wymiarach i z jakim promptem.
 FUNCTIONS: -
 DEPENDS ON: docs/00_PROJECT_OVERVIEW.md, docs/UI_UX_MOCKUP.html
 UWAGA: Każda grafika ma fallback SVG/emoji na czas zanim zostanie wygenerowana.
         Aktualizować przy zmianach w UI lub nowych ekranach.
 ============================================================================= -->

# 🎨 KlassMate — Plan Grafik i Zasobów Wizualnych

---

## 1. Tożsamość wizualna — ustal PRZED generowaniem czegokolwiek

Zanim uruchomisz jakiekolwiek AI do generowania grafik, przygotuj ten brief i trzymaj go przy sobie przez cały projekt. Dzięki niemu możesz w każdym narzędziu uzyskać spójne wyniki nawet po tygodniu przerwy.

### Brief wizualny KlassMate

```
NAZWA APLIKACJI: KlassMate
TAGLINE: "Zadania domowe bez chaosu"
GRUPA DOCELOWA: uczniowie 10–19 lat, Polska

PALETA KOLORÓW (podaj hexami w każdym prompcie):
  Primary:    #4F6EF7  (niebieski-indygo — akcent główny)
  Dark BG:    #1E2235  (granatowy — sidebar, tła)
  Light BG:   #F7F8FA  (jasny szary — tło główne)
  Success:    #10B981  (zielony)
  Warning:    #F59E0B  (pomarańczowy)
  Danger:     #EF4444  (czerwony)

STYL: nowoczesny, przyjazny, "clean". NIE korporacyjny, NIE dziecięcy.
      Bliżej Notion / Linear / Discord niż MS Teams / Classcraft.
MOOD: skupiony, pomocny, bezpieczny, lekko ciepły
MOTYW IKONY: plecak szkolny (🎒) jako symbol główny

CZEGO UNIKAĆ:
  - Kreskówkowe postacie (zbyt dziecięce)
  - Zdjęcia stockowe z uśmiechniętymi uczniami
  - Gradientowe tęcze (przesyt)
  - Realistyczne 3D (niepasuje do flat UI)
  - Ciemnoszare tła z neon glow (zbyt gamingowe)
```

---

## 2. Narzędzia AI do generowania — ranking i strategia

### 2.1. Rekomendowane narzędzia (dostępne, darmowe lub tanie)

| Narzędzie | Co generuje najlepiej | Gdzie dostępne | Limit free |
|-----------|----------------------|---------------|-----------|
| **Adobe Firefly** | Ikony wektorowe, ilustracje, tła | firefly.adobe.com | 25 gen./mies. free |
| **Microsoft Designer / Bing Image Creator** | Ilustracje, splash screeny, ogólne grafiki | designer.microsoft.com | Unlimited (DALL-E 3) |
| **Canva AI (Magic Media)** | App store screenshoty, banery, social media | canva.com | 50 gen./mies. free |
| **Ideogram** | Grafiki z tekstem, logotypy, ikony | ideogram.ai | 10/dzień free, sporo paid |
| **Recraft.ai** | Wektorowe ikony SVG, spójne style | recraft.ai | 50 gen./mies. free tier |
| **Leonardo.ai** | Ilustracje, splash screeny, szczegółowe sceny | leonardo.ai | 150 tokenów/dzień free |

### 2.2. Strategia: nie trać kontekstu

**Problem:** Narzędzia AI gubią kontekst między sesjami. Rozwiązanie:

1. Zapisz brief z sekcji 1 do pliku `VISUAL_BRIEF.txt` — kopiuj go na początku każdej sesji z AI
2. Zachowuj wygenerowane grafiki lokalnie od razu (nie polegaj na historii narzędzia)
3. Pierwszą zaakceptowaną grafikę każdego typu zachowaj jako **reference style** — dołączaj ją do następnych promptów jako "w tym samym stylu co załączone zdjęcie"
4. Generuj w partiach po 1 typ grafiki na sesję (np. cała sesja = tylko ikony kanałów)

### 2.3. Format promptu (kopiuj-wklej szablon)

```
STYL: flat illustration, clean, modern, minimalist. NOT cartoon, NOT 3D render.
KOLORY: primary blue #4F6EF7, dark navy #1E2235, light background #F7F8FA.
TEMATYKA: edukacja, uczniowie szkoły, notatki, współpraca.
BEZ: tekstu (chyba że zaznaczono), twarzy (dla ikon), stockowych zdjęć.
FORMAT: [podaj wymiar i ratio]
TREŚĆ: [opisz co konkretnie]
```

---

## 3. Kompletna lista potrzebnych grafik

### Priorytet P0 — Bez tego aplikacja nie wychodzi (MVP)

---

#### 3.1. Ikona aplikacji

| Asset | Wymiar | Format | Fallback | Narzędzie | Priorytet |
|-------|--------|--------|----------|-----------|-----------|
| App icon — master | 1024×1024 px | PNG (bez tła) | 🎒 emoji | Adobe Firefly / Recraft | P0 |
| App icon — iOS rounded | 1024×1024 px | PNG | jak wyżej | Generowane z mastera | P0 |
| App icon — Android adaptive foreground | 1024×1024 px | PNG | jak wyżej | Generowane z mastera | P0 |
| App icon — Android adaptive background | 1024×1024 px | PNG solid color | #1E2235 flat | Canva (solid fill) | P0 |
| Favicon — web/PWA | 512×512 + 192×192 + 32×32 | PNG | jak wyżej | Generowane z mastera | P0 |

**Prompt dla ikony:**
```
Flat icon design for a school homework sharing app called "KlassMate".
Central element: a stylized backpack silhouette.
Colors: white icon on deep navy blue (#1E2235) background with a blue (#4F6EF7) accent detail.
Style: clean, modern, geometric. Rounded corners.
NO text, NO gradients, NO 3D effects. Simple enough to read at 32px.
1024x1024px, PNG transparent background.
```

---

#### 3.2. Splash Screen

| Asset | Wymiar | Format | Fallback | Narzędzie |
|-------|--------|--------|----------|-----------|
| Splash — mobile (9:19.5) | 1170×2532 px | PNG | Logo + kolor #1E2235 | Adobe Firefly / Leonardo |
| Splash — tablet (3:4) | 1668×2224 px | PNG | jak wyżej | Jak wyżej |
| Splash — web (16:9) | 1920×1080 px | PNG | jak wyżej | Jak wyżej |

**Prompt dla splash:**
```
Splash screen background for a student homework app.
Style: abstract, subtle. Deep navy blue (#1E2235) base with soft geometric shapes
suggesting notebooks, channels, and connections. Very subtle, not distracting.
The center area must be EMPTY (white space 400x400px) for the logo to be placed on top.
Flat design, no 3D, no people, no text.
Mobile format 1170x2532px.
```

**Fallback SVG (używaj do czasu wygenerowania):**
```svg
<!-- assets/splash_fallback.svg -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1170 2532">
  <rect width="1170" height="2532" fill="#1E2235"/>
  <text x="585" y="1266" text-anchor="middle" font-size="120" fill="#4F6EF7">🎒</text>
  <text x="585" y="1380" text-anchor="middle" font-size="48" fill="rgba(255,255,255,0.6)"
        font-family="system-ui">KlassMate</text>
</svg>
```

---

#### 3.3. Onboarding Illustrations (4 slajdy)

| Slajd | Temat | Wymiar | Fallback emoji |
|-------|-------|--------|----------------|
| Slide 1 | Powitanie — uczniowie razem | 600×400 px | 🎒📚 |
| Slide 2 | Kanały przedmiotowe — organizacja | 600×400 px | 📐📖🌍 |
| Slide 3 | Moderacja — bezpieczeństwo | 600×400 px | 🛡️✅ |
| Slide 4 | Notatki + OCR | 600×400 px | 📝📷 |

**Prompt (przykład dla slajdu 2):**
```
Flat illustration for a school app onboarding screen, slide 2 of 4.
Topic: organized subject channels — show stylized chat bubbles grouped by subject icons
(math symbol, book, globe) arranged cleanly.
Style: flat vector illustration, friendly but not cartoonish, clean lines.
Colors: #4F6EF7 blue as main, white elements, navy #1E2235 accents.
NO people, NO text, transparent background. 600x400px.
```

---

### Priorytet P1 — Potrzebne przed public beta

---

#### 3.4. Empty States (puste ekrany)

Każdy ekran z listą ma dedykowany empty state gdy lista jest pusta.

| Ekran | Treść ilustracji | Wymiar | Fallback |
|-------|-----------------|--------|----------|
| Brak wiadomości w kanale | Pusty czat, dymki z "?" | 240×200 px | 💬❓ |
| Brak notatek | Pusty notatnik z piórem | 240×200 px | 📝 |
| Brak przypomnień | Dzwonek + kalendarz | 240×200 px | 🔔 |
| Brak DM | Dwie koperty | 240×200 px | ✉️ |
| Kolejka moderacji pusta | Tarcza z ptaszkiem | 240×200 px | 🛡️✅ |
| Brak wyników wyszukiwania | Lupa z "0" | 240×200 px | 🔍 |

**Strategia:** Generuj wszystkie 6 w jednej sesji, dbając o spójność stylu. Zachowaj pierwszą jako reference.

---

#### 3.5. Ilustracje tematyczne (w ekranach informacyjnych)

| Gdzie | Treść | Wymiar | Fallback |
|-------|-------|--------|----------|
| Ekran zgody rodzica | Rodzic + dziecko + telefon (piktogramowo) | 320×240 px | 👨‍👩‍👦📱 |
| Ekran 2FA setup | Telefon + kod jednorazowy | 280×220 px | 🔐📱 |
| Ekran zaufanego urządzenia | Smartfon z tarczą | 280×220 px | 📱🛡️ |
| Ekran backupu | Chmura ze strzałką | 280×220 px | ☁️⬆️ |
| Ekran archiwizacji klasy | Pudełko archiwalne z datą | 280×220 px | 📦 |
| Ekran usunięcia konta | "Pożegnanie" — neutralne, bez dramatyzmu | 280×220 px | 👋 |
| Help Center hero | Książka z pytajnikiem | 400×200 px | ❓📖 |

---

#### 3.6. Ikony kanałów / przedmiotów (subject icons)

Używane w sidebar jako emoji zastępcze. Opcjonalnie wygeneruj własny zestaw:

| Przedmiot | Emoji fallback | Custom icon (jeśli czas) |
|-----------|---------------|--------------------------|
| Matematyka | 📐 | kalkulator + cyfry flat |
| Język Polski | 📖 | otwarta książka |
| Historia | 🌍 | mapa/glob |
| Angielski | 🇬🇧 | flaga |
| Biologia | 🔬 | mikroskop |
| Chemia | ⚗️ | kolba |
| Fizyka | ⚡ | błyskawica |
| Informatyka | 💻 | laptop |
| WF | ⚽ | piłka |
| Muzyka | 🎵 | nuta |
| Plastyka | 🎨 | paleta |
| Ogłoszenia | 📢 | głośnik |

**Decyzja MVP:** Używaj emoji. Generuj custom ikony dopiero gdy aplikacja ma użytkowników i chcesz premium branding.

---

#### 3.7. App Store / Google Play Assets

| Asset | Wymiar | Format | Uwagi |
|-------|--------|--------|-------|
| Feature Graphic (Play) | 1024×500 px | PNG/JPG | Pokazuje UI + logo |
| Screenshot — iPhone 6.7" | 1290×2796 px | PNG | 5–10 ekranów |
| Screenshot — iPad 12.9" | 2048×2732 px | PNG | 5–10 ekranów |
| Screenshot — Android phone | 1080×1920 px | PNG | 5–10 ekranów |
| Screenshot — Android tablet | 1600×2560 px | PNG | opcjonalne |

**Strategia screenshotów:** Używaj Device Frame z Expo (expo export:web) lub narzędzia Previewed.app (darmowe) do oprawienia prawdziwych zrzutów ekranu w ramki telefonów.

**Feature Graphic prompt:**
```
App store feature banner for a student homework app "KlassMate".
Left: clean smartphone mockup showing a school chat channel interface.
Right: app name "KlassMate" in bold clean sans-serif font,
tagline "Zadania domowe bez chaosu" in smaller text.
Background: deep navy blue (#1E2235) with subtle geometric accent shapes in #4F6EF7.
Style: professional, modern, not cartoonish. 1024x500px.
```

---

### Priorytet P2 — Faza premium / po MVP

---

#### 3.8. Animacja Splash Screen (krótka, ~2s)

**Format docelowy:** Lottie JSON (React Native + Expo AV obsługuje Lottie)

**Jak uzyskać:**

Opcja A (polecana): **LottieFiles.com** — darmowe gotowe animacje
- Szukaj: "backpack", "school", "education", "chat bubble"
- Filtruj: free, lottie format
- Edytuj kolory przez LottieFiles editor (zmień na #4F6EF7 / #1E2235)

Opcja B: **Bing Image Creator / DALL-E → After Effects**
- Wygeneruj 3–4 klatki kluczowe statycznych ilustracji
- Połącz w After Effects lub Haiku Animator
- Wyeksportuj jako Lottie przez plugin Bodymovin

Opcja C (szybka): **Canva → GIF**
- Prosta animacja logo (fading in backpack + nazwa)
- Eksport GIF → konwersja na Lottie przez LottieFiles converter

**Timing animacji:**
```
0.0s — czarny/granatowy ekran
0.2s — ikona plecaka animuje się (scale in + fade)
0.8s — nazwa "KlassMate" pojawia się (slide up + fade)
1.5s — krótkie "odczekanie"
2.0s — fade out → ekran logowania
```

---

#### 3.9. Miniaturki dla powiadomień push

Push notifications na iOS/Android mogą mieć małą ikonę i dużą miniaturę.

| Typ powiadomienia | Mała ikona (monochrom) | Duża ikona (kolor) |
|------------------|----------------------|-------------------|
| Nowa wiadomość | chat bubble outline | jak app icon |
| @wzmianka | @ symbol | jak app icon |
| Wiadomość w moderacji | shield | jak app icon |
| Przypomnienie | bell | jak app icon |
| Nowy członek klasy | person+ | jak app icon |

Małe ikony: biały piktogram na przezroczystym tle, 24×24dp @ 4x = 96×96px PNG.
Generuj ręcznie w Canva lub Figma (proste kształty — 10 minut każda).

---

## 4. Kolejność generowania (harmonogram)

```
Sprint 1 (MVP) — generuj TYLKO to:
  ✅ Ikona aplikacji (1024×1024) — BLOKUJE release
  ✅ Splash screen (mobile) — BLOKUJE release
  ✅ Empty state: brak wiadomości (najczęściej widoczny)
  ✅ Onboarding slide 1 (pierwsze wrażenie)

Sprint 2 — po podstawowych funkcjach:
  ⬜ Remaining onboarding slides (2, 3, 4)
  ⬜ Remaining empty states (5 ekranów)
  ⬜ Ekran zgody rodzica (ważny prawnie — dobra ilustracja pomaga)
  ⬜ Ekran zaufanego urządzenia

Sprint 3 — przed App Store:
  ⬜ App Store screenshoty (5 ekranów każda platforma)
  ⬜ Feature Graphic (Play Store)
  ⬜ Tablet splash

Faza premium:
  ⬜ Splash animation (Lottie)
  ⬜ Custom subject icons (zamiast emoji)
  ⬜ Remaining informational illustrations
```

---

## 5. Nazewnictwo plików i struktura `assets/`

```
assets/
├── icons/
│   ├── app-icon-1024.png           # Master icon
│   ├── app-icon-ios.png            # iOS (1024x1024)
│   ├── app-icon-android-fg.png     # Android adaptive foreground
│   ├── app-icon-android-bg.png     # Android adaptive background (solid color)
│   ├── favicon-512.png
│   ├── favicon-192.png
│   └── favicon-32.png
├── splash/
│   ├── splash-mobile.png           # 1170x2532
│   ├── splash-tablet.png           # 1668x2224
│   ├── splash-web.png              # 1920x1080
│   └── splash-fallback.svg         # SVG fallback (zawsze w repozytorium)
├── onboarding/
│   ├── slide-1-welcome.png
│   ├── slide-2-channels.png
│   ├── slide-3-moderation.png
│   └── slide-4-notes.png
├── empty-states/
│   ├── empty-messages.png
│   ├── empty-notes.png
│   ├── empty-reminders.png
│   ├── empty-dm.png
│   ├── empty-moderation.png
│   └── empty-search.png
├── illustrations/
│   ├── parental-consent.png
│   ├── two-factor-setup.png
│   ├── trusted-device.png
│   ├── backup.png
│   ├── archive-class.png
│   ├── delete-account.png
│   └── help-center.png
├── store/
│   ├── feature-graphic-play.png    # 1024x500
│   ├── screenshot-iphone-01.png    # ...do 10
│   ├── screenshot-android-01.png
│   └── screenshot-ipad-01.png
└── animations/
    └── splash-animation.json       # Lottie (Phase 2)
```

**Zasada:** Każda grafika ma SVG lub emoji fallback zdefiniowany w kodzie. Brak grafiki = `<Fallback />` komponent, NIE crash.

---

## 6. Jak sprawdzić spójność wizualną przed publikacją

Przed submitowaniem do App Store / Play Store, zrób prosty test:

1. Połóż obok siebie: ikonę, splash screen, screenshot 1 z App Store, ilustrację onboarding
2. Odpowiedz na pytania:
   - Czy te same odcienie niebieskiego we wszystkich? (sprawdź eyedropper)
   - Czy styl ilustracji jest spójny (flat = flat wszędzie)?
   - Czy żadna grafika nie wygląda jak "stockowe zdjęcie" obok custom ilustracji?
   - Czy aplikacja wygląda jak produkt jednego studia, czy zestaw przypadkowych grafik?

Jeśli odpowiedź na ostatnie pytanie to "zestaw przypadkowych grafik" — wróć do generowania z reference style (patrz sekcja 2.2).
