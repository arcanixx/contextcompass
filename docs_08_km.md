# 08_ROADMAP_AND_MONETISATION.md
# Path: docs/08_ROADMAP_AND_MONETISATION.md
# Purpose: MVP roadmap, phased delivery plan, monetisation mechanics
# Depends on: 00_PROJECT_OVERVIEW.md

---

# KlassMate — Roadmap & Monetisation

---

## 1. MVP Definition (Phase 1)

**Goal:** A working, safe app that one class can use to share homework information.

**Done = all of the following work:**
- Register, log in (email + Google), 2FA for admins
- Biometric unlock on mobile
- Create a class, generate join code, admin approves members
- Create channels (subjects), post text messages
- Moderation: auto-reject profanity, queue borderline for admin review
- Admin can approve / reject / trim queued messages
- Push notifications: new messages, @mentions
- Basic unread indicators
- Light/dark theme (system sync)
- Onboarding slides + tooltips
- Toast feedback for all actions
- RODO: account deletion, parental consent for under-16

**NOT in MVP (Phase 2+):**
- Voice messages
- Image attachments
- Personal notes + OCR
- Direct messages
- Google Drive / iCloud backup
- Premium subscriptions
- Online status
- Screenshot prevention (defer to P2)
- Custom theme colours

---

## 2. Phased Delivery Plan

### Phase 1 — Foundation (Months 1–2)
| Week | Tasks |
|------|-------|
| 1 | Supabase project setup (Frankfurt), schema + RLS migrations, local dev environment |
| 2 | Auth: email/password, Google OAuth, Apple OAuth, 2FA, biometric unlock |
| 3 | Parental consent flow, session management, device trust |
| 4 | Classes: create, join with code, admin approval flow |
| 5 | Channels: create, list, basic text messaging (no moderation yet) |
| 6 | Moderation Edge Function: profanity filter, queue, admin review UI |
| 7 | Push notifications, unread badges, notification settings |
| 8 | Onboarding, tooltips, toasts, help screen, light/dark theme |

**Milestone:** Beta with one real class (5–10 students)

### Phase 2 — Communication Features (Months 3–4)
| Task | Notes |
|------|-------|
| Voice messages | Record, send, player with waveform |
| Image attachments | Compression, moderation of images |
| Personal notes + OCR | Tesseract.js + OCR.space fallback |
| Direct messages | Text + voice, auto-moderation only |
| User blocking | DM block + report |
| Screenshot prevention | Android FLAG_SECURE, iOS detection |
| Threads | Sub-discussions within channels |
| Class archiving | End-of-year flow |

**Milestone:** Public beta, multiple classes

### Phase 3 — Premium & Scale (Months 5–6)
| Task | Notes |
|------|-------|
| Premium subscriptions | RevenueCat integration (handles App Store + Play Store) |
| No-ads for premium | Ad banner shown to free users |
| Google Drive backup | OAuth, ZIP export |
| iCloud backup | iOS only |
| Extended storage for premium | 2 GB vs 200 MB |
| Custom theme colours | Premium-only personalisation |
| Online status | Opt-in |
| School plan | Teacher dashboard |

**Milestone:** First paying users, app publicly listed

---

## 3. Monetisation Details

### 3.1 Revenue Cat Integration

Use [RevenueCat](https://www.revenuecat.com/) to manage subscriptions across App Store and Google Play. It handles:
- Receipt validation (prevents fraud)
- Cross-platform subscription status
- Free trial periods
- Webhook for Supabase: update `profiles.plan` on purchase/cancellation

```typescript
// src/lib/subscriptions/revenueCat.ts
import Purchases from 'react-native-purchases';

export const initRevenueCat = () => {
  Purchases.configure({
    apiKey: process.env.EXPO_PUBLIC_REVENUECAT_KEY!,
    appUserID: currentUserId, // links RC to Supabase user
  });
};

export const getPremiumStatus = async (): Promise<boolean> => {
  const customerInfo = await Purchases.getCustomerInfo();
  return customerInfo.entitlements.active['premium'] !== undefined;
};
```

### 3.2 Free Tier Limits

Enforced server-side in RLS / Edge Functions:

| Limit | Free | Premium |
|-------|------|---------|
| Storage per class | 200 MB | 2 GB |
| Voice message duration | 60s | 5 min |
| Attachment size | 5 MB | 20 MB |
| Message history visible | 90 days | Unlimited |
| Channels per class | 10 | Unlimited |
| Classes per account | 5 | Unlimited |
| Custom theme colours | ❌ | ✅ |
| Auto backup (Drive/iCloud) | ❌ | ✅ |
| Ads shown | ✅ | ❌ |

### 3.3 Ad Strategy (Free Tier)

- **Provider:** Google AdMob (with GDPR-compliant consent for EU users)
- **Format:** Banner ad at the bottom of the main screen only
- **Frequency:** Max 1 interstitial per session (on class switch), not on message send
- **Children's ads:** MUST use non-personalised ads (NPA) for all users. AdMob has COPPA/GDPR-K compliant ad serving — must be configured.
- **What is NEVER shown:** Video ads mid-message, ads in moderation screens, ads in settings

```typescript
// Ensure child-safe non-personalised ads
// This must be set BEFORE any ad loads
import mobileAds, { AdsConsent } from 'react-native-google-mobile-ads';

const initAds = async () => {
  await AdsConsent.requestInfoUpdate();
  // For child-directed apps: always NPA
  await mobileAds().setRequestConfiguration({
    maxAdContentRating: 'G',
    tagForChildDirectedTreatment: true,
    tagForUnderAgeOfConsent: true,
  });
};
```

### 3.4 Pricing Table

| Plan | Price | Billing | Target |
|------|-------|---------|--------|
| Free | 0 PLN | — | Everyone |
| Premium Student | 1.99 PLN/mo | Monthly | Individual students |
| Premium Annual | 16.99 PLN/yr | Yearly | Save ~29% |
| School Plan | 299 PLN/yr | Yearly | School buys for whole school |

### 3.5 Why These Prices
- 1.99 PLN/month ≈ cost of one bus ticket. Psychologically accessible.
- Annual is ~29% cheaper → encourages longer commitment
- School Plan: 299 PLN / 300 students = ~1 PLN per student per year. Easy to justify to a principal.

---

## 4. Growth Strategy

### 4.1 Viral loop (built into the product)
1. Class admin creates class
2. Shares join code with 30 classmates
3. Each classmate installs the app
4. Some become admins in the next year → repeat

### 4.2 Word-of-mouth amplification
- The app is most useful when the whole class uses it
- "Hej, masz KlassMate? Bo my mamy już całą klasę" is a natural conversation

### 4.3 School adoption path
- Start with one motivated class (organic)
- School hears about it → reaches out for School Plan
- School IT recommends to all classes

### 4.4 SEO / App Store Optimisation
- Keywords: "zadania domowe", "klasa aplikacja", "plan lekcji", "szkoła aplikacja"
- Localisation: Polish App Store description first, English secondary

---

## 5. Success Metrics (per phase)

### Phase 1 success
- 1 class actively using the app for 4 weeks
- 0 safety incidents
- <2s message delivery time on 4G

### Phase 2 success
- 10 classes, >100 active users
- Moderation queue: <30 min average review time by admins
- Crash-free rate: >99%

### Phase 3 success
- 100 classes, >1000 active users
- 5% conversion to premium
- School plan: 1 school signed up
