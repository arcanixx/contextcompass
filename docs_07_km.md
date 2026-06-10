# 07_TESTING_AND_DEBUG.md
# Path: docs/07_TESTING_AND_DEBUG.md
# Purpose: Testing strategy, DEV-only debug panel, mock system specification
# Depends on: 01_ARCHITECTURE.md, 02_CODE_STANDARDS.md

---

# KlassMate — Testing Strategy & Debug Mode

---

## 1. Testing Philosophy

> "Test behaviour, not implementation."

We test:
1. **What users experience** — does the UI respond correctly to actions?
2. **What data enters the database** — do Supabase query functions produce correct SQL?
3. **What moderation decides** — does the profanity filter catch the right things?
4. **What fails gracefully** — error states, network loss, empty states

We do NOT test:
- React Native internals
- Supabase internals
- Third-party library behaviour

---

## 2. Test Layers

### Layer 1: Unit Tests (Jest)
**Target:** Pure functions, utilities, stores, moderation logic

Location: `__tests__/unit/`

```
__tests__/unit/
├── utils/
│   ├── date.test.ts
│   ├── validation.test.ts
│   └── format.test.ts
├── lib/
│   ├── moderation/
│   │   └── wordlist.test.ts
│   ├── storage/
│   │   └── compress.test.ts
│   └── ocr/
│       └── tesseract.test.ts
└── store/
    ├── messageStore.test.ts
    └── authStore.test.ts
```

**Coverage target:** 80% for `src/utils/`, `src/lib/`, `src/store/`

### Layer 2: Integration Tests (Jest + Supabase mock)
**Target:** Supabase query functions — do they call the right tables with the right filters?

Location: `__tests__/integration/`

```
__tests__/integration/
├── queries/
│   ├── messages.test.ts       (send, fetch, pagination)
│   ├── classes.test.ts        (create, join, archive)
│   ├── members.test.ts        (approve, reject, ban)
│   └── moderation.test.ts     (queue, approve, trim, reject)
└── auth/
    ├── session.test.ts
    └── twoFactor.test.ts
```

**Supabase mock** (`__tests__/mocks/supabase.mock.ts`):
```typescript
// Mock the Supabase client — no real network calls in tests
jest.mock('@/lib/supabase/client', () => ({
  supabase: {
    from: jest.fn().mockReturnValue({
      select: jest.fn().mockReturnThis(),
      insert: jest.fn().mockReturnThis(),
      update: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn(),
    }),
    auth: {
      getSession: jest.fn(),
      signInWithPassword: jest.fn(),
      signOut: jest.fn(),
    },
    channel: jest.fn().mockReturnValue({
      on: jest.fn().mockReturnThis(),
      subscribe: jest.fn(),
    }),
  },
}));
```

### Layer 3: Component Tests (React Native Testing Library)
**Target:** Key screens and interactive components

Location: `__tests__/components/`

```
__tests__/components/
├── MessageBubble.test.tsx
├── MessageInput.test.tsx
├── ModerationQueueItem.test.tsx
├── VoiceRecorder.test.tsx
└── OcrUploader.test.tsx
```

Example:
```typescript
// __tests__/components/MessageInput.test.tsx
import { render, fireEvent, waitFor } from '@testing-library/react-native';
import MessageInput from '@/components/message/MessageInput';

describe('MessageInput', () => {
  it('disables Send button when input is empty', () => {
    const { getByTestId } = render(<MessageInput onSend={jest.fn()} />);
    expect(getByTestId('send-button')).toBeDisabled();
  });

  it('enables Send button when text is entered', () => {
    const { getByTestId } = render(<MessageInput onSend={jest.fn()} />);
    fireEvent.changeText(getByTestId('message-input'), 'Hello');
    expect(getByTestId('send-button')).not.toBeDisabled();
  });

  it('shows character counter at 1500 characters', () => {
    const longText = 'a'.repeat(1500);
    const { getByText, getByTestId } = render(<MessageInput onSend={jest.fn()} />);
    fireEvent.changeText(getByTestId('message-input'), longText);
    expect(getByText('1500/2000')).toBeTruthy();
  });

  it('calls onSend with trimmed content on button press', async () => {
    const mockSend = jest.fn();
    const { getByTestId } = render(<MessageInput onSend={mockSend} />);
    fireEvent.changeText(getByTestId('message-input'), '  Hello world  ');
    fireEvent.press(getByTestId('send-button'));
    await waitFor(() => expect(mockSend).toHaveBeenCalledWith('Hello world'));
  });
});
```

### Layer 4: Edge Function Tests (Deno Test)
**Target:** Moderation logic in Edge Functions

Location: `supabase/functions/__tests__/`

```typescript
// supabase/functions/__tests__/moderate-message.test.ts
import { assertEquals } from "jsr:@std/assert";
import { moderateContent } from "../moderate-message/index.ts";

Deno.test("rejects profanity in Polish", async () => {
  const result = await moderateContent("To jest k**** zadanie");
  assertEquals(result.decision, "reject");
});

Deno.test("approves clean homework message", async () => {
  const result = await moderateContent("Matematyka strona 45, zadanie 3-5");
  assertEquals(result.decision, "approve");
});

Deno.test("queues ambiguous content for review", async () => {
  const result = await moderateContent("To głupie zadanie mnie wkurza");
  assertEquals(result.decision, "review"); // "głupie" and "wkurza" are borderline
});
```

---

## 3. Test Runner Configuration

```typescript
// jest.config.ts
export default {
  preset: 'jest-expo',
  testEnvironment: 'node',
  setupFilesAfterFramework: ['<rootDir>/__tests__/setup.ts'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  collectCoverageFrom: [
    'src/utils/**/*.ts',
    'src/lib/**/*.ts',
    'src/store/**/*.ts',
    '!src/**/*.d.ts',
  ],
  coverageThreshold: {
    global: { lines: 80, functions: 80 },
  },
};
```

---

## 4. Debug & Dev Mode

### 4.1 The DEBUG_MODE Flag

Debug mode is controlled by **two conditions that must both be true**:
1. `__DEV__` — Expo/React Native development build (not production)
2. `EXPO_PUBLIC_DEBUG_MODE=true` in `.env.development`

```typescript
// src/config/features.config.ts
export const FEATURES = {
  DEBUG_PANEL: __DEV__ && process.env.EXPO_PUBLIC_DEBUG_MODE === 'true',
  MOCK_MODERATION: __DEV__ && process.env.EXPO_PUBLIC_MOCK_MODERATION === 'true',
  MOCK_PUSH: __DEV__ && process.env.EXPO_PUBLIC_MOCK_PUSH === 'true',
  MOCK_OCR: __DEV__ && process.env.EXPO_PUBLIC_MOCK_OCR === 'true',
  SEED_DATA_VISIBLE: __DEV__ && process.env.EXPO_PUBLIC_SHOW_SEED === 'true',
} as const;
```

### 4.2 Debug Panel Location

Route: `src/app/debug/` — only accessible when `FEATURES.DEBUG_PANEL === true`.

The debug tab appears in the bottom tab bar only in DEBUG_MODE:
```typescript
// src/app/(main)/_layout.tsx
{FEATURES.DEBUG_PANEL && (
  <Tabs.Screen
    name="debug"
    options={{ title: '🐛 Debug', tabBarIcon: () => <BugIcon /> }}
  />
)}
```

### 4.3 Debug Panel Screens

#### `debug/index.tsx` — Dashboard
```
┌──────────────────────────────────────────────┐
│  🐛 KlassMate Debug Panel                   │
│  Build: 0.1.0 | Env: development             │
│  Supabase: eu-central-1 (Frankfurt)          │
│  User: jan@test.pl (id: abc-123)             │
│                                              │
│  ── Mock Controls ──                         │
│  [Mock: Moderation]  ● ON                   │
│  [Mock: Push Notifs] ○ OFF                  │
│  [Mock: OCR]         ○ OFF                  │
│                                              │
│  ── Scenarios ──                             │
│  [Simulate: Message Rejected]               │
│  [Simulate: Message In Review]              │
│  [Simulate: Admin Moderation Queue (5)]     │
│  [Simulate: Session Expiry]                 │
│  [Simulate: Network Offline]                │
│  [Simulate: Push Notification]              │
│  [Simulate: Biometric Prompt]               │
│  [Simulate: OCR Success]                    │
│  [Simulate: OCR Failure]                    │
│  [Simulate: File Upload Progress]           │
│  [Simulate: Parental Consent Pending]       │
│                                             │
│  ── Data ──                                 │
│  [Load Seed Class Data]                     │
│  [Clear All Local State]                    │
│  [Reset Seen Tooltips]                      │
│  [Reset Onboarding]                         │
│                                             │
│  ── Logs ──                                 │
│  [View Error Log (last 50)]                 │
│  [Copy Log to Clipboard]                    │
└──────────────────────────────────────────────┘
```

#### `debug/mock-messages.tsx` — Message Scenarios

Allows sending messages directly to the mock moderation pipeline:
- Text input for custom content
- Buttons: "Send Clean", "Send Profanity", "Send Borderline", "Send as Admin"
- Shows the moderation decision + reason in real-time below

#### `debug/mock-moderation.tsx` — Moderation Queue Simulator

Injects fake flagged messages into the moderation queue:
- "Add 1 item to queue" / "Add 5 items" / "Clear queue"
- Allows testing the admin trim flow without needing real flagged content

#### `debug/mock-notifications.tsx` — Notification Simulator

Triggers local push notifications of each type:
- "New message in #matematyka"
- "@mention from Ania"
- "New member request"
- "Your message was moderated"

### 4.4 Mock Services

When `FEATURES.MOCK_MODERATION` is true, the client skips calling the Edge Function and returns a mocked response:

```typescript
// src/lib/moderation/client.ts
import { FEATURES } from '@/config/features.config';
import type { ModerationResult } from '@/types/moderation.types';

export const moderateMessage = async (content: string): Promise<ModerationResult> => {
  if (FEATURES.MOCK_MODERATION) {
    return getMockModerationResult(content); // local mock, no network
  }
  // Real call to Edge Function
  return callModerationEdgeFunction(content);
};

const getMockModerationResult = (content: string): ModerationResult => {
  // Simple keyword simulation for dev
  if (content.includes('[REJECT]')) return { decision: 'reject', reason: 'mock_profanity' };
  if (content.includes('[REVIEW]')) return { decision: 'review', reason: 'mock_review', confidence: 0.75 };
  return { decision: 'approve' };
};
```

Similarly for OCR (`FEATURES.MOCK_OCR`):
```typescript
// Returns: "To jest przykładowy tekst rozpoznany przez OCR.\nStrona 45, zadanie 3."
```

### 4.5 Seed Data

`supabase/seed/dev_seed.sql` creates:
- 1 test class "Klasa 3B — Testowa"
- 3 test users (admin + 2 members) with known credentials
- 5 channels (Matematyka, Polski, Historia, Angielski, Ogłoszenia)
- 20 sample messages per channel
- 3 items in moderation queue (1 approve, 1 reject, 1 trim scenario)
- 2 personal notes

Seed data is ONLY loaded into the development Supabase project, never production. Guarded by:
```sql
-- supabase/seed/dev_seed.sql
DO $$
BEGIN
  IF current_database() NOT LIKE '%dev%' AND current_database() NOT LIKE '%test%' THEN
    RAISE EXCEPTION 'Seed data cannot be loaded into non-dev database: %', current_database();
  END IF;
END $$;
```

---

## 5. Error Logging (Production)

### Sentry integration
```typescript
// src/lib/errors/logger.ts
import * as Sentry from '@sentry/react-native';
import { FEATURES } from '@/config/features.config';

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export const logger = {
  debug: (message: string, context?: Record<string, unknown>) => {
    if (__DEV__) console.debug(`[DEBUG] ${message}`, context);
    // NOT sent to Sentry
  },

  info: (message: string, context?: Record<string, unknown>) => {
    if (__DEV__) console.info(`[INFO] ${message}`, context);
    Sentry.addBreadcrumb({ message, data: context, level: 'info' });
  },

  warn: (message: string, context?: Record<string, unknown>) => {
    if (__DEV__) console.warn(`[WARN] ${message}`, context);
    Sentry.captureMessage(message, { level: 'warning', extra: context });
  },

  error: (message: string, context?: Record<string, unknown>) => {
    if (__DEV__) console.error(`[ERROR] ${message}`, context);
    Sentry.captureException(new Error(message), { extra: context });
  },
};
```

### What IS sent to Sentry
- Unhandled errors and crashes
- Failed Supabase operations (error code only, no user content)
- Failed moderation calls (no message content)
- Failed push notification delivery

### What is NEVER sent to Sentry
- Message content
- User names or emails
- Any personally identifiable information
- Moderation queue content
- OCR image data

### Sentry configuration (GDPR-safe)
```typescript
Sentry.init({
  dsn: process.env.EXPO_PUBLIC_SENTRY_DSN,
  environment: __DEV__ ? 'development' : 'production',
  // Strip PII automatically
  beforeSend: (event) => {
    // Remove any user data from error context
    delete event.user?.email;
    delete event.user?.username;
    return event;
  },
});
```

---

## 6. CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/ci.yml
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
      - run: npm run typecheck        # tsc --noEmit
      - run: npm run lint             # eslint
      - run: npm run test:unit        # jest --coverage
      - run: npm run test:components  # jest --testPathPattern=components

  edge-functions:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: denoland/setup-deno@v1
      - run: deno test supabase/functions/__tests__/
```
