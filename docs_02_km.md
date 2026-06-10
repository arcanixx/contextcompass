# 02_CODE_STANDARDS.md
# Path: docs/02_CODE_STANDARDS.md
# Purpose: Coding conventions, naming, file headers, formatting rules
# Depends on: 00_PROJECT_OVERVIEW.md

---

# KlassMate — Code Standards

---

## 1. Language & Tooling

| Tool | Version | Config file |
|------|---------|------------|
| TypeScript | `^5.3` | `tsconfig.json` |
| ESLint | `^8.x` | `.eslintrc.js` |
| Prettier | `^3.x` | `.prettierrc` |
| Husky | pre-commit hook | `.husky/pre-commit` |
| lint-staged | runs on staged files | `lint-staged.config.js` |

**`tsconfig.json` key settings:**
```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "exactOptionalPropertyTypes": true,
    "noUncheckedIndexedAccess": true
  }
}
```

---

## 2. File Header (MANDATORY)

Every source file (`.ts`, `.tsx`) must start with this header block:

```typescript
/**
 * @file ComponentName.tsx
 * @path src/components/message/MessageBubble.tsx
 *
 * @description
 * Renders a single chat message bubble. Handles text, voice, and attachment types.
 * Applies different styling for own vs. other messages.
 *
 * @exports
 * - MessageBubble (default export, React component)
 * - MessageBubbleProps (type)
 *
 * @dependsOn
 * - src/types/message.types.ts
 * - src/constants/colors.ts
 * - src/components/ui/Avatar.tsx
 * - src/components/message/VoiceMessagePlayer.tsx
 * - src/components/message/AttachmentPreview.tsx
 * - src/i18n/index.ts
 */
```

If a file has no exports (e.g. a config with only side effects), write `@exports - none`.
If a file imports nothing, write `@dependsOn - none`.

---

## 3. Naming Conventions

| Entity | Convention | Example |
|--------|-----------|---------|
| React components | `PascalCase` | `MessageBubble` |
| Component files | `PascalCase.tsx` | `MessageBubble.tsx` |
| Hooks | `camelCase` with `use` prefix | `useMessages` |
| Hook files | `camelCase.ts` | `useMessages.ts` |
| Utility functions | `camelCase` | `formatDate` |
| Constants (value) | `SCREAMING_SNAKE_CASE` | `MAX_FILE_SIZE` |
| Constants (config objects) | `SCREAMING_SNAKE_CASE` | `FEATURES`, `LIMITS` |
| TypeScript types | `PascalCase` with suffix | `MessageType`, `ClassMember` |
| TypeScript interfaces | `PascalCase` | `MessageBubbleProps` |
| Zustand stores | `camelCase` + `Store` | `messageStore` |
| Database columns | `snake_case` | `created_at` |
| i18n keys | `dot.notation.lower` | `message.send.label` |
| Route params | `camelCase` | `[classId]` |

### Do NOT:
- Use `I` prefix for interfaces (`IMessage` → `Message`)
- Use `type` suffix for basic TS types (`MessageType` is OK for discriminated unions, but `UserType` → just `User`)
- Use `Component` suffix (`ButtonComponent` → `Button`)

---

## 4. File Length Limit

**Maximum 200 lines per file.** This is a hard limit enforced by ESLint rule.

If a file is approaching 200 lines:
1. Extract sub-components into `ComponentName.Sub.tsx`
2. Extract hooks into `useLogic.ts` 
3. Extract helpers into `utils/domain.ts`
4. Split a large screen into `ScreenName/index.tsx` + `ScreenName/ScreenName.logic.ts`

---

## 5. TypeScript Rules

```typescript
// ✅ GOOD — typed props
interface MessageBubbleProps {
  message: Message;
  isOwn: boolean;
  onLongPress?: (messageId: string) => void;
}

// ❌ BAD — never use 'any'
const handler = (data: any) => { ... }

// ✅ GOOD — use 'unknown' then narrow
const handler = (data: unknown) => {
  if (!isMessage(data)) throw new AppError('INVALID_DATA');
  // now data is Message
}

// ❌ BAD — optional chaining without fallback in render
<Text>{user?.name}</Text>

// ✅ GOOD — explicit fallback
<Text>{user?.name ?? t('common.unknown_user')}</Text>

// ❌ BAD — non-null assertion without comment
const channel = channels.find(c => c.id === id)!

// ✅ GOOD — assert with guard
const channel = channels.find(c => c.id === id);
if (!channel) throw new AppError('CHANNEL_NOT_FOUND', { id });
```

---

## 6. Error Handling

All async operations must be wrapped in `try/catch`. Errors must be logged.

```typescript
// Pattern for hooks
const sendMessage = async (content: string): Promise<Result<Message, AppError>> => {
  try {
    const result = await moderateAndSend(content);
    return { ok: true, value: result };
  } catch (error) {
    const appError = toAppError(error);
    logger.error('sendMessage failed', { error: appError, context: { channelId } });
    return { ok: false, error: appError };
  }
};

// Pattern for Edge Functions
Deno.serve(async (req) => {
  try {
    // ... logic
    return new Response(JSON.stringify(result), { status: 200 });
  } catch (error) {
    console.error('[moderate-message] Unhandled error:', error);
    return new Response(JSON.stringify({ error: 'INTERNAL_ERROR' }), { status: 500 });
  }
});
```

**AppError structure** (`src/lib/errors/types.ts`):
```typescript
export class AppError extends Error {
  constructor(
    public readonly code: ErrorCode,
    public readonly context?: Record<string, unknown>,
    public readonly originalError?: unknown,
  ) {
    super(code);
    this.name = 'AppError';
  }
}

export type ErrorCode =
  | 'CHANNEL_NOT_FOUND'
  | 'MESSAGE_REJECTED_MODERATION'
  | 'AUTH_SESSION_EXPIRED'
  | 'UPLOAD_TOO_LARGE'
  | 'OCR_FAILED'
  | 'INVALID_DATA'
  // ... extend as needed
  ;
```

---

## 7. i18n — No Hardcoded Strings

**No string literals in component render.** Every user-visible string goes through `t()`.

```typescript
// ❌ BAD
<Text>Wyślij wiadomość</Text>
<Toast message="Wiadomość wysłana" />
Alert.alert("Błąd", "Nie można wysłać wiadomości");

// ✅ GOOD
const { t } = useTranslation();
<Text>{t('message.input.placeholder')}</Text>
<Toast message={t('message.send.success')} />
Alert.alert(t('common.error'), t('message.send.failed'));
```

**Translation file structure** (`src/i18n/pl.json`):
```json
{
  "common": {
    "error": "Błąd",
    "cancel": "Anuluj",
    "confirm": "Potwierdź",
    "unknown_user": "Nieznany użytkownik",
    "loading": "Ładowanie..."
  },
  "auth": {
    "login": {
      "title": "Zaloguj się",
      "email_label": "Email",
      "password_label": "Hasło"
    }
  },
  "message": {
    "input": { "placeholder": "Napisz wiadomość..." },
    "send": {
      "label": "Wyślij",
      "success": "Wiadomość wysłana",
      "failed": "Nie można wysłać wiadomości"
    },
    "moderation": {
      "pending": "Twoja wiadomość jest weryfikowana przez moderatora",
      "rejected": "Wiadomość narusza zasady społeczności",
      "trimmed": "Fragment Twojej wiadomości został usunięty przez moderatora"
    }
  }
}
```

---

## 8. Icons — No Hardcoded Names

```typescript
// src/constants/icons.ts
export const ICONS = {
  send: 'paper-plane',
  attach: 'paperclip',
  voice: 'microphone',
  settings: 'cog',
  moderation: 'shield-check',
  block: 'ban',
  archive: 'archive-box',
  unread: 'circle-small',
} as const;

// In component:
// ❌ BAD
<Icon name="paper-plane" />

// ✅ GOOD
import { ICONS } from '@/constants/icons';
<Icon name={ICONS.send} />
```

---

## 9. No Re-exports from `index.ts` (unless explicitly needed)

```typescript
// ❌ BAD — barrel file that re-exports everything
// components/index.ts
export { Button } from './ui/Button';
export { Input } from './ui/Input';
export { MessageBubble } from './message/MessageBubble';
// ... 40 more exports

// ✅ GOOD — import directly
import { Button } from '@/components/ui/Button';
import { MessageBubble } from '@/components/message/MessageBubble';
```

Only create `index.ts` barrel files for:
- `src/config/index.ts` — config module re-exports (intentional)
- `src/types/index.ts` — type-only re-exports (zero runtime cost)
- Public API surface of a self-contained module (e.g. `src/lib/moderation/index.ts`)

---

## 10. State Management (Zustand)

Each store handles one domain. No cross-store imports directly — use selectors.

```typescript
// src/store/messageStore.ts
import { create } from 'zustand';
import type { Message } from '@/types/message.types';

interface MessageState {
  messages: Record<string, Message[]>;  // keyed by channelId
  isLoading: boolean;
  error: string | null;
}

interface MessageActions {
  addMessage: (channelId: string, message: Message) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
}

export const useMessageStore = create<MessageState & MessageActions>((set) => ({
  messages: {},
  isLoading: false,
  error: null,
  addMessage: (channelId, message) =>
    set((state) => ({
      messages: {
        ...state.messages,
        [channelId]: [...(state.messages[channelId] ?? []), message],
      },
    })),
  setLoading: (loading) => set({ isLoading: loading }),
  setError: (error) => set({ error }),
}));
```

---

## 11. Component Structure Template

```typescript
/**
 * @file ComponentName.tsx
 * @path src/components/[domain]/ComponentName.tsx
 * @description [What it renders and when]
 * @exports ComponentName (default), ComponentNameProps
 * @dependsOn [list imports]
 */

import React, { memo } from 'react';
import { View, StyleSheet } from 'react-native';
import { useTranslation } from 'react-i18next';

// ─── Types ───────────────────────────────────────────────────────────────────

export interface ComponentNameProps {
  // all props explicitly typed, no 'any'
}

// ─── Component ───────────────────────────────────────────────────────────────

const ComponentName = memo(({ ...props }: ComponentNameProps) => {
  const { t } = useTranslation();

  // hooks at top
  // derived state next
  // handlers next (useCallback for expensive ones)
  // render last

  return (
    <View style={styles.container}>
      {/* JSX */}
    </View>
  );
});

ComponentName.displayName = 'ComponentName';

export default ComponentName;

// ─── Styles ──────────────────────────────────────────────────────────────────
// Use theme tokens, never raw hex or pixel values
const styles = StyleSheet.create({
  container: {
    // ...
  },
});
```

---

## 12. Commit Message Convention (Conventional Commits)

```
feat(messages): add voice message recording
fix(moderation): handle empty content edge case
docs(architecture): update database schema
test(auth): add 2FA verification unit tests
chore(deps): upgrade expo to 52.1.0
refactor(store): split messageStore into separate files
```

Format: `type(scope): description`

Types: `feat`, `fix`, `docs`, `test`, `chore`, `refactor`, `style`, `perf`
