# 05_LEGAL_COMPLIANCE.md
# Path: docs/05_LEGAL_COMPLIANCE.md
# Purpose: Legal requirements — RODO/GDPR, children's data, disclaimers, ToS
# Depends on: 00_PROJECT_OVERVIEW.md

---

# KlassMate — Legal & Compliance

> ⚠️ This document is a developer's checklist, not a legal opinion.
> Before launch, consult a Polish attorney specialising in RODO/data protection.

---

## 1. Applicable Regulations

| Regulation | Applies because | Key requirement |
|-----------|----------------|----------------|
| **RODO (GDPR)** | App operates in Poland/EU, processes EU citizens' data | Lawful basis for processing, consent, right to erasure |
| **RODO Art. 8** | Users under 16 in Poland | Verifiable parental consent for under-16s |
| **COPPA (US)** | If App Store/Play Store distribution reaches US users under 13 | Parental consent for under-13s |
| **DSA (Digital Services Act)** | Platform hosting user-generated content | Moderation requirements, transparency reports |
| **Ustawa o świadczeniu usług drogą elektroniczną** | Polish digital services law | Terms of Service, cookie policy |
| **Prawo autorskie (Copyright)** | Users may share copyrighted content (textbook photos) | Clear policy on acceptable use of copyrighted material |

---

## 2. RODO Compliance Checklist

### 2.1 Lawful Basis for Processing
| Data type | Lawful basis |
|-----------|-------------|
| Account data (name, email) | Contract performance (Art. 6(1)(b)) |
| Messages, posts | Contract performance |
| Under-16 users' data | Parental consent (Art. 6(1)(a) + Art. 8) |
| Error logs / analytics | Legitimate interests (Art. 6(1)(f)) — minimised, anonymised |
| Push notification tokens | Consent (Art. 6(1)(a)) |

### 2.2 Data Minimisation (must implement)
- Store only `birth_year`, never full birth date
- No collection of: phone number, home address, school address, geolocation
- Push tokens: stored per device, deleted on logout
- Error logs: no message content, only error codes and anonymised user IDs
- Analytics: aggregate only (e.g. "class has 24 members"), no individual tracking

### 2.3 Data Retention Limits
| Data | Retention | Auto-delete trigger |
|------|-----------|-------------------|
| Active messages | Unlimited (free) / Unlimited (premium) | Class archived → 2 years → auto-delete |
| Archived class messages | 2 years from archive date | Automated CRON job |
| Deleted user messages | 30 days (anonymised) | `delete-user-data` Edge Function |
| Audit logs | 12 months | CRON cleanup |
| Error logs (Sentry) | 90 days | Sentry retention policy |
| Push tokens | Until logout or device removal | Device deregistration |
| Backup files (user's Drive) | User controls (it's their Drive) | N/A |

### 2.4 User Rights Implementation
| Right | How implemented |
|-------|----------------|
| Right to access | Settings → "Pobierz swoje dane" → JSON export |
| Right to erasure | Settings → "Usuń konto" → `delete-user-data` Edge Function |
| Right to rectification | Settings → Edit profile (name, avatar) |
| Right to portability | Same as access — machine-readable JSON |
| Right to object (analytics) | Settings → Prywatność → "Wyłącz analitykę" |
| Right to restrict processing | Contact form → manual process (pre-launch requirement) |

---

## 3. Children's Data — Parental Consent (Critical)

### 3.1 Age gate logic
```
Registration: user enters birth_year
    │
    ├── Current year - birth_year >= 16 → no parental consent needed → proceed
    │
    └── Current year - birth_year < 16 → PARENTAL CONSENT REQUIRED
              │
              ├──► "Potrzebujemy zgody rodzica lub opiekuna prawnego"
              ├──► Enter parent/guardian email address
              ├──► Send verification email to parent
              │    Subject: "Zgoda na korzystanie z KlassMate przez Twoje dziecko"
              │    Body: clear explanation of what data is collected, how moderation works,
              │    parent's rights, link to Privacy Policy
              │    [WYRAŹ ZGODĘ] [ODMÓW]
              │
              ├──► App shows waiting screen: "Czekamy na potwierdzenie od rodzica"
              │    Resend email option after 24h
              │    Account in 'pending_consent' state — cannot use app
              │
              ├──► Parent clicks WYRAŹ ZGODĘ → consent_given_at recorded
              │    → User notified: "Rodzic wyraził zgodę. Możesz teraz korzystać z aplikacji!"
              │
              └──► Parent clicks ODMÓW → account marked rejected
                   → User notified: "Rodzic nie wyraził zgody. Skontaktuj się z rodzicem."
```

### 3.2 What parents are consenting to (must be clear in email)
- Display name and email stored
- Messages sent in class channels stored on EU servers
- Messages reviewed by automated moderation system
- Class admin (a classmate or teacher) can see and moderate messages
- Notification tokens stored on device
- Data stored until account deletion
- Data is NOT sold, NOT used for advertising profiling, NOT shared with third parties

### 3.3 Revoking parental consent
- Parent can email `privacy@klassmatch.pl` at any time
- Results in account suspension and data deletion within 30 days
- Must be documented in Privacy Policy

---

## 4. In-App Legal Documents

All legal documents must be:
- Readable in-app (no external browser required)
- Written in plain Polish (not legalese)
- Versioned (users notified when updated, must re-accept for major changes)
- Available before registration (linked from login screen)

### 4.1 Privacy Policy must cover
- Who is the data controller (your name/company, address)
- What data is collected and why
- How long data is kept
- Who data is shared with (Supabase/AWS as processor, Sentry as processor)
- Children's data section (explicit)
- How to exercise RODO rights (email address)
- Cookie/local storage usage

### 4.2 Terms of Service must cover
- Permitted use (homework info sharing, mutual help)
- Prohibited use — explicit list:
  - Sharing complete homework solutions with intent to copy
  - Sharing copyrighted textbook content beyond "fair use"
  - Hate speech, bullying, discrimination
  - Sharing personal data of others
  - Impersonating others
  - Spam
- Moderation rules and consequences (warning → temporary ban → permanent ban)
- Account termination process
- Limitation of liability (app is not responsible for content posted by users)
- Applicable law: Polish law, jurisdiction: Poland

### 4.3 Community Guidelines (separate, simpler document)
Written at reading level for 12-year-olds:
- "Traktuj innych tak, jak sam chcesz być traktowany"
- "Nie przesyłaj gotowych rozwiązań — pomóż zrozumieć, nie ściągaj"
- "Zdjęcia z książek — tylko fragmenty, nie całe rozdziały"
- "Jeśli ktoś Ci przeszkadza — zablokuj i zgłoś, nie odpowiadaj"

---

## 5. Copyright Considerations

Users will share photos of textbook pages. This raises copyright issues:

### 5.1 Acceptable use (fair use / dozwolony użytek)
Under Polish copyright law (Art. 27 Pr. Aut.), educational use allows limited reproduction for teaching purposes. However, this applies to schools/teachers, not necessarily student apps.

### 5.2 Required policy
- Limit image size (5 MB) — discourages full chapter scanning
- Terms of Service explicitly state: "Nie przesyłaj całych rozdziałów, stron z podręcznika lub innych chronionych materiałów"
- DMCA-style notice & takedown process: publishers can contact `copyright@klassmatch.pl`
- Add watermark warning on image upload: "Pamiętaj: przesyłaj tylko fragmenty potrzebne do zadania"

### 5.3 OCR feature and copyright
The Notes OCR feature converts textbook photos to personal notes. This is for private use and falls under private copy exceptions. The extracted text is stored only in the user's private notes, never broadcast publicly.

---

## 6. Moderation & DSA Compliance

Under the EU Digital Services Act (applies to platforms with UGC):

### 6.1 Required moderation mechanisms
- ✅ Mechanism for users to report illegal content (implemented: "Zgłoś wiadomość")
- ✅ Timely action on reports (admin moderation queue)
- ✅ Transparency to the person who posted the content (moderation result notifications)
- ✅ Right to appeal moderation decisions (contact form → process defined in ToS)

### 6.2 Transparency reporting (Phase 2)
- Annual report on: number of messages moderated, reasons, outcomes
- Required once the platform grows beyond "micro-enterprise" threshold

---

## 7. Implementation Checklist (Pre-Launch)

- [ ] Privacy Policy written and reviewed by lawyer
- [ ] Terms of Service written and reviewed by lawyer
- [ ] Community Guidelines written (plain language)
- [ ] Parental consent email flow implemented and tested
- [ ] `delete-user-data` Edge Function implemented and tested
- [ ] Data export (right to access) implemented
- [ ] Supabase DPA (Data Processing Agreement) signed via dashboard
- [ ] Sentry DPA reviewed (or replaced with EU-hosted alternative)
- [ ] App Store / Google Play privacy questionnaire completed correctly
  - Declare: data types collected (name, email, user content, device ID)
  - Declare: children's app (age rating appropriately set)
  - Do NOT check "data used for advertising" unless running ad targeting
- [ ] Age gate tested for edge cases (year boundary, invalid year, no year entered)
- [ ] Cookie/local storage notice on web version
- [ ] Contact email addresses set up: `privacy@`, `security@`, `copyright@`
- [ ] RODO rights process documented internally (how to handle manual requests)
