# MONETIZATION.md — ContextCompass

> Model biznesowy, plan freemium, integracja Stripe, komunikacja z użytkownikiem.

---

## Model freemium — szczegóły

### Porównanie planów

| Funkcja | Free | Premium (1,99 zł/mies.) |
|---|---|---|
| **AI** | | |
| Podpowiedzi AI (hint) | 30 / dzień | Bez limitu |
| Analizy pełnych rozmów | 3 / tydzień | Bez limitu |
| Model AI | Gemini Flash / Groq (darmowe) | GPT-4o-mini (lepsza jakość) |
| Własny klucz API | ✅ (bypass limitów) | ✅ |
| **Kontakty** | | |
| Liczba kontaktów | 10 | Bez limitu |
| Templates dostępne | 3 (ogólny, znajomy, praca) | Wszystkie (12+) |
| Template erotyczny (18+) | ❌ | ✅ |
| Template randkowy zaawansowany | ❌ | ✅ |
| **Analizy i statystyki** | | |
| Analiza sentiment | ❌ | ✅ |
| Historia raportów | 7 dni | Bez limitu |
| Wykresy stylu komunikacji | ❌ | ✅ |
| **Dane i backup** | | |
| Eksport ręczny (ZIP) | ✅ | ✅ |
| Backup automatyczny | ❌ | ✅ (Google Drive / co 24h) |
| Synchronizacja urządzeń | ✅ | ✅ (priorytetowa) |
| **Wsparcie** | | |
| Priorytetowe wsparcie | ❌ | ✅ (odpowiedź < 24h) |

---

## Integracja Stripe

### Produkty i ceny w Stripe Dashboard

```
Produkt: ContextCompass Premium
Cena:    1.99 PLN / miesiąc (recurring)
ID:      price_xxx (zapisz w config/default.json lub Supabase Vault)
```

### Flow zakupu

```
[Użytkownik klika "Kup Premium"]
         ↓
[Edge Function: create-checkout-session]
  - Tworzy Stripe Checkout Session
  - success_url: https://app.contextcompass.pl/settings/subscription?success=true
  - cancel_url:  https://app.contextcompass.pl/settings/subscription?canceled=true
  - metadata: { user_id: "uuid" }
         ↓
[Redirect do Stripe Checkout (hosted)]
         ↓
[Płatność zakończona → Stripe webhook]
         ↓
[Edge Function: handle-stripe-event]
  - Weryfikacja podpisu Stripe (STRIPE_WEBHOOK_SECRET)
  - event.type == 'checkout.session.completed':
    → UPDATE profiles SET premium_until = NOW() + INTERVAL '31 days'
  - event.type == 'invoice.payment_succeeded' (odnowienie):
    → UPDATE profiles SET premium_until = NOW() + INTERVAL '31 days'
  - event.type == 'customer.subscription.deleted':
    → UPDATE profiles SET premium_until = NOW()
         ↓
[Toast w aplikacji: "Premium aktywowane! 🎉"]
```

### Zmienne środowiskowe (Supabase Vault)

```
STRIPE_SECRET_KEY         sk_live_...
STRIPE_WEBHOOK_SECRET     whsec_...
STRIPE_PRICE_ID_PREMIUM   price_...
```

### Edge Function: handle-stripe-event (szkielet)

```typescript
// Weryfikacja podpisu webhookowego
const signature = req.headers.get('stripe-signature');
const body = await req.text();
const event = stripe.webhooks.constructEvent(body, signature, STRIPE_WEBHOOK_SECRET);

switch (event.type) {
  case 'checkout.session.completed': {
    const session = event.data.object;
    const userId = session.metadata?.user_id;
    if (userId) await extendPremium(userId, 31);
    break;
  }
  case 'invoice.payment_succeeded': {
    // Miesięczne odnowienie
    const invoice = event.data.object;
    const customerId = invoice.customer as string;
    const userId = await getUserByStripeCustomerId(customerId);
    if (userId) await extendPremium(userId, 31);
    break;
  }
  case 'customer.subscription.deleted': {
    // Anulowanie — nie odbieramy dostępu natychmiast, tylko nie przedłużamy
    break;
  }
}
```

---

## Komunikacja z użytkownikiem — bez agresji

### Zasada

**Nigdy nie blokujemy użytkownika bez wyjaśnienia.**  
Każdy komunikat o limicie musi:
1. Wyjaśniać co zostało wyczerpane
2. Pokazywać ile zostało (jeśli częściowy limit)
3. Oferować alternatywę (poczekaj / kup premium / dodaj własny klucz)
4. Być zamykalny (X)

### Wzorce komunikatów

#### Wyczerpany dzienny limit podpowiedzi (free)

```
Modal:
┌─────────────────────────────────────────┐
│  Wyczerpałeś dzisiejszy limit           │
│                                         │
│  Wykorzystałeś 30/30 podpowiedzi AI     │
│  na dziś. Limit odnowi się o północy.   │
│                                         │
│  Chcesz więcej już teraz?               │
│                                         │
│  [Kup Premium — 1,99 zł/mies.]          │
│  [Dodaj własny klucz API]               │
│  [Poczekaj do północy]                  │
└─────────────────────────────────────────┘
```

#### Próba użycia zablokowanej funkcji (premium)

```
Toast (3s, nie modal):
"Ta funkcja dostępna w Premium ✨  [Zobacz plany]"
```

#### Fallback AI (zmiana modelu)

```
Toast (5s, informacyjny):
"Przełączono na Groq (dzienny limit Gemini wyczerpany)"
```

#### Wyczerpanie limitów analizy (free, 3/tydz.)

```
Inline w widoku analizy (zamiast przycisku):
┌─────────────────────────────────────────┐
│  Wykorzystałeś 3/3 analizy w tym tygod- │
│  niu. Nowe analizy dostępne od poniedziałku. │
│                                         │
│  [Przejdź na Premium — analizy bez limitu]│
└─────────────────────────────────────────┘
```

### Gdzie NIE wyświetlać reklam / zachęt do premium

- W trakcie aktywnego pisania/rozmowy (rozpraszałoby)
- Częściej niż raz na 3 dni (dla tego samego użytkownika)
- Jako popup przy wejściu do aplikacji (bez kontekstu)

---

## Alternatywne scenariusze monetyzacji (do rozważenia post-MVP)

### 1. Pay-per-use (mikropłatności)

- 10 podpowiedzi = 0,49 zł (przez Stripe one-time)
- Dla użytkowników nieregularnych, którzy nie chcą abonamentu
- Wymaga: konta tokenów w bazie, UI salda, Stripe one-time payment

**Ocena:** Dobry pomysł dla segmentu "okazjonalni", ale komplikuje UX.  
**Rekomendacja:** Wdrożyć po MVP jeśli konwersja na abonament < 3%.

### 2. Plan Team (organizacje)

- 5 użytkowników = 7,99 zł/mies.
- Wspólny limit AI, zarządzanie przez admina
- Dla: agencji marketingowych, trenerów sprzedaży, coachów

**Ocena:** Wymaga multitenancy w DB (teams table). Duży potencjał B2B.  
**Rekomendacja:** Post-MVP, miesiąc 4–6.

### 3. Marketplace szablonów

- Użytkownicy tworzą i sprzedają własne templates (np. "szablon dla sprzedawcy samochodów")
- Revenue share: 70% twórca / 30% platforma
- Wymaga: tabela templates, system recenzji, Stripe Connect

**Ocena:** Długoterminowy potencjał. Wymaga krytycznej masy użytkowników.  
**Rekomendacja:** Rok 2+.

### 4. API dla developerów

- Dostęp do silnika ContextCompass przez REST API
- Płatne plany (1000 req = 10$)
- Dla: chatbotów, aplikacji coachingowych, CRM

**Ocena:** Wymaga dokumentacji API, developer portal, osobnego limitu.  
**Rekomendacja:** Rok 2+.

---

## Metryki sukcesu

| Metryka | Cel (3 miesiące) | Cel (12 miesięcy) |
|---|---|---|
| Aktywni użytkownicy (MAU) | 500 | 5 000 |
| Konwersja Free → Premium | > 3% | > 8% |
| Churn miesięczny (Premium) | < 10% | < 5% |
| Przychód MRR | 200 zł | 5 000 zł |
| Liczba podpowiedzi/dzień | 2 000 | 50 000 |
| Plugin installs (Chrome Store) | 200 | 2 000 |
