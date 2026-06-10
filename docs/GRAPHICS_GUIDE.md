<!-- =============================================================================
 FILE: GRAPHICS_GUIDE.md
 PATH: docs/GRAPHICS_GUIDE.md
 VERSION: 0.1.0
 PURPOSE: Kompletna lista potrzebnych grafik, specyfikacje techniczne, rekomendacje narzędzi AI do generowania.
 DEPENDS ON: README.md, UI_MOCKUP.html
 ============================================================================= -->

# GRAPHICS_GUIDE.md — Przewodnik po grafikach projektu

> Każda grafika ma: przeznaczenie, wymiary, format, fallback (SVG/emoji) i prompt sugerowany do AI.
> Sekcja C zawiera przewodnik po narzędziach — które wybrać i jak zachować spójność stylu.

---

## A. LISTA WYMAGANYCH GRAFIK

### A.1. Ikony aplikacji (app icon)

Najważniejsze grafiki — muszą być gotowe przed jakimkolwiek testem na urządzeniu.

| # | Przeznaczenie | Wymiary | Format | Fallback | Priorytet |
|---|---------------|---------|--------|----------|-----------|
| I-01 | Favicon przeglądarka | 32×32 px | `.ico` / `.png` | `⊙` (tekst) | 🔴 P0 |
| I-02 | PWA ikona mała | 192×192 px | `.png` (bez alfa) | SVG circle | 🔴 P0 |
| I-03 | PWA ikona duża | 512×512 px | `.png` (bez alfa) | SVG circle | 🔴 P0 |
| I-04 | Plugin toolbar | 16×16, 32×32, 48×48, 128×128 px | `.png` | SVG | 🔴 P0 |
| I-05 | Apple Touch icon | 180×180 px | `.png` (bez alfa, bg pełne) | SVG | 🟡 P1 |
| I-06 | Android adaptive icon — foreground | 108×108 dp (432×432 px @4x) | `.png` (z przeźroczystością) | SVG | 🟡 P1 |
| I-07 | Android adaptive icon — background | 108×108 dp | `.png` (solid color) | Kolor `#6366F1` | 🟡 P1 |
| I-08 | macOS / Windows taskbar icon | 256×256 px | `.png` | SVG | 🟢 P2 |

**Prompt sugerowany (dla Gemini/Bing Image Creator/DALL-E):**
```
App icon for "ContextCompass" — a minimal, modern logo.
Style: flat design, single color gradient (indigo #6366F1 to violet #7C3AED).
Symbol: a stylized compass rose combined with a speech bubble or chat dots.
Clean lines, geometric, recognizable at 32px.
White background. Square format.
Do NOT include text, people, or photorealistic elements.
```

---

### A.2. Splash screen / onboarding

| # | Przeznaczenie | Wymiary | Format | Fallback | Priorytet |
|---|---------------|---------|--------|----------|-----------|
| S-01 | Splash screen mobile (iOS) | 1170×2532 px | `.png` | Gradient CSS `#6366F1→#4F46E5` | 🔴 P0 |
| S-02 | Splash screen mobile (Android) | 1080×2340 px | `.png` | Gradient CSS | 🔴 P0 |
| S-03 | Splash screen desktop / PWA | 1920×1080 px | `.png` lub animacja | Gradient CSS | 🟡 P1 |
| S-04 | **Animacja splash** (Lottie/CSS) | 400×400 px | `.json` (Lottie) lub CSS | Ikona statyczna + fade-in | 🟡 P1 |

**Opis animacji splash (S-04):**
Ikona ContextCompass (kompas + bańka) pojawia się od środka (scale 0→1, 0.4s ease-out), następnie krótkie obrócenie wskazówki kompasu (rotacja 0→30deg→0, 0.6s), potem fade-out do ekranu głównego.

**Prompt sugerowany (Bing Image Creator / Adobe Firefly):**
```
Minimalist splash screen background for a mobile app.
Solid deep indigo gradient (top: #312E81, bottom: #6366F1).
Subtle geometric pattern: faint compass rose watermark, opacity 8%.
Clean, premium, dark. No text, no people.
Portrait orientation 9:19.5 ratio.
```

---

### A.3. Onboarding — ilustracje kroków

| # | Krok | Wymiary | Format | Fallback | Priorytet |
|---|------|---------|--------|----------|-----------|
| O-01 | Krok 1: Powitanie — kompas/podróż | 400×300 px | `.png` / `.svg` | Emoji `🧭` duże | 🟡 P1 |
| O-02 | Krok 2: Profil — sylwetka z cechami | 400×300 px | `.png` / `.svg` | Emoji `👤` duże | 🟡 P1 |
| O-03 | Krok 3: Pierwsza rozmowa — bańki czatu | 400×300 px | `.png` / `.svg` | Emoji `💬` duże | 🟡 P1 |

**Styl ilustracji:** flat design, linia, 2–3 kolory (indigo, pink, white), bez cieni fotorealistycznych. Spójny z ikoną aplikacji.

**Prompt sugerowany:**
```
Flat illustration for app onboarding step 1.
Theme: navigation compass and a journey forward. 
Style: minimal flat vector, 2-color palette (indigo #6366F1, soft white).
Geometric shapes, no people, no text.
Friendly and modern. Transparent or white background. 400x300px.
```

---

### A.4. Tła i dekoracje UI

| # | Przeznaczenie | Wymiary | Format | Fallback | Priorytet |
|---|---------------|---------|--------|----------|-----------|
| B-01 | Tło karty Premium — gradient z efektem | 600×200 px | `.png` / `.webp` | CSS `bg-gradient-to-r from-amber-400 to-rose-500` | 🟡 P1 |
| B-02 | Tło sekcji 18+ — ciepłe, abstrakcyjne | 800×400 px | `.png` / `.webp` | CSS `bg-rose-50` | 🟢 P2 |
| B-03 | Placeholder pusty dashboard | 320×240 px | `.svg` | Emoji `💬` + tekst | 🟡 P1 |
| B-04 | Placeholder brak wyników wyszukiwania | 240×200 px | `.svg` | Emoji `🔍` + tekst | 🟢 P2 |
| B-05 | Placeholder brak analizy | 320×240 px | `.svg` | Emoji `📊` + tekst | 🟢 P2 |
| B-06 | Error state ilustracja (coś poszło nie tak) | 240×200 px | `.svg` | Emoji `⚠️` + tekst | 🟡 P1 |
| B-07 | Offline state ilustracja | 240×200 px | `.svg` | Emoji `📡` + tekst | 🟡 P1 |

---

### A.5. Grafiki dla Open Graph / Social preview

Wymagane przy publikacji w Chrome Web Store i na stronie landing.

| # | Przeznaczenie | Wymiary | Format | Priorytet |
|---|---------------|---------|--------|-----------|
| OG-01 | Chrome Web Store — ikona promo mała | 440×280 px | `.png` | 🔴 P0 (wymagane przez Store) |
| OG-02 | Chrome Web Store — baner duży | 1400×560 px | `.png` | 🟡 P1 |
| OG-03 | Open Graph (linki w social media) | 1200×630 px | `.png` / `.jpg` | 🟡 P1 |
| OG-04 | Screenshoty dla Chrome Web Store (min. 1) | 1280×800 px | `.png` | 🔴 P0 (wymagane) |

**Prompt sugerowany (OG-01, baner promo):**
```
Promotional banner for a Chrome extension called "ContextCompass".
Tagline: "AI-powered conversation assistant".
Style: clean, modern SaaS. Dark indigo background (#1E1B4B).
Logo on left, abstract compass/chat illustration on right.
White typography. Professional, not cartoonish.
1400x560px, PNG.
```

---

### A.6. Ikony systemu (inline SVG — nie wymagają generowania AI)

Te ikony powinny być SVG inline z biblioteki (`lucide-react` lub `heroicons`) — nie generuj ich przez AI.

| Ikona | Użycie | Biblioteka |
|-------|--------|-----------|
| `MessageCircle` | kontakty, chat | lucide-react |
| `User` | profil | lucide-react |
| `Bell` | przypomnienia | lucide-react |
| `BarChart2` | analizy | lucide-react |
| `Settings` | ustawienia | lucide-react |
| `Mic` | nagrywanie | lucide-react |
| `Copy` | kopiuj odpowiedź | lucide-react |
| `X` | zamknij, wyczyść pole | lucide-react |
| `WifiOff` | offline | lucide-react |
| `Sparkles` | AI / premium | lucide-react |
| `Crown` | premium badge | lucide-react |
| `Fingerprint` | biometria (Android) | lucide-react |
| `ScanFace` | Face ID (iOS) | lucide-react |

---

## B. FALLBACKI SVG — GOTOWE DO UŻYCIA

### B.1. Ikona aplikacji (fallback SVG)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#6366F1"/>
      <stop offset="100%" stop-color="#4F46E5"/>
    </linearGradient>
  </defs>
  <rect width="100" height="100" rx="22" fill="url(#g)"/>
  <!-- Kompas uproszczony -->
  <circle cx="50" cy="48" r="22" fill="none" stroke="white" stroke-width="3" opacity="0.6"/>
  <polygon points="50,26 54,48 50,44 46,48" fill="white"/>
  <polygon points="50,70 54,48 50,52 46,48" fill="white" opacity="0.4"/>
  <!-- Bańka czatu -->
  <rect x="34" y="60" width="32" height="20" rx="8" fill="white" opacity="0.9"/>
  <polygon points="42,80 38,88 48,80" fill="white" opacity="0.9"/>
  <circle cx="42" cy="70" r="2.5" fill="#6366F1"/>
  <circle cx="50" cy="70" r="2.5" fill="#6366F1"/>
  <circle cx="58" cy="70" r="2.5" fill="#6366F1"/>
</svg>
```

### B.2. Empty state — brak kontaktów
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 240" fill="none">
  <circle cx="160" cy="100" r="60" fill="#EEF2FF"/>
  <circle cx="160" cy="85" r="25" fill="#C7D2FE"/>
  <rect x="130" y="115" width="60" height="40" rx="20" fill="#C7D2FE"/>
  <rect x="80" y="170" width="160" height="12" rx="6" fill="#E5E7EB"/>
  <rect x="110" y="192" width="100" height="10" rx="5" fill="#F3F4F6"/>
</svg>
```

### B.3. Offline state
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 200" fill="none">
  <path d="M40 60 Q120 0 200 60" stroke="#E5E7EB" stroke-width="8" stroke-linecap="round"/>
  <path d="M65 90 Q120 40 175 90" stroke="#E5E7EB" stroke-width="8" stroke-linecap="round"/>
  <path d="M95 120 Q120 90 145 120" stroke="#E5E7EB" stroke-width="8" stroke-linecap="round"/>
  <circle cx="120" cy="150" r="12" fill="#F59E0B"/>
  <!-- Przekreślenie -->
  <line x1="30" y1="30" x2="210" y2="170" stroke="#EF4444" stroke-width="4" stroke-linecap="round"/>
</svg>
```

---

## C. NARZĘDZIA DO GENEROWANIA GRAFIK

### C.1. Porównanie darmowych narzędzi AI

| Narzędzie | Darmowy limit | Mocne strony | Słabe strony | Idealne do |
|-----------|--------------|--------------|--------------|------------|
| **Bing Image Creator** (DALL-E 3) | ~15/dzień (boosty), potem wolniej | Jakość, realność, prompt zrozumienie | Czasem dodaje tekst mimo próśb | Splash screen, baner OG, onboarding |
| **Adobe Firefly** | 25 generacji/mies. (darmowe konto) | Styl "commercial safe", konsekwentny | Mniej kreatywny, wymaga konta | Baner Store, ikona promo, tła |
| **Canva AI (Magic Media)** | 50 generacji/mies. | Łatwy eksport w gotowych rozmiarach, szablony | Mniej precyzyjny prompt | Baner Store, OG image, template |
| **Google Gemini (Imagen)** | Dostępny przez AI Studio (bezpłatnie) | Dobra jakość, szybkość | Czasem konserwatywny (odmowy) | Ikony, ilustracje onboarding |
| **Ideogram** (ideogram.ai) | 10 darmowych/dzień | Doskonały w tekście na grafikach | Słabszy w abstrakcji | Banery z tekstem, OG |
| **Leonardo.ai** | 150 tokenów/dzień | Duża kontrola stylu, LoRA | Krzywa uczenia | Spójny zestaw ilustracji |

### C.2. Które narzędzie do czego

```
Ikona aplikacji (I-01 do I-08):
  → Adobe Firefly (styl minimal, commercial safe)
  → Prompt: użyj szablonu z sekcji A.1

Splash screen (S-01 do S-03):
  → Bing Image Creator (DALL-E 3) — najlepsza jakość tła
  → Prompt: użyj szablonu z sekcji A.2

Animacja splash (S-04):
  → Nie AI — użyj LottieFiles.com (darmowe animacje) lub CSS
  → Szukaj: "compass animation lottie" na lottiefiles.com

Ilustracje onboarding (O-01 do O-03):
  → Leonardo.ai (spójny styl między krokami — użyj tego samego seed/model)
  → Generuj wszystkie 3 w jednej sesji, żeby styl był jednolity

Tła i dekoracje (B-01 do B-07):
  → CSS gradient > AI generowanie dla prostych teł
  → AI tylko dla: baner Premium (B-01), placeholder grafiki (B-03, B-06, B-07)

Chrome Web Store grafiki (OG-01 do OG-04):
  → Canva (darmowy, gotowe szablony 1400×560, 440×280)
  → Screenshoty: zrób z działającej aplikacji (DevTools → screenshot)
```

### C.3. Zachowanie spójności stylu — kluczowe zasady

**Problem:** Generujesz ikonę w Bing, onboarding w Gemini, baner w Canva — efekt: graficznie niespójne.

**Rozwiązanie:**

1. **Ustal "design brief" zanim zaczniesz** — wklej go do każdego generatora:
   ```
   DESIGN BRIEF ContextCompass:
   - Styl: flat design, minimal, geometric
   - Paleta: Primary #6366F1 (indigo), Accent #EC4899 (pink), White, Dark #1E1B4B
   - Klimat: profesjonalny ale przyjazny, nowoczesny, nie cartoonish
   - Symbol główny: kompas + bańka czatu (motyw nawigacji w rozmowie)
   - NIE używać: zdjęć ludzi, fotorealizmu, zbyt wielu kolorów, tekstu w grafice
   ```

2. **Generuj w jednej sesji** — modele "pamiętają" styl w ramach konwersacji (Bing, Gemini)

3. **Użyj jednego generatora dla jednego typu** — np. tylko Firefly dla ikon, tylko Leonardo dla ilustracji

4. **Test spójności** — umieść wszystkie grafiki na białym tle obok siebie i oceń wizualnie przed użyciem

### C.4. Jak opisać projekt AI generatorowi (gotowy brief)

```
Projekt: ContextCompass
Typ: Aplikacja mobilna + plugin przeglądarkowy
Funkcja: AI asystent podpowiadający co odpisać w rozmowach
Grupa docelowa: 18-35 lat, tech-savvy, używają czatów social media

Motyw wizualny:
- Kompas jako symbol (nawigacja w relacjach i rozmowach)
- Bańki czatu (komunikacja)
- Gradient indigo-violet (inteligentny, spokojny)

Klimat: jak aplikacja do medytacji spotyka technologię AI — spokojny, pomocny, nie stresujący

Paleta kolorów:
- Indigo: #6366F1 (primary)
- Violet: #4F46E5 (dark)
- Pink: #EC4899 (accent, delikatny)
- Tło jasne: #F9FAFB
- Tło ciemne: #1E1B4B

NIE rób:
- Zdjęcia ludzi przy telefonach
- Photorealistyczne elementy
- Zbyt dużo kolorów
- Tekstu wewnątrz grafiki (poza banerami)
```

---

## D. SPECYFIKACJE TECHNICZNE — EKSPORT

### D.1. Formaty i wymagania

| Format | Kiedy używać | Uwagi |
|--------|-------------|-------|
| `.svg` | Ikony systemu, ilustracje wektorowe, placeholdery | Inline lub `<img>` — skaluje się bez utraty jakości |
| `.png` (z alfa) | Ikony aplikacji z przeźroczystym tłem | Maksymalna jakość, brak kompresji stratnej |
| `.png` (bez alfa) | Splash screen, Apple Touch icon | Wymagają pełnego tła (Apple odrzuca przeźroczystość) |
| `.webp` | Tła, dekoracje UI, duże grafiki dekoracyjne | 30% mniejszy niż PNG, obsługiwany przez wszystkie nowoczesne przeglądarki |
| `.jpg` | OG images, screenshoty Store | Kompresja stratna OK dla fotograficznych tła |
| `.lottie` / `.json` | Animacje (splash, loading) | LottieFiles, nie generuj przez AI |

### D.2. Gdzie w projekcie

```
public/
├── icons/
│   ├── icon-16.png        # I-04 plugin
│   ├── icon-32.png        # I-01 favicon, I-04 plugin
│   ├── icon-48.png        # I-04 plugin
│   ├── icon-128.png       # I-04 plugin
│   ├── icon-180.png       # I-05 Apple Touch
│   ├── icon-192.png       # I-02 PWA
│   ├── icon-512.png       # I-03 PWA
│   └── icon.svg           # fallback SVG (sekcja B.1)
├── splash/
│   ├── splash-ios.png     # S-01
│   ├── splash-android.png # S-02
│   └── splash-animation.json  # S-04 Lottie
├── onboarding/
│   ├── step1.svg          # O-01
│   ├── step2.svg          # O-02
│   └── step3.svg          # O-03
├── illustrations/
│   ├── empty-contacts.svg # B-03
│   ├── empty-search.svg   # B-04
│   ├── offline.svg        # B-07
│   └── error.svg          # B-06
└── og/
    ├── og-1200x630.png    # OG-03
    ├── store-440x280.png  # OG-01
    └── store-1400x560.png # OG-02
```

### D.3. Responsywność ikon — `manifest.webmanifest`

```json
{
  "name": "ContextCompass",
  "short_name": "ContextCompass",
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ],
  "theme_color": "#6366F1",
  "background_color": "#1E1B4B"
}
```

---

## E. CHECKLISTA GRAFIK PRZED RELEASE

```
Ikony aplikacji
□ icon-32.png (favicon)
□ icon-192.png (PWA)
□ icon-512.png (PWA + maskable)
□ icon-128.png (Chrome Store)
□ icon-180.png (Apple Touch)

Splash screen
□ splash-ios.png lub CSS gradient fallback
□ splash-android.png lub CSS gradient fallback
□ Animacja Lottie lub CSS fade-in (minimum)

Chrome Web Store (WYMAGANE przed publishem)
□ store-440x280.png (ikona promo)
□ Screenshot 1280×800 (minimum 1, max 5)
□ Opis w Store pasujący do grafik

Open Graph
□ og-1200x630.png (linki w social media)

Ilustracje UI (ważne dla UX)
□ empty-contacts.svg (pusty dashboard)
□ offline.svg
□ error.svg

Opcjonalne (P2)
□ onboarding/step1-3.svg
□ store-1400x560.png (duży baner Store)
□ Animacja splash Lottie (zamiast CSS)
```
