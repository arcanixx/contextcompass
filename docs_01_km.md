# 01_ARCHITECTURE.md
# Path: docs/01_ARCHITECTURE.md
# Purpose: System architecture, data models, file structure, API contracts
# Depends on: 00_PROJECT_OVERVIEW.md

---

# KlassMate — Architecture Document

---

## 1. Architecture Style: Backend-for-Frontend (BFF)

```
┌─────────────────────────────────────────────────────────┐
│                     CLIENT APPS                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  iOS (Expo)  │  │Android (Expo)│  │  Web (PWA)   │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         └──────────────────┼──────────────────┘          │
│                            │ HTTPS / WSS                  │
└────────────────────────────┼─────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────┐
│                  SUPABASE (Frankfurt, EU)                  │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Auth      │  │  PostgREST   │  │  Realtime (WS)   │  │
│  │  (GoTrue)  │  │  (REST API)  │  │  Subscriptions   │  │
│  └────────────┘  └──────────────┘  └──────────────────┘  │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Storage   │  │  PostgreSQL  │  │  Edge Functions  │  │
│  │  (S3-like) │  │  + RLS       │  │  (Deno/TS)       │  │
│  └────────────┘  └──────────────┘  └──────────────────┘  │
└───────────────────────────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────┐
│              EXTERNAL SERVICES (optional, free tier)      │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │ Sentry (EU)  │  │  OCR.space   │  │  Expo Push     │  │
│  │ Error logs   │  │  (fallback)  │  │  Notifications │  │
│  └──────────────┘  └──────────────┘  └────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

**Key principle:** The client NEVER has direct DB credentials. All writes go through Supabase Auth + RLS. All dangerous operations (moderation, compression, push notifications) go through Edge Functions.

---

## 2. Database Schema

### Naming conventions
- Tables: `snake_case`, plural
- Columns: `snake_case`
- PKs: `id uuid DEFAULT gen_random_uuid()`
- Timestamps: `created_at`, `updated_at` (always `timestamptz`)
- Soft delete: `deleted_at timestamptz` (never hard-delete user content)

---

### Table: `profiles`
```sql
CREATE TABLE profiles (
  id            uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name  text NOT NULL CHECK (char_length(display_name) BETWEEN 2 AND 50),
  avatar_url    text,
  role          text NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'teacher', 'superadmin')),
  birth_year    int,                        -- for RODO age check only, not stored as full date
  consent_given_at timestamptz,             -- parental consent timestamp
  consent_method   text,                   -- 'email_link' | 'parent_account' | 'admin_vouched'
  is_active     boolean NOT NULL DEFAULT true,
  settings      jsonb NOT NULL DEFAULT '{}',  -- notification prefs, theme, sound, online_status_visible
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
```

### Table: `classes`
```sql
CREATE TABLE classes (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text NOT NULL CHECK (char_length(name) BETWEEN 2 AND 100),
  school_name   text,
  school_year   text NOT NULL,             -- e.g. "2025/2026"
  join_code     text UNIQUE NOT NULL,      -- 6-char alphanumeric invite code
  is_archived   boolean NOT NULL DEFAULT false,
  archived_at   timestamptz,
  created_by    uuid NOT NULL REFERENCES profiles(id),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
```

### Table: `class_members`
```sql
CREATE TABLE class_members (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id      uuid NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  profile_id    uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role          text NOT NULL DEFAULT 'member' CHECK (role IN ('member', 'admin')),
  status        text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'banned')),
  approved_by   uuid REFERENCES profiles(id),
  approved_at   timestamptz,
  joined_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (class_id, profile_id)
);
```

### Table: `channels`
```sql
CREATE TABLE channels (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id      uuid NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  name          text NOT NULL CHECK (char_length(name) BETWEEN 1 AND 80),
  subject_emoji text,                      -- e.g. "📐" for math
  description   text,
  position      int NOT NULL DEFAULT 0,    -- display order
  is_archived   boolean NOT NULL DEFAULT false,
  created_by    uuid NOT NULL REFERENCES profiles(id),
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (class_id, name)
);
```

### Table: `threads`
```sql
CREATE TABLE threads (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id    uuid NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  title         text NOT NULL CHECK (char_length(title) BETWEEN 3 AND 200),
  created_by    uuid NOT NULL REFERENCES profiles(id),
  is_pinned     boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
```

### Table: `messages`
```sql
CREATE TABLE messages (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id      uuid REFERENCES threads(id) ON DELETE CASCADE,
  channel_id     uuid NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  dm_id          uuid REFERENCES direct_conversations(id) ON DELETE CASCADE,
  sender_id      uuid NOT NULL REFERENCES profiles(id),
  content        text,                     -- nullable if voice-only message
  voice_url      text,                     -- Supabase Storage path
  voice_duration int,                      -- seconds
  moderation_status text NOT NULL DEFAULT 'pending'
    CHECK (moderation_status IN ('pending', 'approved', 'queued_review', 'rejected', 'trimmed')),
  moderation_note text,                    -- internal note from admin/system
  original_content text,                   -- preserved if trimmed by admin
  edited_at      timestamptz,
  deleted_at     timestamptz,              -- soft delete
  created_at     timestamptz NOT NULL DEFAULT now(),
  -- A message must belong to either a channel OR a DM, not both
  CONSTRAINT message_target_check CHECK (
    (channel_id IS NOT NULL AND dm_id IS NULL) OR
    (dm_id IS NOT NULL AND channel_id IS NOT NULL)
  )
);
```

### Table: `attachments`
```sql
CREATE TABLE attachments (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id    uuid NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  storage_path  text NOT NULL,             -- Supabase Storage path
  file_type     text NOT NULL,             -- 'image' | 'pdf' | 'voice'
  mime_type     text NOT NULL,
  size_bytes    int NOT NULL,
  original_name text,
  width         int,                       -- for images
  height        int,                       -- for images
  created_at    timestamptz NOT NULL DEFAULT now()
);
```

### Table: `direct_conversations`
```sql
CREATE TABLE direct_conversations (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id      uuid NOT NULL REFERENCES classes(id),  -- DMs are scoped to a class
  participant_a uuid NOT NULL REFERENCES profiles(id),
  participant_b uuid NOT NULL REFERENCES profiles(id),
  a_blocked_b   boolean NOT NULL DEFAULT false,
  b_blocked_a   boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (class_id, participant_a, participant_b),
  CHECK (participant_a < participant_b)               -- canonical ordering
);
```

### Table: `moderation_queue`
```sql
CREATE TABLE moderation_queue (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id    uuid NOT NULL REFERENCES messages(id),
  class_id      uuid NOT NULL REFERENCES classes(id),
  reason        text NOT NULL,             -- why flagged: 'profanity' | 'hate' | 'spam' | 'reported'
  confidence    float,                     -- 0.0–1.0 from AI check
  status        text NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'approved', 'rejected', 'trimmed')),
  reviewed_by   uuid REFERENCES profiles(id),
  reviewed_at   timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now()
);
```

### Table: `notifications`
```sql
CREATE TABLE notifications (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id  uuid NOT NULL REFERENCES profiles(id),
  type          text NOT NULL,             -- 'new_message' | 'mention' | 'moderation' | 'member_request'
  payload       jsonb NOT NULL,            -- contextual data
  is_read       boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now()
);
```

### Table: `personal_notes`
```sql
CREATE TABLE personal_notes (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id      uuid NOT NULL REFERENCES profiles(id),
  class_id      uuid REFERENCES classes(id),   -- optional: linked to a class
  channel_id    uuid REFERENCES channels(id),  -- optional: linked to a subject
  title         text,
  content       text,
  source_image_url text,                   -- if created from OCR, reference to source
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
```

### Table: `devices`
```sql
CREATE TABLE devices (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  device_name    text,                     -- "Jan's iPhone", "School Tablet"
  device_type    text,                     -- 'ios' | 'android' | 'web'
  push_token     text,
  is_trusted     boolean NOT NULL DEFAULT false,  -- trusted = no session expiry
  last_seen_at   timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now()
);
```

### Table: `audit_log`
```sql
CREATE TABLE audit_log (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id      uuid REFERENCES profiles(id),
  action        text NOT NULL,             -- 'message_rejected' | 'member_banned' | etc.
  target_table  text,
  target_id     uuid,
  metadata      jsonb,
  created_at    timestamptz NOT NULL DEFAULT now()
);
-- Append-only. No updates or deletes ever.
```

---

## 3. Row Level Security (RLS) Policies — Key Examples

```sql
-- Users can only see messages in classes they are approved members of
CREATE POLICY "messages_select" ON messages FOR SELECT
USING (
  channel_id IN (
    SELECT c.id FROM channels c
    JOIN class_members cm ON cm.class_id = c.class_id
    WHERE cm.profile_id = auth.uid() AND cm.status = 'approved'
  )
  AND moderation_status IN ('approved', 'trimmed')
  AND deleted_at IS NULL
);

-- Users can only insert messages in their own name
CREATE POLICY "messages_insert" ON messages FOR INSERT
WITH CHECK (sender_id = auth.uid());

-- Only class admins can see the moderation queue for their class
CREATE POLICY "moderation_queue_admin_only" ON moderation_queue FOR SELECT
USING (
  class_id IN (
    SELECT cm.class_id FROM class_members cm
    WHERE cm.profile_id = auth.uid() AND cm.role = 'admin'
  )
);

-- Personal notes are private to their owner
CREATE POLICY "personal_notes_owner_only" ON personal_notes FOR ALL
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());
```

---

## 4. Edge Functions

Each Edge Function is a Deno TypeScript file under `supabase/functions/`.

| Function name | Trigger | Responsibility |
|--------------|---------|----------------|
| `moderate-message` | HTTP POST before message insert | Profanity check, hate speech filter, decision: approve/queue/reject |
| `compress-attachment` | Storage upload webhook | Resize + convert to WebP, reduce PDF quality |
| `send-push-notification` | DB trigger via pg_net | Fan-out push to all devices of recipient |
| `export-backup` | HTTP POST (authenticated) | Generate JSON or ZIP of class data, upload to user's cloud |
| `cleanup-expired-sessions` | CRON (daily) | Expire sessions on untrusted devices after 4h inactivity |
| `archive-class` | HTTP POST (admin) | Mark class + channels as archived, snapshot storage |
| `delete-user-data` | HTTP POST (authenticated) | RODO right-to-erasure: anonymise all user content |
| `ocr-process` | HTTP POST (authenticated) | Run Tesseract server-side or proxy to OCR.space fallback |

---

## 5. File & Folder Structure

```
klassmatch/
│
├── src/
│   ├── app/                          # Expo Router — screens and layouts
│   │   ├── _layout.tsx               # Root layout (providers, splash)
│   │   ├── (auth)/
│   │   │   ├── _layout.tsx
│   │   │   ├── login.tsx
│   │   │   ├── register.tsx
│   │   │   ├── verify-2fa.tsx
│   │   │   ├── consent.tsx           # Parental consent flow
│   │   │   └── onboarding.tsx        # First-time tutorial
│   │   ├── (main)/
│   │   │   ├── _layout.tsx           # Tab/drawer layout
│   │   │   ├── index.tsx             # Class list / home
│   │   │   ├── class/
│   │   │   │   ├── [classId]/
│   │   │   │   │   ├── _layout.tsx
│   │   │   │   │   ├── index.tsx     # Channel list (sidebar)
│   │   │   │   │   ├── channel/
│   │   │   │   │   │   └── [channelId].tsx
│   │   │   │   │   ├── members.tsx
│   │   │   │   │   ├── moderation.tsx  # Admin only
│   │   │   │   │   └── settings.tsx
│   │   │   ├── notes/
│   │   │   │   ├── index.tsx
│   │   │   │   └── [noteId].tsx
│   │   │   ├── dm/
│   │   │   │   └── [conversationId].tsx
│   │   │   └── settings/
│   │   │       ├── index.tsx
│   │   │       ├── notifications.tsx
│   │   │       ├── theme.tsx
│   │   │       ├── backup.tsx
│   │   │       ├── account.tsx
│   │   │       └── trusted-devices.tsx
│   │   └── debug/                    # DEV ONLY — flag-gated
│   │       ├── _layout.tsx           # Shows only when __DEV__ && DEBUG_MODE
│   │       ├── mock-messages.tsx
│   │       ├── mock-moderation.tsx
│   │       └── mock-notifications.tsx
│   │
│   ├── components/                   # Reusable UI, max 150 lines each
│   │   ├── ui/
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   ├── Avatar.tsx
│   │   │   ├── Badge.tsx
│   │   │   ├── Modal.tsx
│   │   │   ├── Toast.tsx
│   │   │   ├── Skeleton.tsx          # Loading states
│   │   │   └── EmptyState.tsx
│   │   ├── message/
│   │   │   ├── MessageBubble.tsx
│   │   │   ├── MessageInput.tsx
│   │   │   ├── VoiceMessagePlayer.tsx
│   │   │   ├── VoiceRecorder.tsx
│   │   │   ├── AttachmentPreview.tsx
│   │   │   └── ModerationBanner.tsx  # "Message awaiting review"
│   │   ├── class/
│   │   │   ├── ClassCard.tsx
│   │   │   ├── ChannelListItem.tsx
│   │   │   ├── MemberListItem.tsx
│   │   │   └── UnreadBadge.tsx
│   │   ├── moderation/
│   │   │   ├── ModerationQueueItem.tsx
│   │   │   └── TrimMessageModal.tsx
│   │   ├── notes/
│   │   │   ├── NoteCard.tsx
│   │   │   └── OcrUploader.tsx
│   │   └── shared/
│   │       ├── SplashScreen.tsx
│   │       ├── OnboardingSlide.tsx
│   │       └── OfflineBanner.tsx
│   │
│   ├── config/                       # Static configuration — no hardcoded values elsewhere
│   │   ├── index.ts                  # Re-exports all config
│   │   ├── app.config.ts             # App name, version, bundle IDs
│   │   ├── supabase.config.ts        # URL + anon key from env
│   │   ├── features.config.ts        # Feature flags
│   │   ├── limits.config.ts          # File size limits, max voice duration, etc.
│   │   ├── locales.config.ts         # Available languages, default language
│   │   └── moderation.config.ts     # Confidence thresholds, blocked word list ref
│   │
│   ├── constants/
│   │   ├── colors.ts                 # Theme color tokens (no hex in components)
│   │   ├── spacing.ts
│   │   ├── typography.ts
│   │   └── icons.ts                  # Icon name map (no string literals in components)
│   │
│   ├── contexts/
│   │   ├── AuthContext.tsx
│   │   ├── ThemeContext.tsx
│   │   └── NetworkContext.tsx        # Online/offline status
│   │
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useClass.ts
│   │   ├── useChannel.ts
│   │   ├── useMessages.ts
│   │   ├── useModeration.ts
│   │   ├── useNotifications.ts
│   │   ├── useOCR.ts
│   │   ├── useDMs.ts
│   │   └── useTheme.ts
│   │
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts             # Singleton Supabase client
│   │   │   ├── types.ts              # Generated DB types (supabase gen types)
│   │   │   └── queries/              # Named query functions, one file per domain
│   │   │       ├── messages.ts
│   │   │       ├── classes.ts
│   │   │       ├── members.ts
│   │   │       └── profiles.ts
│   │   ├── moderation/
│   │   │   ├── client.ts             # Calls Edge Function
│   │   │   └── wordlist.ts           # Local profanity list (fallback)
│   │   ├── storage/
│   │   │   ├── upload.ts             # Upload with compression
│   │   │   ├── compress.ts           # Image compression (react-native-compressor)
│   │   │   └── paths.ts              # Storage path builders
│   │   ├── ocr/
│   │   │   ├── tesseract.ts          # Tesseract.js wrapper
│   │   │   └── ocrspace.ts           # OCR.space fallback
│   │   ├── auth/
│   │   │   ├── session.ts            # Session management, device trust
│   │   │   └── twoFactor.ts          # 2FA helpers
│   │   └── errors/
│   │       ├── logger.ts             # Sentry integration
│   │       └── types.ts              # AppError types
│   │
│   ├── services/
│   │   ├── NotificationService.ts
│   │   ├── BackupService.ts
│   │   └── AnalyticsService.ts       # Privacy-first, minimal (only aggregate counts)
│   │
│   ├── store/                        # Zustand stores
│   │   ├── authStore.ts
│   │   ├── classStore.ts
│   │   ├── messageStore.ts
│   │   ├── notificationStore.ts
│   │   └── uiStore.ts                # Theme, modals, loading states
│   │
│   ├── types/
│   │   ├── index.ts
│   │   ├── auth.types.ts
│   │   ├── class.types.ts
│   │   ├── message.types.ts
│   │   └── moderation.types.ts
│   │
│   ├── utils/
│   │   ├── date.ts
│   │   ├── validation.ts
│   │   ├── format.ts
│   │   └── platform.ts               # Platform detection helpers
│   │
│   └── i18n/
│       ├── index.ts
│       ├── pl.json                   # Polish (default)
│       └── en.json                   # English
│
├── supabase/
│   ├── functions/
│   │   ├── moderate-message/
│   │   │   └── index.ts
│   │   ├── compress-attachment/
│   │   │   └── index.ts
│   │   ├── send-push-notification/
│   │   │   └── index.ts
│   │   ├── export-backup/
│   │   │   └── index.ts
│   │   └── delete-user-data/
│   │       └── index.ts
│   ├── migrations/
│   │   ├── 0001_initial_schema.sql
│   │   ├── 0002_rls_policies.sql
│   │   ├── 0003_functions_triggers.sql
│   │   └── 0004_seed_data.sql        # Only for DEV/test environment
│   └── seed/
│       └── dev_seed.sql
│
├── docs/
│   ├── 00_PROJECT_OVERVIEW.md        # This file set
│   ├── 01_ARCHITECTURE.md
│   ├── 02_CODE_STANDARDS.md
│   ├── 03_AI_RULES.md
│   ├── 04_SECURITY.md
│   ├── 05_LEGAL_COMPLIANCE.md
│   ├── 06_FEATURES_SPEC.md
│   ├── 07_TESTING_STRATEGY.md
│   ├── 08_DEBUG_DEV_MODE.md
│   └── 09_MONETISATION.md
│
├── __tests__/
│   ├── unit/
│   ├── integration/
│   └── mocks/
│
├── assets/
│   ├── icons/                        # App icons, all sizes
│   ├── images/
│   └── fonts/
│
├── .env.example                      # Template — never commit actual .env
├── .env.development
├── .env.production
├── app.config.ts                     # Expo dynamic config
├── babel.config.js
├── tsconfig.json
├── jest.config.ts
├── package.json
└── README.md
```

---

## 6. Authentication & Session Flow

```
User opens app
    │
    ├─── Has valid session token?
    │         │
    │    YES ─┤──► Is device trusted?
    │         │         │
    │         │    YES ─┤──► Continue (no expiry)
    │         │    NO ──┤──► Session older than 4h?
    │         │              │
    │         │         YES ─┤──► Force re-login (school device scenario)
    │         │         NO ──┤──► Continue
    │         │
    │    NO ──┴──► Show Login Screen
    │
    ├─── Login (email/Google/Apple)
    │         │
    │         └──► Has 2FA enabled? (mandatory for admins, optional for members)
    │                   │
    │              YES ─┤──► Send TOTP/SMS → verify
    │              NO ──┤──► Proceed
    │
    ├─── First login on new device?
    │         │
    │    YES ──┤──► "New device detected: [device name]"
    │              ├─► "Trust this device?" (disables 4h timeout here)
    │              └─► Info: "On trusted devices you stay logged in. On shared devices, you'll be logged out after inactivity."
    │
    └─── Proceed to app
```

---

## 7. Message Lifecycle (Moderation Flow)

```
User taps Send
    │
    ├─► Client-side: basic length/empty check (instant feedback)
    │
    ├─► POST to Edge Function: moderate-message
    │       │
    │       ├─► Run local profanity filter (word list, Polish + English)
    │       │
    │       ├─► Run hate/spam pattern check
    │       │
    │       └─► Decision:
    │             │
    │       PASS ─┤──► Set moderation_status = 'approved'
    │             │    Save to DB
    │             │    Broadcast via Realtime
    │             │
    │       REVIEW─┤──► Set moderation_status = 'queued_review'
    │             │    Save to DB (NOT broadcast to channel)
    │             │    Insert into moderation_queue
    │             │    Notify class admins
    │             │    Sender sees: "Twoja wiadomość jest weryfikowana"
    │             │
    │       FAIL ──┤──► Do NOT save to DB
    │                   Return error to client
    │                   Sender sees: "Wiadomość narusza zasady społeczności"
    │
Admin reviews queued message:
    ├─► APPROVE  → moderation_status = 'approved', broadcast
    ├─► REJECT   → moderation_status = 'rejected', sender notified
    └─► TRIM     → admin removes fragment, moderation_status = 'trimmed'
                   original_content preserved internally
                   trimmed version broadcast
                   sender notified: "Fragment Twojej wiadomości został usunięty"
```

---

## 8. Config Module Structure

`src/config/features.config.ts` — Feature flags:
```typescript
export const FEATURES = {
  // Dev/debug
  DEBUG_PANEL: __DEV__ && process.env.EXPO_PUBLIC_DEBUG_MODE === 'true',
  MOCK_MODERATION: __DEV__ && process.env.EXPO_PUBLIC_MOCK_MODERATION === 'true',
  MOCK_PUSH: __DEV__ && process.env.EXPO_PUBLIC_MOCK_PUSH === 'true',

  // Gradual rollout flags
  NOTES_MODULE: true,
  VOICE_MESSAGES: true,
  DM_MESSAGES: true,
  BACKUP_GDRIVE: false,    // Phase 2
  BACKUP_ICLOUD: false,    // Phase 2
  PREMIUM_SUBSCRIPTIONS: false,  // Phase 3

  // Safety
  SCREENSHOT_PREVENTION: true,   // Best-effort (Android FLAG_SECURE, iOS detection)
} as const;
```

`src/config/limits.config.ts`:
```typescript
export const LIMITS = {
  MESSAGE_MAX_LENGTH: 2000,      // characters
  VOICE_MAX_DURATION_FREE: 60,   // seconds
  VOICE_MAX_DURATION_PREMIUM: 300,
  ATTACHMENT_MAX_SIZE_FREE: 5 * 1024 * 1024,     // 5 MB
  ATTACHMENT_MAX_SIZE_PREMIUM: 20 * 1024 * 1024, // 20 MB
  CLASS_STORAGE_FREE: 200 * 1024 * 1024,         // 200 MB
  CLASS_STORAGE_PREMIUM: 2 * 1024 * 1024 * 1024, // 2 GB
  OCR_IMAGE_MAX_SIZE: 3 * 1024 * 1024,           // 3 MB (OCR.space free tier limit)
  MAX_CLASSES_FREE: 5,
  MAX_CHANNELS_PER_CLASS_FREE: 10,
  SESSION_TIMEOUT_UNTRUSTED: 4 * 60 * 60 * 1000, // 4 hours in ms
} as const;
```

`src/config/locales.config.ts`:
```typescript
export const LOCALES = {
  DEFAULT: 'pl',
  AVAILABLE: ['pl', 'en'] as const,
  FALLBACK: 'pl',
} as const;
```
