# 00_PROJECT_OVERVIEW.md
# Path: docs/00_PROJECT_OVERVIEW.md
# Purpose: Master project assumptions, goals, and scope definition
# Depends on: nothing (root document)

---

# KlassMate — Project Overview & Foundational Assumptions

> **Version:** 0.1.0-draft  
> **Last updated:** 2026-06  
> **Status:** Pre-development, design phase

---

## 1. What Is KlassMate?

KlassMate is a **safe, moderated, student-to-student communication platform** for school classes. Its core purpose is mutual help around homework — not copying answers, but sharing information: which pages to read, what was covered in class, what the teacher assigned. Think of it as a private class group chat, but structured, moderated, and built with children's safety as a first-class feature.

### What it is NOT:
- Not a homework-answer sharing site (not like Brainly)
- Not a teacher-management tool (not ClassDojo)
- Not a general social network
- Not a replacement for the school register (dziennik elektroniczny)

---

## 2. Target Users

| Role | Description |
|------|-------------|
| **Student (member)** | Primary user. Posts questions, shares info, reads messages |
| **Class Admin** | Student or teacher with elevated permissions. Approves members, moderates content |
| **Parent/Guardian** | Passive role — provides consent for minors, no direct app access in MVP |
| **App Superadmin** | Developer-level access. Error logs, system health only. Never sees message content |

**Age range:** Primarily 10–19. Core legal concern: users under 16 (RODO/Poland) require verifiable parental consent.

---

## 3. Core Value Propositions

1. **Homework information sharing** — "We have math from page 45, exercises 3–5"
2. **Safe environment** — two-layer moderation (AI + human admin)
3. **Class-scoped** — not open internet, closed groups only
4. **No expert required** — a 12-year-old can run it as class admin
5. **No API keys, no external accounts required** — the app works out of the box

---

## 4. Platform Targets

| Platform | Priority | Notes |
|----------|----------|-------|
| Web (PWA) | P0 | Works in any browser, installable |
| Android | P1 | React Native / Expo |
| iOS | P1 | React Native / Expo |
| Tablet (iPad/Android) | P2 | Responsive layouts required |

---

## 5. Tech Stack Decision

| Layer | Choice | Reason |
|-------|--------|--------|
| Frontend | React Native + Expo (SDK 52+) | Web + mobile from one codebase |
| Web target | Expo for Web (PWA) | No separate web app needed |
| Backend | Supabase (Frankfurt/eu-central-1) | EU data residency, RLS, Auth, Realtime |
| DB | PostgreSQL via Supabase | Mature, RLS support |
| File storage | Supabase Storage | Integrated, same auth context |
| Edge logic | Supabase Edge Functions (Deno) | Content moderation, compression |
| State management | Zustand | Lightweight, no boilerplate |
| Styling | NativeWind (Tailwind for RN) | Consistent, theming support |
| Navigation | Expo Router v3 | File-based, typed routes |
| Testing | Jest + React Native Testing Library | Unit + integration |
| Error tracking | Sentry (self-hosted or EU SaaS) | GDPR-safe error reporting |
| OCR (notes module) | Tesseract.js (client-side, free) + fallback to OCR.space free tier | No user API keys needed |
| Content moderation AI | Supabase Edge Function calling free/internal models | No external paid API required |
| Push notifications | Expo Notifications + Web Push API | Cross-platform |
| i18n | i18next + react-i18next | No hardcoded strings |

### On OCR Strategy (critical decision):
- **Primary:** Tesseract.js runs in-browser/in-app, no API key, no cost, works offline
- **Fallback:** OCR.space free tier (500 req/day/IP, no registration) for difficult images
- **NOT used:** Google Vision API, AWS Textract, any service requiring user-created API keys
- The 10-year-old user never touches API configuration. The app handles everything.

### On Content Moderation AI:
- MVP uses a **rule-based profanity filter** (open-source Polish+English word lists)
- A Supabase Edge Function runs the check server-side before any message is stored
- Phase 2 adds a free/open AI model via Edge Function (no user keys needed)
- Paid external moderation APIs (Azure Content Safety etc.) are evaluated only if moderation quality is insufficient and the app has revenue to support it

---

## 6. Supabase & GDPR Notes

<br/>

**Supabase region: `eu-central-1` (Frankfurt, Germany)**

This satisfies **data residency** (data physically stored in EU). It does **not** fully solve **data sovereignty** (Supabase is a US-incorporated company, subject to CLOUD Act). For a children's educational app operated by a small developer in Poland:

- Frankfurt region is acceptable for RODO compliance for most use cases
- A **Data Processing Agreement (DPA)** with Supabase must be signed (available in Supabase dashboard)
- For Phase 2/commercial scale, evaluate EU-native alternatives: **Neon.tech** (Frankfurt), **PocketBase** (self-hosted), or **Directus** on Polish VPS
- All data must be deletable per RODO "right to be forgotten" — implemented from day 1

---

## 7. Market Gap Analysis

Based on research (June 2026):

| App | What it does | What's missing |
|-----|-------------|----------------|
| ClassDojo | Teacher→parent communication | No student-to-student collaboration |
| Google Classroom | Assignment management by teachers | No peer help, teacher-controlled only |
| Brainly | Open Q&A for homework answers | Public internet, no class privacy, answer-sharing focus |
| My Study Life / Class Timetable | Personal planner only | No communication features |
| Flip (ex-Flipgrid) | Video responses, teacher-led | Teacher-centric, not peer-to-peer |

**Conclusion:** There is no Polish-language, student-run, closed-group, homework-information-sharing app with built-in moderation for minors. This is the gap KlassMate fills.

---

## 8. Monetisation Strategy

### Tier 1: Free (default for all)
- All core features: channels, threads, file sharing, voice messages, notifications
- Storage limit: 200 MB per class
- Message history: last 90 days visible
- Ads: subtle banner, once per session (no video ads in MVP)

### Tier 2: Premium — 1.99 PLN/month or 16.99 PLN/year per user
- No ads
- Full message history (unlimited)
- Storage limit: 2 GB per class
- Auto-backup to Google Drive / iCloud
- Longer voice messages (up to 5 min vs 60s free)
- Custom theme colour
- Priority moderation queue

### Tier 3: School Plan — 299 PLN/year per school
- Unlimited classes
- Teacher dashboard (read-only analytics)
- Admin override for all classes
- Priority support

### Revenue philosophy:
- Never lock safety features behind paywall
- Never lock moderation tools behind paywall
- Monetise convenience and history, not communication itself

---

## 9. Open Questions for Owner — PLEASE ANSWER BEFORE DEVELOPMENT

> These questions affect architecture decisions that are expensive to change later.

### 🔴 Critical (must answer before writing code)

1. **App name:** "KlassMate" is working name. Do you have a preferred name? This affects package IDs, domain, Supabase project name.

2. **Parental consent mechanism:** For users under 16, RODO requires verifiable parental consent. Options:
   - **A)** Email sent to parent-provided address, parent clicks confirmation link *(simplest, legally borderline)*
   - **B)** Parent creates own account and approves child *(safest legally, more friction)*
   - **C)** Class admin (e.g. teacher) vouches for all students *(shifts liability)*
   
   **Which approach is acceptable to you?**

3. **Who can be a Class Admin?** 
   - **A)** Any student in the class (self-organised)
   - **B)** Only a verified teacher
   - **C)** Student, but teacher must approve the class creation
   
   **This affects the trust model significantly.**

4. **Screenshot prevention:** React Native can partially prevent screenshots (Android: `FLAG_SECURE`, iOS: detection only, cannot fully block). On web — impossible to prevent. Do you want to implement best-effort prevention, or is this a hard requirement that might affect platform support?

5. **Voice messages vs "recording conversations":** The original request mentioned "recording conversations aloud". This is very different legally from "sending a voice message":
   - Voice message = one person records, sends to channel = **OK**
   - Recording a live conversation = all participants must consent = **legally complex**
   
   **Confirming: MVP will support voice messages only (no live recording), correct?**

### 🟡 Important (answer before Phase 2)

6. **Backup format:** When a user exports backup to Google Drive, what format? 
   - **A)** JSON export (technical, full fidelity)
   - **B)** PDF/ZIP of readable content (user-friendly, loses structure)
   - **C)** Both

7. **Private messages media:** Should private 1:1 messages allow image sending? (Original spec says no, current doc says "without sending images directly" — confirming this exclusion?)

8. **Class archive:** When a class is archived (new school year), should students still be able to READ archived content? For how long? (Suggestion: 2 years, then auto-delete)

9. **Online status:** Should online status be opt-in (user enables it in settings) or opt-out (on by default, user can hide)?

10. **Ads provider:** If using ads in free tier, which network? Google AdMob is standard but requires app review and has policies for apps targeting children (COPPA/GDPR-K compliant ad serving required).

### 🟢 Nice to have clarity on

11. **Default language:** Polish only for MVP, or Polish + English from day 1?

12. **Notes module OCR:** Should OCR results be editable before saving, or auto-saved as-is?

13. **Theme options:** Dark/light only (sync with system), or also custom colour palettes?
