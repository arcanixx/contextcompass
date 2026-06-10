# 06_FEATURES_SPEC.md
# Path: docs/06_FEATURES_SPEC.md
# Purpose: Detailed feature specification — UX flows, help system, notifications, notes, DMs
# Depends on: 00_PROJECT_OVERVIEW.md, 01_ARCHITECTURE.md

---

# KlassMate — Feature Specification

---

## 1. Help System Architecture

The help system has four components that work together:

### 1.1 Onboarding (first-time users)
- **Splash screen** — app logo + animated tagline, 2s, then auto-advance
- **Onboarding slides** — 4 slides, swipeable, skippable:
  1. "Witaj w KlassMate — zadania domowe bez chaosu"
  2. "Kanały przedmiotowe — wszystko na swoim miejscu"
  3. "Moderacja — bezpieczne środowisko"
  4. "Notatki — zrób zdjęcie zeszytu, my zamienimy je na tekst"
- Slides shown only once, stored in `SecureStore` (not re-shown after login)
- "Pomiń" button always visible

### 1.2 Contextual Tooltips
Every non-obvious UI element has a tooltip shown on **first interaction** (tracked in user `settings` JSONB):

```typescript
// Tooltip tracking in user settings
type SeenTooltips = {
  moderation_queue: boolean;
  join_code: boolean;
  trusted_device: boolean;
  voice_message: boolean;
  ocr_button: boolean;
  admin_trim: boolean;
  archive_class: boolean;
};
```

Tooltip appearance:
- Shown once, then dismissed forever per user
- Tap anywhere to dismiss
- "Nie pokazuj ponownie" checkbox
- Arrow pointing to the element
- Max 2 lines of text

Example tooltips:
| Element | Tooltip text |
|---------|-------------|
| Moderation queue icon | "Tu trafiają wiadomości wymagające sprawdzenia. Tylko admini widzą tę sekcję." |
| Join code field | "Ten 6-znakowy kod wysyłasz kolegom z klasy, żeby mogli dołączyć." |
| Voice message button | "Przytrzymaj, żeby nagrać wiadomość głosową (maks. 60 sekund)." |
| OCR button in Notes | "Zrób zdjęcie strony z zeszytu — zamienimy je na tekst do edycji." |
| Archive class button | "Archiwizacja zamrozi klasę na końcu roku. Możesz ją czytać, ale nie pisać." |
| Trusted device toggle | "Zaufane urządzenia nie wylogują Cię automatycznie po bezczynności." |

### 1.3 Toast Messages

Every user action receives feedback. Toast appears at the bottom of the screen, auto-dismisses after 3s (errors: 5s, require tap).

| Action | Toast type | Message |
|--------|-----------|---------|
| Message sent | success | "Wiadomość wysłana" |
| Message pending moderation | info | "Wiadomość jest weryfikowana przez moderatora" |
| Message rejected | error | "Wiadomość narusza zasady społeczności" |
| File upload success | success | "Plik dodany pomyślnie" |
| File too large | error | "Plik jest za duży. Maksymalny rozmiar to 5 MB." |
| Voice recording saved | success | "Wiadomość głosowa gotowa do wysłania" |
| Member approved | success | "Uczeń został dodany do klasy" |
| Member rejected | info | "Prośba o dołączenie odrzucona" |
| User blocked | info | "Użytkownik zablokowany. Możesz go odblokować w ustawieniach." |
| Note saved | success | "Notatka zapisana" |
| OCR complete | success | "Tekst rozpoznany — sprawdź i edytuj przed zapisem" |
| OCR failed | error | "Nie udało się rozpoznać tekstu. Spróbuj przy lepszym oświetleniu." |
| Biometric enabled | success | "Face ID włączony" |
| Backup started | info | "Eksport danych w toku..." |
| Backup complete | success | "Kopia zapasowa zapisana na Google Drive" |
| No network | error | "Brak połączenia z internetem. Sprawdź Wi-Fi lub dane mobilne." |
| Session expired | warning | "Sesja wygasła. Zaloguj się ponownie." |

Toast component supports:
- `type`: `'success' | 'error' | 'warning' | 'info'`
- `action`: optional button (e.g. "Ponów próbę", "Odblokuj")
- `duration`: auto or `'persistent'` (requires tap to dismiss)

### 1.4 Help Center (in-app)
Accessible via Settings → Pomoc:
- Searchable FAQ list
- Topics: "Jak dołączyć do klasy?", "Co to jest moderacja?", "Jak usunąć konto?", etc.
- Link to contact email for support
- Privacy Policy (rendered in-app WebView, not external browser)
- Terms of Service

---

## 2. Authentication UX

### 2.1 Login Screen
- Email + password (primary)
- "Zaloguj się przez Google" (OAuth)
- "Zaloguj się przez Apple" (OAuth, iOS only)
- "Zapomniałem hasła" → magic link to email
- "Nie mam konta — zarejestruj się"

### 2.2 Registration Flow
```
Step 1: Email + password (strength indicator shown)
Step 2: Display name ("Jak masz na imię?") — shown to classmates
Step 3: Birth year selection — determines consent requirement
    │
    ├── Age ≥ 16 → proceed directly
    └── Age < 16 → parental consent flow:
                   "Potrzebujemy zgody rodzica"
                   Enter parent's email
                   → Email sent to parent with consent link
                   → App shows "Czekamy na zgodę rodzica"
                   → Parent clicks link → consent recorded → user can proceed
Step 4: Terms of Service + Privacy Policy — must scroll to bottom to accept
Step 5: Optional: enable biometrics
Step 6: Onboarding slides
```

### 2.3 Biometric Unlock Flow
```
App opens (session valid, device trusted)
    │
    ├── Biometric available + user has enabled it?
    │       │
    │   YES ─┤──► Show biometric prompt immediately
    │         │       │
    │         │   SUCCESS ──► Enter app
    │         │   FAIL ──────► "Nie rozpoznano. Spróbuj ponownie."
    │         │   FAIL ×3 ────► Show password field
    │         │
    │   NO ──►│──► Show email/password OR quick-unlock if no biometrics
    │
    └── Biometric available but user hasn't decided?
            │
            └──► Show password, after success offer biometric setup
```

### 2.4 Quick Re-auth (for sensitive actions)
A bottom sheet appears instead of navigating to login:

```
┌─────────────────────────────────────────┐
│  Potwierdź swoją tożsamość              │
│  Aby kontynuować, użyj Face ID          │
│                                         │
│  [  👤  Użyj Face ID  ]                │
│                                         │
│  ──── lub ────                          │
│  [Wpisz hasło zamiast tego]             │
└─────────────────────────────────────────┘
```

---

## 3. Channels & Messaging

### 3.1 Channel List (sidebar)
- Channel name + subject emoji (e.g. 📐 Matematyka, 📖 Polski)
- Unread message count badge (red dot with number)
- Muted channels shown with strikethrough icon
- Pinned channels at top with 📌
- Archived channels collapsed under "Archiwum" section (read-only)
- Long press on channel → context menu: Wycisz / Przypnij / Zgłoś (admin: Edytuj / Usuń)

### 3.2 Message Composer
Features:
- Text input (multiline, expands to max 5 lines)
- Character counter at 1500/2000
- Attach image button → image picker → auto-compress before send
- Voice message button → hold to record, release to send (or tap to preview first)
- Send button — disabled when empty

Placeholder text: `"Napisz wiadomość w #${channelName}..."` (i18n interpolated)

### 3.3 Message Bubble
- Own messages: right-aligned, primary colour background
- Others' messages: left-aligned, grey background, avatar + name shown
- Long press → context menu:
  - "Odpowiedz w wątku" (creates/opens thread)
  - "Skopiuj tekst"
  - "Zgłoś wiadomość"
  - (admin only) "Usuń wiadomość"
- Voice message: waveform visualiser + play button + duration
- Image attachment: thumbnail, tap to full-screen
- "Twoja wiadomość jest weryfikowana" — dimmed placeholder bubble for pending messages

### 3.4 Threads
- Tap "Odpowiedz w wątku" to create or open a thread on a message
- Thread appears as a panel/sheet sliding from the right (tablet: side panel)
- Thread shows original message at top, replies below
- Thread title editable by admin
- Threads listed in sidebar below channel name, indented

---

## 4. Moderation UX (Admin)

### 4.1 Moderation Queue Screen
- Only visible to class admins
- Red badge on the shield icon in sidebar when queue is non-empty
- List of messages awaiting review:
  - Sender name + avatar
  - Message preview (truncated to 3 lines)
  - Reason flagged: "Możliwa wulgarność", "Zgłoszono przez użytkownika"
  - Time since flagged

### 4.2 Admin Actions on a Queued Message
```
┌──────────────────────────────────────────────────────────┐
│  Wiadomość od: Jan Kowalski                             │
│  Kanał: #matematyka                                      │
│  ─────────────────────────────────────────────────────  │
│  "Ej ktoś rozwiązał to zadanie bo ta k**** jest          │
│   za trudna, strona 45 zad 3"                           │
│  ─────────────────────────────────────────────────────  │
│  Powód flagi: Możliwa wulgarność (pewność: 87%)         │
│                                                          │
│  [✅ Zatwierdź całą]  [✂️ Przytnij]  [❌ Odrzuć]        │
└──────────────────────────────────────────────────────────┘
```

**Trim flow:**
1. Admin taps "Przytnij"
2. Message text shown with selectable regions
3. Admin highlights the word/phrase to remove
4. Preview shown: "Ej ktoś rozwiązał to zadanie bo ta [usunięto] jest za trudna, strona 45 zad 3"
5. "Wyślij przycięty tekst" → message sent with `moderation_status = 'trimmed'`
6. Sender receives toast: "Fragment Twojej wiadomości został usunięty przez moderatora i wiadomość została opublikowana."

**Admin cannot:**
- Edit the content themselves (only remove segments)
- See the content of DMs
- See who reported a DM (anonymised)

---

## 5. Direct Messages (DMs)

### Rules
- Available only between members of the same class
- Text only (no images — privacy protection)
- Voice messages allowed (same 60s limit)
- Both users must be approved class members
- Either user can block the other (bilateral — both stop seeing each other's DMs)

### Block flow
1. User taps "Zablokuj" from member list or DM
2. Confirmation: "Na pewno chcesz zablokować Jana Kowalskiego? Nie będziecie mogli wysyłać sobie wiadomości."
3. Block recorded in `direct_conversations` (`a_blocked_b = true`)
4. Toast: "Jan Kowalski zablokowany"
5. Can be undone from Settings → Zablokowani użytkownicy

### DM moderation
- Automatic only (no human admin sees DM content)
- Profanity/hate: message auto-rejected, sender notified
- User can report a DM → anonymised report → app superadmin flagged (not class admin)

---

## 6. Personal Notes Module

### 6.1 Note types
- **Free note** — text, not linked to any class
- **Subject note** — linked to a class + channel (subject), shown in context

### 6.2 OCR Flow (photo to text)
```
User opens Notes → taps "+" → "Zdjęcie z zeszytu"
    │
    ├──► Camera opens (or image picker for existing photo)
    ├──► Image captured
    ├──► Loading toast: "Rozpoznajemy tekst..."
    ├──► Tesseract.js processes image (client-side, offline-capable)
    │       │
    │   SUCCESS ──► Show extracted text in editable field
    │               "Sprawdź i popraw tekst przed zapisem"
    │               [Zapisz jako notatkę]  [Anuluj]
    │
    │   LOW QUALITY / FAIL ──► Fallback to OCR.space API (server call)
    │               │
    │           SUCCESS ──► Show text (same flow)
    │           FAIL ──────► Toast: "Nie udało się rozpoznać tekstu.
    │                         Spróbuj przy lepszym oświetleniu lub
    │                         przesuń kamerę bliżej tekstu."
    │
    └──► Source image is NOT stored on server (privacy)
         Only the extracted text is saved to personal_notes table
```

### 6.3 Note Editor
- Simple rich text: bold, italic, bullet list, heading
- Subject/class tag picker
- Search notes by text content
- Notes are private — never shared to class (unless user deliberately copies text to message)

---

## 7. Notifications

### 7.1 Types & Channels
| Notification type | Push | In-app badge | In-app toast |
|------------------|------|-------------|-------------|
| New message in channel | ✅ | ✅ | ✅ (if app open) |
| @mention | ✅ | ✅ | ✅ |
| Thread reply | ✅ | ✅ | ✅ |
| New DM | ✅ | ✅ | ✅ |
| Member join request | ✅ (admin) | ✅ | ✅ |
| Message in moderation queue | ✅ (admin) | ✅ | ✅ |
| Message moderated (sender) | ✅ | ❌ | ✅ |
| Backup complete | ❌ | ❌ | ✅ |
| Session expiring (30 min) | ❌ | ❌ | ✅ (banner) |

### 7.2 Notification Settings (granular)
Settings → Powiadomienia:
- Master on/off toggle
- Per-class on/off
- Per-channel: All / Mentions only / Off
- DMs: on/off
- Sound: on/off
- Vibration: on/off
- Quiet hours: from/to time picker
- Notification preview in lock screen: on/off (privacy-conscious default: off)

### 7.3 Unread Indicators
- Channel in sidebar: bold name + blue dot + unread count
- Class card on home: total unread count badge
- Tab bar icon: total unread count badge
- DM conversation: bold name + count
- Reading a channel marks messages as read automatically (on scroll + 2s dwell time)

---

## 8. Online Status

- **Off by default** — must be explicitly enabled in Settings → Prywatność → Pokaż status online
- When enabled: green dot next to avatar on member list
- Statuses: `online` (active last 5 min), `away` (active last 30 min), `offline`
- A user can see others' status only if those users have status enabled
- Online status is scoped to class membership — shared device scenario:
  - Status updates only when the app is in foreground
  - Goes to `offline` immediately on explicit logout

---

## 9. Backup & Export

### 9.1 Available in Phase 2 (flag: `FEATURES.BACKUP_GDRIVE`)

User flow:
1. Settings → Kopia zapasowa → "Połącz Google Drive"
2. OAuth flow — KlassMate requests `drive.file` scope only (narrowest possible scope)
3. User selects: what to back up (messages / notes / both), date range
4. "Eksportuj teraz" → Edge Function generates ZIP
5. ZIP uploaded to user's Google Drive folder "KlassMate Backup"
6. Toast: "Kopia zapasowa zapisana na Google Drive"

### 9.2 Backup format
```
klassmatch_backup_YYYY-MM-DD.zip
├── README.txt          (human-readable explanation)
├── profile.json        (user's own profile data)
├── classes/
│   └── [class-name]/
│       ├── channels/
│       │   └── [channel-name].json   (messages array)
│       └── members.json
└── notes/
    └── notes.json
```

### 9.3 RODO: Data deletion
Settings → Konto → "Usuń konto":
1. Biometric / password re-auth required
2. Confirmation: "Czy na pewno chcesz usunąć konto? Tej operacji nie można cofnąć."
3. Edge Function `delete-user-data` runs:
   - Anonymises `profiles` record (name → "Usunięty użytkownik", avatar deleted)
   - Soft-deletes all messages (content nulled, `deleted_at` set)
   - Removes from all `class_members`
   - Deletes all `personal_notes`
   - Removes all `devices`
   - Marks auth user for deletion in Supabase Auth
4. Toast + navigate to goodbye screen

---

## 10. Admin: Class Management

### 10.1 Creating a class
1. Name + school name (optional) + school year
2. System generates 6-character join code (e.g. `KM-4F2X`)
3. Admin can regenerate code at any time (old code invalidated)
4. Admin can optionally set: max members, require admin approval for join

### 10.2 Approving members
```
New join request notification arrives
    │
    ├──► Admin sees: [Avatar] Jan Kowalski chce dołączyć do klasy
    │    [✅ Zatwierdź] [❌ Odrzuć]
    │
    ├──► Approve → class_members status = 'approved'
    │    → Toast to admin: "Jan Kowalski dodany do klasy"
    │    → Notification to user: "Twoja prośba o dołączenie do klasy została zatwierdzona"
    │
    └──► Reject → class_members status = 'rejected'
         → Notification to user: "Twoja prośba o dołączenie do klasy została odrzucona"
```

### 10.3 Year-end archiving
1. Admin taps "Archiwizuj klasę"
2. Confirmation + info: "Klasa stanie się archiwalna. Uczniowie będą mogli przeglądać historię, ale nie pisać nowych wiadomości."
3. Optional: "Utwórz nową klasę na nowy rok szkolny" (pre-fills name, copies channel structure)
4. Archived class visible under "Archiwum" with lock icon
5. Archived class messages retained for 2 years, then auto-deleted (configurable)

### 10.4 Admin permissions
- Promote member to admin (requires confirmation)
- Demote admin to member
- Ban member (cannot re-join without new approval)
- Delete any message in the class
- Edit channel names/descriptions
- Reorder channels
- Archive the class
