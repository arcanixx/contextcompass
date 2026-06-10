# 13 — API Contract (Edge Functions + Zod Schemas)
# Path: docs/13_api_contract.md
# Purpose: Kompletne schematy wejścia/wyjścia dla wszystkich Edge Functions (Zod) + REST conventions
# Depends on: docs/01_ARCHITECTURE.md, docs/01b_ARCHITECTURE_SUPPLEMENT.md, docs/11_user_stories_and_ac.md
# Status: MVP v0.1 (Phase 1)

---

# KlassMate — API Contract & Edge Functions Specification

> **Wersja:** 0.1.0-draft  
> **Ostatnia aktualizacja:** 2025-06-11  
> **Scope:** Wszystkie Edge Functions (Supabase Deno/TS) + współdzielone schematy Zod  
> **Konwencja:** Każdy endpoint to `POST /functions/v1/{function-name}`

---

## 1. Konwencje globalne

### 1.1 Request / Response envelope

Każdy endpoint przyjmuje i zwraca JSON zgodnie z poniższym wzorcem:

```typescript
// Request (body)
{
  "payload": { ... },        // dane wejściowe — schemat per function
  "requestId": "uuid"        // opcjonalnie, do trace'owania
}

// Response — success (HTTP 200)
{
  "success": true,
  "data": { ... },             // dane wyjściowe — schemat per function
  "meta": {
    "requestId": "uuid",
    "processedAt": "2025-06-11T12:00:00Z",
    "durationMs": 45
  }
}

// Response — error (HTTP 4xx / 5xx)
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",   // jeden z ErrorCode
    "message": "Field 'content' is required", // human-readable (EN dla dev, PL dla user w UI)
    "field": "content",           // opcjonalnie, które pole
    "details": [ ... ]            // opcjonalnie, array błędów Zod
  },
  "meta": { "requestId": "uuid" }
}
```

### 1.2 Error codes

| Kod | HTTP | Znaczenie | Kiedy używać |
|-----|------|-----------|--------------|
| `UNAUTHORIZED` | 401 | Brak lub nieważny JWT | Missing / expired token |
| `FORBIDDEN` | 403 | JWT ważny, ale brak uprawnień | Nie-admin próbuje moderować |
| `VALIDATION_ERROR` | 400 | Błąd walidacji Zod | Niepoprawne pole, za długi tekst |
| `NOT_FOUND` | 404 | Zasób nie istnieje | Niepoprawne classId, messageId |
| `RATE_LIMITED` | 429 | Przekroczony limit | >10 req/min na user dla AI proxy |
| `MODERATION_REJECTED` | 422 | Treść odrzucona przez moderację | Profanity, spam |
| `INTERNAL_ERROR` | 500 | Błąd serwera | Crash, timeout, DB error |
| `SERVICE_UNAVAILABLE` | 503 | Usługa zewnętrzna niedostępna | OCR.space down, Expo Push down |

### 1.3 Auth

Wszystkie endpointy (poza `health-check`) wymagają nagłówka:
```
Authorization: Bearer <supabase_jwt>
```

Edge Function weryfikuje JWT przez `createClient` z `anonKey` (nie service role dla auth — service role używana tylko do zapisu do DB po weryfikacji).

### 1.4 Rate limiting (per user, per minute)

| Funkcja | Limit | Uzasadnienie |
|---------|-------|--------------|
| `moderate-message` | 30 | Moderacja jest szybka, ale nie powinna być spamowana |
| `send-push-notification` | 20 | Push są drogie w perception, nie w cenie |
| `export-backup` | 1 | Ciężka operacja, generuje ZIP |
| `delete-user-data` | 1 | Destrukcyjna, wymaga re-auth |
| `report-error` | 10 | Error reporting nie powinien być głośny |
| `ocr-process` | 10 | OCR jest ciężki (Tesseract WASM) |
| `compress-attachment` | 10 | Kompresja obrazków |
| `archive-class` | 5 | Admin operacja |
| `cleanup-expired-sessions` | N/A | CRON, nie user-facing |
| `process-reminders` | N/A | CRON, nie user-facing |

Przekroczenie limitu → `429 RATE_LIMITED`.

---

## 2. Współdzielone schematy Zod

Plik: `packages/shared/schemas.ts` (lub `src/types/api.schemas.ts` w monorepo)

```typescript
import { z } from 'zod';

// ─── Primitives ──────────────────────────────────────────────────────────────

export const UuidSchema = z.string().uuid();

export const TimestampSchema = z.string().datetime({ offset: true });

export const ModerationStatusSchema = z.enum([
  'pending',
  'approved',
  'queued_review',
  'rejected',
  'trimmed',
]);

export const NotificationTypeSchema = z.enum([
  'new_message',
  'mention',
  'thread_reply',
  'dm_new',
  'join_request',
  'join_approved',
  'join_rejected',
  'moderation_queued',
  'message_approved',
  'message_rejected',
  'message_trimmed',
  'reminder',
  'session_expiring',
]);

export const DeviceTypeSchema = z.enum(['ios', 'android', 'web']);

export const RoleSchema = z.enum(['student', 'teacher', 'superadmin']);

export const ClassMemberStatusSchema = z.enum([
  'pending',
  'approved',
  'rejected',
  'banned',
]);

export const ClassMemberRoleSchema = z.enum(['member', 'admin']);

// ─── Reusable objects ──────────────────────────────────────────────────────

export const ProfileRefSchema = z.object({
  id: UuidSchema,
  display_name: z.string().min(2).max(50),
  avatar_url: z.string().url().nullable(),
  role: RoleSchema,
});

export const ClassRefSchema = z.object({
  id: UuidSchema,
  name: z.string().min(2).max(100),
  school_name: z.string().max(100).nullable(),
  school_year: z.string().max(20),
  join_code: z.string().length(6),
});

export const ChannelRefSchema = z.object({
  id: UuidSchema,
  class_id: UuidSchema,
  name: z.string().min(1).max(80),
  subject_emoji: z.string().max(10).nullable(),
  position: z.number().int().min(0),
});

export const MessageRefSchema = z.object({
  id: UuidSchema,
  channel_id: UuidSchema,
  sender_id: UuidSchema,
  content: z.string().max(2000).nullable(),
  moderation_status: ModerationStatusSchema,
  created_at: TimestampSchema,
});

export const AttachmentRefSchema = z.object({
  id: UuidSchema,
  message_id: UuidSchema,
  storage_path: z.string().min(1),
  file_type: z.enum(['image', 'pdf', 'voice']),
  mime_type: z.string(),
  size_bytes: z.number().int().min(1),
  width: z.number().int().nullable(),
  height: z.number().int().nullable(),
});
```

---

## 3. Edge Functions — szczegółowa specyfikacja

---

### 3.1 `moderate-message`

**Cel:** Pre-insert content moderation. Wywoływany przez klienta PRZED `INSERT` do `messages`.

**Trigger:** HTTP POST (klient)  
**Auth:** Wymagany (user JWT)  
**Rate limit:** 30/min

#### Zod Schema — Input

```typescript
export const ModerateMessageInputSchema = z.object({
  content: z.string().min(1).max(2000),
  contentType: z.enum(['channel_message', 'dm_message', 'thread_reply']),
  classId: UuidSchema,
  channelId: UuidSchema.optional(),      // wymagane dla channel_message
  dmConversationId: UuidSchema.optional(), // wymagane dla dm_message
  threadId: UuidSchema.optional(),         // wymagane dla thread_reply
  senderId: UuidSchema,
  attachments: z.array(z.object({
    mimeType: z.string(),
    sizeBytes: z.number().int(),
    fileName: z.string(),
  })).max(5).optional(),
});

// Refinement: XOR channel vs DM
export type ModerateMessageInput = z.infer<typeof ModerateMessageInputSchema>;
```

**Walidacja dodatkowa (poza Zod):**
- `senderId` musi być `approved` memberem `classId`.
- Jeśli `contentType === 'dm_message'` — obie strony DM muszą być `approved` w klasie i niezablokowane.

#### Zod Schema — Output

```typescript
export const ModerationDecisionSchema = z.enum(['approve', 'review', 'reject']);

export const ModerateMessageOutputSchema = z.object({
  decision: ModerationDecisionSchema,
  reason: z.enum([
    'clean',
    'profanity_pl',
    'profanity_en',
    'hate_speech',
    'spam',
    'personal_data',
    'reported',
    'image_flagged',
    'manual_review_required',
  ]),
  confidence: z.number().min(0).max(1).optional(), // tylko dla AI / heuristic
  flaggedWords: z.array(z.string()).optional(),
  moderationQueueId: UuidSchema.optional(), // tylko gdy decision = 'review'
  suggestedAction: z.enum(['allow', 'block', 'review']).optional(),
});

export type ModerateMessageOutput = z.infer<typeof ModerateMessageOutputSchema>;
```

#### Przykład — Request

```http
POST /functions/v1/moderate-message
Authorization: Bearer eyJhbG...
Content-Type: application/json

{
  "payload": {
    "content": "Matematyka strona 45, zadanie 3-5. Ktoś wie jak to zrobić?",
    "contentType": "channel_message",
    "classId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "channelId": "b2c3d4e5-f6a7-8901-bcde-f23456789012",
    "senderId": "c3d4e5f6-a7b8-9012-cdef-345678901234"
  }
}
```

#### Przykład — Response (approve)

```json
{
  "success": true,
  "data": {
    "decision": "approve",
    "reason": "clean",
    "confidence": 0.02
  },
  "meta": {
    "requestId": "req-123e4567-e89b-12d3-a456-426614174000",
    "processedAt": "2025-06-11T12:00:00Z",
    "durationMs": 12
  }
}
```

#### Przykład — Response (review)

```json
{
  "success": true,
  "data": {
    "decision": "review",
    "reason": "profanity_pl",
    "confidence": 0.87,
    "flaggedWords": ["k****"],
    "moderationQueueId": "d4e5f6a7-b8c9-0123-defa-456789012345"
  }
}
```

#### Przykład — Response (reject)

```json
{
  "success": true,
  "data": {
    "decision": "reject",
    "reason": "hate_speech",
    "confidence": 0.94,
    "flaggedWords": ["idioci", "debile"]
  }
}
```

#### Implementacja — sketch (Deno)

```typescript
// supabase/functions/moderate-message/index.ts
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { z } from 'npm:zod@3.23.8';

const InputSchema = z.object({ /* ... jak wyżej ... */ });

Deno.serve(async (req) => {
  try {
    const { payload } = await req.json();
    const input = InputSchema.parse(payload);

    // 1. Auth check
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );
    const { data: { user } } = await supabase.auth.getUser();
    if (!user || user.id !== input.senderId) throw new Error('UNAUTHORIZED');

    // 2. Membership check
    const { data: member } = await supabase
      .from('class_members')
      .select('status, role')
      .eq('class_id', input.classId)
      .eq('profile_id', input.senderId)
      .single();
    if (!member || member.status !== 'approved') throw new Error('FORBIDDEN');

    // 3. Run profanity filter (Polish + English word lists)
    const result = runProfanityCheck(input.content);

    // 4. Return decision
    return new Response(JSON.stringify({
      success: true,
      data: result,
      meta: { requestId: crypto.randomUUID(), processedAt: new Date().toISOString() }
    }), { status: 200 });

  } catch (error) {
    if (error instanceof z.ZodError) {
      return new Response(JSON.stringify({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'Invalid input', details: error.errors }
      }), { status: 400 });
    }
    // ... other error handling
  }
});
```

---

### 3.2 `compress-attachment`

**Cel:** Kompresja i konwersja załączników przed uploadem do Storage.

**Trigger:** HTTP POST (klient, opcjonalnie — klient może też kompresować lokalnie)  
**Auth:** Wymagany  
**Rate limit:** 10/min

#### Zod Schema — Input

```typescript
export const CompressAttachmentInputSchema = z.object({
  fileBase64: z.string().min(1), // base64 encoded file
  fileName: z.string().min(1).max(255),
  mimeType: z.enum(['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  targetMaxWidth: z.number().int().min(100).max(4096).default(1920),
  targetQuality: z.number().min(0.1).max(1).default(0.85), // dla JPEG/WebP
  maxSizeBytes: z.number().int().min(1).max(20 * 1024 * 1024).default(5 * 1024 * 1024),
});
```

#### Zod Schema — Output

```typescript
export const CompressAttachmentOutputSchema = z.object({
  compressedBase64: z.string().min(1),
  originalSize: z.number().int(),
  compressedSize: z.number().int(),
  width: z.number().int(),
  height: z.number().int(),
  mimeType: z.enum(['image/jpeg', 'image/webp', 'application/pdf']),
  wasCompressed: z.boolean(),
});
```

---

### 3.3 `send-push-notification`

**Cel:** Wysyłka powiadomień push przez Expo Push API.

**Trigger:** DB trigger (pg_net) przy INSERT do `notifications` OR HTTP POST (admin/debug)  
**Auth:** Service role (DB trigger) lub user JWT (debug)  
**Rate limit:** 20/min per user

#### Zod Schema — Input

```typescript
export const SendPushNotificationInputSchema = z.object({
  notificationId: UuidSchema, // ID z tabeli notifications
  // Alternatywnie — direct payload (tylko dla debug / admin):
  directPayload: z.object({
    recipientId: UuidSchema,
    title: z.string().min(1).max(100),
    body: z.string().min(1).max(255),
    data: z.record(z.string()).optional(),
    priority: z.enum(['normal', 'high']).default('normal'),
  }).optional(),
});
```

#### Zod Schema — Output

```typescript
export const SendPushNotificationOutputSchema = z.object({
  sent: z.number().int().min(0), // liczba urządzeń, do których wysłano
  skipped: z.enum(['user_preference', 'quiet_hours', 'no_devices', 'muted_channel']).optional(),
  expoReceiptIds: z.array(z.string()).optional(),
});
```

---

### 3.4 `export-backup`

**Cel:** Generowanie ZIP/JSON z danymi użytkownika (RODO right to access / user backup).

**Trigger:** HTTP POST (authenticated user)  
**Auth:** Wymagany (user JWT — tylko własne dane)  
**Rate limit:** 1/min

#### Zod Schema — Input

```typescript
export const ExportBackupInputSchema = z.object({
  format: z.enum(['json', 'zip']).default('json'),
  includeMessages: z.boolean().default(true),
  includeNotes: z.boolean().default(true),
  includeClasses: z.boolean().default(true),
  dateFrom: TimestampSchema.optional(), // filtr: tylko dane od tej daty
  dateTo: TimestampSchema.optional(),
});
```

#### Zod Schema — Output

```typescript
export const ExportBackupOutputSchema = z.object({
  downloadUrl: z.string().url(),
  expiresAt: TimestampSchema, // link ważny 1h
  sizeBytes: z.number().int(),
  fileCount: z.number().int(),
  format: z.enum(['json', 'zip']),
  generatedAt: TimestampSchema,
});
```

---

### 3.5 `delete-user-data`

**Cel:** RODO right to erasure — anonimizacja / usunięcie wszystkich danych użytkownika.

**Trigger:** HTTP POST (authenticated user, po re-auth biometrią/hasłem)  
**Auth:** Wymagany (user JWT)  
**Rate limit:** 1/min (destukcyjna operacja)

#### Zod Schema — Input

```typescript
export const DeleteUserDataInputSchema = z.object({
  confirmPhrase: z.literal('USUŃ MOJE KONTO'), // friction — użytkownik musi przepisać
  reason: z.enum([
    'no_longer_needed',
    'privacy_concerns',
    'switched_app',
    'other',
  ]).optional(),
  feedback: z.string().max(500).optional(),
});
```

#### Zod Schema — Output

```typescript
export const DeleteUserDataOutputSchema = z.object({
  deleted: z.boolean(),
  anonymisedAt: TimestampSchema,
  affectedTables: z.array(z.object({
    table: z.string(),
    rowsAffected: z.number().int(),
    action: z.enum(['deleted', 'anonymised', 'cascade_deleted']),
  })),
  sessionRevoked: z.boolean(),
});
```

---

### 3.6 `process-reminders`

**Cel:** CRON job — wysyłka przypomnień (reminders) których `remind_at <= now()`.

**Trigger:** Supabase Scheduled Function (CRON: `* * * * *`)  
**Auth:** Service role (internal)  
**Rate limit:** N/A (internal)

#### Zod Schema — Input

Brak (CRON nie przyjmuje payloadu). Opcjonalnie:

```typescript
export const ProcessRemindersInputSchema = z.object({
  batchSize: z.number().int().min(1).max(500).default(100),
  dryRun: z.boolean().default(false), // tylko log, nie wysyłaj
}).optional();
```

#### Zod Schema — Output

```typescript
export const ProcessRemindersOutputSchema = z.object({
  processed: z.number().int(),
  sent: z.number().int(),
  skipped: z.number().int(),
  errors: z.number().int(),
  nextBatchAt: TimestampSchema.optional(),
});
```

---

### 3.7 `report-error`

**Cel:** Zbieranie raportów błędów od klienta do tabeli `error_reports`.

**Trigger:** HTTP POST (klient, gdy `logger.error()` lub `logger.critical()`)  
**Auth:** Wymagany (user JWT, ale user ID haszowany SHA-256)  
**Rate limit:** 10/min

#### Zod Schema — Input

```typescript
export const ReportErrorInputSchema = z.object({
  errorCode: z.string().min(1).max(100),
  errorMessage: z.string().min(1).max(1000),
  stackTrace: z.string().optional(),
  context: z.record(z.unknown()).optional(), // BEZ PII — tylko kody, ID, flagi
  breadcrumbs: z.array(z.object({
    action: z.string(),
    timestamp: TimestampSchema,
    metadata: z.record(z.unknown()).optional(),
  })).max(20).optional(),
  appVersion: z.string(),
  platform: DeviceTypeSchema,
  osVersion: z.string().optional(),
  deviceModel: z.string().optional(),
});
```

#### Zod Schema — Output

```typescript
export const ReportErrorOutputSchema = z.object({
  reportId: UuidSchema,
  received: z.boolean(),
});
```

---

### 3.8 `ocr-process`

**Cel:** OCR — rozpoznawanie tekstu ze zdjęcia (Tesseract.js server-side + fallback OCR.space).

**Trigger:** HTTP POST (klient, gdy Notes → „Zdjęcie z zeszytu”)  
**Auth:** Wymagany  
**Rate limit:** 10/min

#### Zod Schema — Input

```typescript
export const OcrProcessInputSchema = z.object({
  imageBase64: z.string().min(1), // base64, max 3 MB (OCR.space free tier limit)
  language: z.enum(['pol', 'eng', 'deu']).default('pol'),
  fallbackToOcrSpace: z.boolean().default(true),
});
```

#### Zod Schema — Output

```typescript
export const OcrProcessOutputSchema = z.object({
  text: z.string(),
  confidence: z.number().min(0).max(100).optional(),
  engine: z.enum(['tesseract', 'ocrspace', 'none']),
  processingTimeMs: z.number().int(),
  fallbackUsed: z.boolean(),
});
```

---

### 3.9 `archive-class`

**Cel:** Archiwizacja klasy na koniec roku szkolnego (read-only, snapshot).

**Trigger:** HTTP POST (admin klasy)  
**Auth:** Wymagany (user JWT + admin role w klasie)  
**Rate limit:** 5/min

#### Zod Schema — Input

```typescript
export const ArchiveClassInputSchema = z.object({
  classId: UuidSchema,
  createNewClassForNextYear: z.boolean().default(false),
  newClassName: z.string().min(2).max(100).optional(),
  newSchoolYear: z.string().max(20).optional(),
});
```

#### Zod Schema — Output

```typescript
export const ArchiveClassOutputSchema = z.object({
  archivedClassId: UuidSchema,
  archivedAt: TimestampSchema,
  newClassId: UuidSchema.optional(), // jeśli createNewClassForNextYear = true
  membersMigrated: z.number().int().optional(),
});
```

---

### 3.10 `cleanup-expired-sessions`

**Cel:** CRON job — wygasanie sesji na niezaufanych urządzeniach po 4h bezczynności.

**Trigger:** Supabase Scheduled Function (CRON: `0 * * * *` — co godzinę)  
**Auth:** Service role (internal)  
**Rate limit:** N/A

#### Zod Schema — Input

Brak (CRON). Opcjonalnie:

```typescript
export const CleanupExpiredSessionsInputSchema = z.object({
  maxInactiveHours: z.number().int().min(1).max(24).default(4),
  dryRun: z.boolean().default(false),
}).optional();
```

#### Zod Schema — Output

```typescript
export const CleanupExpiredSessionsOutputSchema = z.object({
  revokedDevices: z.number().int(),
  notifiedUsers: z.number().int(),
});
```

---

## 4. Client-side API helper

Współdzielony helper do wołania Edge Functions z walidacją Zod:

```typescript
// src/lib/supabase/edgeFunctions.ts
import { z, ZodSchema } from 'zod';
import { supabase } from './client';
import { AppError } from '@/lib/errors/types';

interface ApiResponse<T> {
  success: true;
  data: T;
  meta: { requestId: string; processedAt: string; durationMs: number };
}

interface ApiError {
  success: false;
  error: {
    code: string;
    message: string;
    field?: string;
    details?: z.ZodIssue[];
  };
  meta: { requestId: string };
}

export async function callEdgeFunction<T>(
  functionName: string,
  input: unknown,
  outputSchema: ZodSchema<T>,
): Promise<{ ok: true; value: T } | { ok: false; error: AppError }> {
  try {
    const { data, error } = await supabase.functions.invoke(functionName, {
      body: { payload: input, requestId: crypto.randomUUID() },
    });

    if (error) throw new AppError('INTERNAL_ERROR', { functionName, error });

    const response = data as ApiResponse<T> | ApiError;
    if (!response.success) {
      throw new AppError(response.error.code as any, {
        functionName,
        message: response.error.message,
        field: response.error.field,
      });
    }

    const parsed = outputSchema.safeParse(response.data);
    if (!parsed.success) {
      throw new AppError('VALIDATION_ERROR', {
        functionName,
        issues: parsed.error.errors,
      });
    }

    return { ok: true, value: parsed.data };
  } catch (err) {
    const appError = err instanceof AppError ? err : new AppError('INTERNAL_ERROR', { originalError: err });
    return { ok: false, error: appError };
  }
}
```

---

## 5. OpenAPI / Swagger generation

Zod schematy mogą być automatycznie konwertowane do OpenAPI 3.1:

```bash
# Generowanie openapi.json z Zod
npx zod-to-openapi src/types/api.schemas.ts --out docs/openapi.json
```

Lub używając `zod-to-json-schema`:

```typescript
// scripts/generate-openapi.ts
import { zodToJsonSchema } from 'zod-to-json-schema';
import { ModerateMessageInputSchema, ModerateMessageOutputSchema } from '@/types/api.schemas';

const openapi = {
  openapi: '3.1.0',
  info: { title: 'KlassMate Edge Functions API', version: '0.1.0' },
  paths: {
    '/functions/v1/moderate-message': {
      post: {
        requestBody: {
          content: {
            'application/json': {
              schema: zodToJsonSchema(ModerateMessageInputSchema),
            },
          },
        },
        responses: {
          '200': {
            content: {
              'application/json': {
                schema: zodToJsonSchema(ModerateMessageOutputSchema),
              },
            },
          },
        },
      },
    },
    // ... repeat for all functions
  },
};
```

---

## 6. Testowanie Edge Functions (Deno Test)

Każda Edge Function MUSI mieć test w `supabase/functions/__tests__/`:

```typescript
// supabase/functions/__tests__/moderate-message.test.ts
import { assertEquals } from "jsr:@std/assert";
import { moderateContent } from "../moderate-message/index.ts";

Deno.test("moderate-message: approves clean homework info", async () => {
  const result = await moderateContent("Matematyka strona 45, zadanie 3-5");
  assertEquals(result.decision, "approve");
  assertEquals(result.reason, "clean");
});

Deno.test("moderate-message: rejects Polish profanity", async () => {
  const result = await moderateContent("To jest k**** zadanie");
  assertEquals(result.decision, "reject");
  assertEquals(result.reason, "profanity_pl");
});

Deno.test("moderate-message: queues borderline content", async () => {
  const result = await moderateContent("To głupie zadanie mnie wkurza");
  assertEquals(result.decision, "review");
  assertEquals(result.reason, "manual_review_required");
});

Deno.test("moderate-message: validates input schema", async () => {
  // Test Zod validation — empty content
  const result = await callEdgeFunction('moderate-message', { content: '' });
  assertEquals(result.ok, false);
  assertEquals(result.error.code, 'VALIDATION_ERROR');
});
```

---

## 7. Changelog

| Data | Wersja | Zmiana | Autor |
|------|--------|--------|-------|
| 2025-06-11 | 0.1.0 | Initial API contract with Zod schemas for all 10 Edge Functions | AI Analysis |
