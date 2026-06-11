# 16 — Analytics Plan
# Path: docs/16_analytics_plan.md
# Purpose: Jakie eventy trackować, jakie metryki mierzyć, privacy-first approach
# Depends on: docs/00_PROJECT_OVERVIEW.md, docs/08_ROADMAP_AND_MONETISATION.md, docs/11_user_stories_and_ac.md
# Status: MVP v0.1 (Phase 1)

---

# KlassMate — Analytics & Metrics Plan

> **Wersja:** 0.1.0-draft  
> **Ostatnia aktualizacja:** 2025-06-11  
> **Filozofia:** Privacy-first. Tylko zagregowane dane. Zero PII. Zero tracking indywidualnych użytkowników.  
> **Cel:** Rozumieć użycie produktu, identyfikować churn, optymalizować onboarding i retencję — bez naruszania prywatności dzieci.

---

## 1. Zasady privacy-first analytics

| Zasada | Implementacja |
|--------|---------------|
| **No PII** | Eventy nie zawierają: user_id, email, display_name, message content, avatar URL. |
| **No individual tracking** | Nie tworzymy profili behawioralnych użytkowników. Funnel = zagregowany. |
| **No third-party trackers** | Nie używamy Google Analytics, Facebook Pixel, Mixpanel. Własny system na Supabase. |
| **Opt-out** | Użytkownik może wyłączyć analitykę w Settings → Prywatność. |
| **Data minimization** | Zbieramy tylko to, co jest niezbędne do decyzji produktowych. |
| **Retention** | Eventy analityczne przechowywane 90 dni, potem auto-delete (CRON). |
| **RODO basis** | Legitimate interest (Art. 6(1)(f)) — zagregowane statystyki użycia aplikacji. |

---

## 2. Architektura analityki

```
┌─────────────────────────────────────────┐
│  CLIENT APP (React Native / Expo Web)    │
│  ┌─────────────────────────────────────┐  │
│  │ AnalyticsService.ts               │  │
│  │ - batchuje eventy lokalnie        │  │
│  │ - flush co 30s lub przy background│  │
│  │ - jeśli opt-out = true → no-op    │  │
│  └─────────────────────────────────────┘  │
└────────────────────┬──────────────────────┘
                     │ HTTPS POST
┌────────────────────▼──────────────────────┐
│  SUPABASE Edge Function: `ingest-analytics`│
│  - walidacja schema (Zod)                │
│  - odrzucenie jeśli zawiera PII          │
│  - zapis do `analytics_events`           │
└────────────────────┬──────────────────────┘
                     │
┌────────────────────▼──────────────────────┐
│  TABLE: `analytics_events`                 │
│  - append-only, partitioned by day         │
│  - auto-delete po 90 dniach (CRON)       │
│  - RLS: NO user access (service role)    │
└───────────────────────────────────────────┘
```

**Dlaczego nie używamy gotowych narzędzi (GA, Mixpanel, Amplitude)?**
- Google Analytics = US company, data transfer, RODO risk.
- Mixpanel / Amplitude = drogie przy scale, mogą zbierać więcej niż chcemy.
- Własny system = pełna kontrola nad danymi, zero kosztów, RODO-compliant by design.

---

## 3. Eventy — pełna lista

### 3.1 Eventy produktowe (Product Events)

Te eventy mówią CO użytkownik robi w aplikacji.

| Event name | Kiedy wysyłać | Właściwości (properties) | Cel biznesowy |
|------------|-------------|---------------------------|---------------|
| `app_open` | Przy każdym foreground app | `platform`, `app_version`, `theme` | DAU/MAU, platform split |
| `app_close` | Przy background / kill | `session_duration_seconds` | Session length, engagement |
| `onboarding_start` | Po splash screen | `slide_count` | Onboarding funnel |
| `onboarding_complete` | Po ostatnim slajdzie lub „Pomiń” | `slides_seen`, `skipped` | Onboarding completion rate |
| `onboarding_skip` | Po kliknięciu „Pomiń” | `slide_index` | Gdzie użytkownicy rezygnują |
| `register_start` | Po kliknięciu „Zarejestruj się” | `method` (email/google/apple) | Conversion funnel |
| `register_complete` | Po aktywacji konta (email verified / consent given) | `method`, `age_group` (<13, 13-15, 16+) | Sign-up conversion |
| `login_success` | Po udanym logowaniu | `method`, `is_trusted_device` | Retencja, auth method preference |
| `login_failure` | Po nieudanym logowaniu | `method`, `error_code` | UX friction |
| `parental_consent_sent` | Po wysłaniu emaila do rodzica | — | Consent flow health |
| `parental_consent_received` | Po kliknięciu linku przez rodzica | `response` (approved/rejected) | Consent conversion |
| `class_create` | Po utworzeniu klasy | `has_school_name`, `channel_count` | Viral loop start |
| `class_join` | Po dołączeniu do klasy | `method` (code/link), `required_approval` | Growth metric |
| `member_approved` | Po zatwierdzeniu przez admina | — | Activation rate |
| `member_rejected` | Po odrzuceniu | — | Abuse detection |
| `channel_message_sent` | Po wysłaniu wiadomości (approved by moderation) | `has_attachment`, `message_length_bucket` (short/medium/long) | Core engagement |
| `dm_sent` | Po wysłaniu DM | — | DM adoption (Phase 2) |
| `moderation_decision` | Po decyzji Edge Function | `decision` (approve/review/reject), `reason`, `confidence_bucket` (low/medium/high) | Safety metric |
| `moderation_queue_action` | Po akcji admina | `action` (approve/reject/trim), `queue_wait_minutes` | Admin responsiveness |
| `voice_message_sent` | Po wysłaniu voice (Phase 2) | `duration_seconds_bucket` | Feature adoption |
| `attachment_uploaded` | Po uploadzie załącznika | `file_type`, `size_bucket`, `compression_ratio` | Storage usage |
| `note_created` | Po utworzeniu notatki | `source` (manual/ocr), `has_ocr_fallback` | Notes adoption (Phase 2) |
| `reminder_created` | Po utworzeniu przypomnienia | `has_channel_link`, `repeat_type` | Reminders adoption (Phase 2) |
| `backup_exported` | Po wygenerowaniu backupu | `format`, `size_bucket` | Data portability usage |
| `account_deleted` | Po usunięciu konta | `reason` (optional) | Churn signal |
| `settings_changed` | Po zmianie ustawień | `setting_key`, `new_value` (anonymized) | Preference trends |
| `push_permission_granted` | Po akceptacji powiadomień | `context` (after_join/after_first_message/settings) | Push opt-in rate |
| `push_permission_denied` | Po odmowie | `context` | Push friction |
| `device_trusted` | Po oznaczeniu urządzenia jako trusted | — | Security behavior |
| `device_revoked` | Po odwołaniu urządzenia | — | Security behavior |
| `biometric_enabled` | Po włączeniu biometrii | `method` (face_id/touch_id/fingerprint) | Security adoption |
| `error_reported` | Po wysłaniu raportu błędu | `error_code`, `platform` | Quality metric |

### 3.2 Eventy biznesowe (Business Events)

Te eventy mówią o monetizacji i wartości.

| Event name | Kiedy wysyłać | Właściwości | Cel biznesowy |
|------------|-------------|-------------|---------------|
| `premium_view_pricing` | Po otwarciu ekranu cen (Phase 3) | `source` (settings/banner/upsell) | Pricing page traffic |
| `premium_start_trial` | Po rozpoczęciu trialu | `plan` (monthly/annual) | Trial conversion |
| `premium_subscribe` | Po zakupie | `plan`, `payment_method`, `revenue_pln` | MRR/ARR |
| `premium_cancel` | Po anulowaniu | `plan`, `tenure_days`, `reason` (optional) | Churn analysis |
| `ad_impression` | Po wyświetleniu reklamy (Phase 3) | `ad_type`, `placement` | Ad revenue |
| `ad_click` | Po kliknięciu reklamy | `ad_type` | Ad engagement |
| `school_plan_inquiry` | Po wypełnieniu formularza kontaktowego (Phase 3) | `school_size_bucket` | B2B pipeline |

### 3.3 Eventy techniczne (Technical Events)

Te eventy mówią o stabilności i performance.

| Event name | Kiedy wysyłać | Właściwości | Cel techniczny |
|------------|-------------|-------------|----------------|
| `api_request` | Po każdym request do Supabase | `endpoint`, `method`, `duration_ms`, `status_code` | API performance |
| `edge_function_error` | Po błędzie Edge Function | `function_name`, `error_code` | Backend health |
| `offline_queue_flush` | Po wysłaniu offline queue | `item_count`, `success_count`, `fail_count` | Offline reliability |
| `realtime_reconnect` | Po reconnect Supabase Realtime | `disconnect_duration_seconds`, `reconnect_attempts` | Connection stability |
| `ocr_success` | Po udanym OCR | `engine`, `processing_time_ms`, `confidence_bucket` | OCR performance |
| `ocr_failure` | Po nieudanym OCR | `engine`, `error_code` | OCR reliability |
| `app_crash` | Po crashu (Sentry catch) | `error_code`, `platform`, `app_version` | Stability |

---

## 4. Metryki (Metrics) — dashboard produktowy

### 4.1 North Star Metric

**North Star:** `Weekly Active Classes (WAC)` — liczba klas, w których w danym tygodniu została wysłana co najmniej 1 wiadomość.

Dlaczego:
- Odzwierciedla core value (komunikacja w klasie).
- Jest zagregowany — nie trackuje indywidualnych użytkowników.
- Wzrost WAC = wzrost viral loop (1 klasa = 20–30 użytkowników).

### 4.2 Funnel — rejestracja do aktywacji

| Krok | Event | Metryka | Target MVP |
|------|-------|---------|------------|
| 1. App open | `app_open` | DAU | — |
| 2. Onboarding start | `onboarding_start` | Onboarding start rate | 90% |
| 3. Onboarding complete | `onboarding_complete` | Onboarding completion rate | 70% |
| 4. Register start | `register_start` | Register start rate | 60% |
| 5. Register complete | `register_complete` | Sign-up conversion | 40% |
| 6. Class created / joined | `class_create` / `class_join` | Class activation rate | 80% |
| 7. First message sent | `channel_message_sent` | Core activation (Aha! moment) | 60% |
| 8. Message sent day 7 | `channel_message_sent` | D7 retention (class-level) | 50% |

**Cel MVP:** 1 klasa aktywna przez 4 tygodnie z 5–10 uczniami, każdy wysłał ≥ 5 wiadomości.

### 4.3 Retencja

| Metryka | Definicja | Jak mierzyć | Target Phase 2 |
|---------|-----------|-------------|----------------|
| D1 retention | % klas z wiadomością w dniu 1 po dołączeniu | `class_join` → `channel_message_sent` w D1 | 60% |
| D7 retention | % klas z wiadomością w dniu 7 | `class_join` → `channel_message_sent` w D7 | 40% |
| D30 retention | % klas z wiadomością w dniu 30 | `class_join` → `channel_message_sent` w D30 | 25% |
| WAU/MAU | Weekly Active Classes / Monthly Active Classes | WAC / MAC | 40% |

**Uwaga:** Mierzymy retencję na poziomie **klasy**, nie użytkownika. To zagregowane i lepsze odzwierciedla viral loop.

### 4.4 Engagement

| Metryka | Definicja | Target MVP |
|---------|-----------|------------|
| Messages per class per day | Średnia liczba wiadomości w aktywnej klasie dziennie | 10 |
| Messages per user per week | Średnia liczba wiadomości na użytkownika w tygodniu | 5 |
| Moderation queue size (avg) | Średnia liczba wiadomości w kolejce moderacji | < 5 |
| Moderation response time (avg) | Średni czas od `queued_review` do decyzji admina | < 2h |
| Push opt-in rate | % użytkowników, którzy włączyli push | 60% |
| Offline queue flush success | % wiadomości z offline queue wysłanych po reconnect | 95% |

### 4.5 Monetizacja (Phase 3+)

| Metryka | Definicja | Target Phase 3 |
|---------|-----------|----------------|
| Free-to-Premium conversion | % użytkowników, którzy kupili Premium | 5% |
| Trial-to-Paid conversion | % trial users, którzy zostali po okresie próbnym | 30% |
| ARPU (Average Revenue Per User) | MRR / liczba aktywnych użytkowników | 0.50 PLN/mies |
| LTV (Lifetime Value) | Średni przychód z użytkownika przez cały okres | 15 PLN |
| CAC (Customer Acquisition Cost) | Koszt pozyskania 1 użytkownika (marketing) | < 5 PLN |
| School Plan pipeline | Liczba zapytań B2B / miesiąc | 3 |

### 4.6 Quality & Stability

| Metryka | Definicja | Target MVP |
|---------|-----------|------------|
| Crash-free rate | % sesji bez crashu (Sentry) | 99.5% |
| API p95 latency | 95th percentile czasu odpowiedzi Supabase | < 500ms |
| Edge Function p95 latency | 95th percentile czasu Edge Function | < 300ms |
| App load time (TTI) | Time to Interactive na web (3G) | < 3s |
| Error rate | % requestów zakończonych błędem | < 1% |

---

## 5. Implementacja analityki

### 5.1 Schema tabeli `analytics_events`

```sql
CREATE TABLE analytics_events (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_name    text NOT NULL,
  event_version int NOT NULL DEFAULT 1,          -- wersja schema eventu
  properties    jsonb NOT NULL DEFAULT '{}',     -- zagregowane, bez PII
  platform      text NOT NULL,                   -- 'ios' | 'android' | 'web'
  app_version   text NOT NULL,
  session_id    text NOT NULL,                   -- anonimowy, rotowany co 30min
  timestamp     timestamptz NOT NULL DEFAULT now(),
  inserted_at   timestamptz NOT NULL DEFAULT now()
) PARTITION BY RANGE (timestamp);

-- Partycje per miesiąc (automatyczne tworzenie via CRON)
CREATE TABLE analytics_events_2025_06 PARTITION OF analytics_events
  FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');

-- Indeksy
CREATE INDEX idx_analytics_events_name ON analytics_events(event_name, timestamp);
CREATE INDEX idx_analytics_events_session ON analytics_events(session_id, timestamp);

-- RLS: brak dostępu dla użytkowników (tylko service role / dashboard)
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "no_user_access" ON analytics_events FOR ALL USING (false);
```

### 5.2 Edge Function `ingest-analytics`

```typescript
// supabase/functions/ingest-analytics/index.ts
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { z } from 'npm:zod@3.23.8';

const EventSchema = z.object({
  event_name: z.string().min(1).max(100),
  event_version: z.number().int().min(1).default(1),
  properties: z.record(z.unknown()).default({}),
  platform: z.enum(['ios', 'android', 'web']),
  app_version: z.string(),
  session_id: z.string().uuid(),
  timestamp: z.string().datetime(),
});

Deno.serve(async (req) => {
  try {
    const { payload } = await req.json();
    const event = EventSchema.parse(payload);

    // Sanity check: reject if properties contain potential PII patterns
    const propsStr = JSON.stringify(event.properties);
    if (propsStr.includes('@') || propsStr.includes('http')) {
      return new Response(JSON.stringify({
        success: false, error: { code: 'POTENTIAL_PII', message: 'Event rejected' }
      }), { status: 400 });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    await supabase.from('analytics_events').insert(event);

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error) {
    return new Response(JSON.stringify({
      success: false, error: { code: 'VALIDATION_ERROR', message: String(error) }
    }), { status: 400 });
  }
});
```

### 5.3 Client-side service

```typescript
// src/services/AnalyticsService.ts
import { supabase } from '@/lib/supabase/client';
import { logger } from '@/lib/errors/logger';

const BATCH_SIZE = 20;
const FLUSH_INTERVAL_MS = 30_000;

interface AnalyticsEvent {
  event_name: string;
  event_version?: number;
  properties?: Record<string, unknown>;
}

class AnalyticsService {
  private queue: AnalyticsEvent[] = [];
  private timer: ReturnType<typeof setInterval> | null = null;
  private sessionId = crypto.randomUUID();
  private optOut = false;

  init() {
    this.optOut = /* read from profiles.settings.analytics_opt_out */ false;
    this.timer = setInterval(() => this.flush(), FLUSH_INTERVAL_MS);
  }

  track(event: AnalyticsEvent) {
    if (this.optOut) return;
    this.queue.push(event);
    if (this.queue.length >= BATCH_SIZE) this.flush();
  }

  private async flush() {
    if (!this.queue.length) return;
    const batch = this.queue.splice(0, BATCH_SIZE);

    try {
      await supabase.functions.invoke('ingest-analytics', {
        body: {
          payload: batch.map(e => ({
            ...e,
            event_version: e.event_version ?? 1,
            properties: e.properties ?? {},
            platform: Platform.OS === 'web' ? 'web' : Platform.OS,
            app_version: Constants.expoConfig?.version ?? 'unknown',
            session_id: this.sessionId,
            timestamp: new Date().toISOString(),
          })),
        },
      });
    } catch (error) {
      logger.warn('Analytics flush failed', { error });
      // Nie retry — eventy analityczne nie są krytyczne
    }
  }

  destroy() {
    if (this.timer) clearInterval(this.timer);
    this.flush();
  }
}

export const analytics = new AnalyticsService();
```

### 5.4 Dashboard (Phase 2)

W Phase 2 można zbudować prosty dashboard SQL + React:

```sql
-- Przykładowe zapytania dla dashboardu

-- DAU (Daily Active Users — zagregowane, nie PII)
SELECT 
  DATE(timestamp) as day,
  COUNT(DISTINCT session_id) as dau
FROM analytics_events
WHERE event_name = 'app_open'
  AND timestamp >= NOW() - INTERVAL '30 days'
GROUP BY day
ORDER BY day;

-- Onboarding funnel
SELECT 
  event_name,
  COUNT(*) as count
FROM analytics_events
WHERE event_name IN ('onboarding_start', 'onboarding_complete', 'register_complete', 'class_join', 'channel_message_sent')
  AND timestamp >= NOW() - INTERVAL '7 days'
GROUP BY event_name;

-- Core activation (classes with messages this week)
SELECT COUNT(DISTINCT properties->>'class_id') as wac
FROM analytics_events
WHERE event_name = 'channel_message_sent'
  AND timestamp >= NOW() - INTERVAL '7 days';
```

---

## 6. Retencja danych i compliance

| Typ danych | Retencja | Mechanizm |
|------------|----------|-----------|
| `analytics_events` | 90 dni | CRON job: `DELETE FROM analytics_events WHERE timestamp < NOW() - INTERVAL '90 days'` |
| Aggregated reports (dashboard) | Nieskończona | Tylko zagregowane liczby (DAU, WAC), bez session_id |
| Session IDs | 90 dni | Usuwane razem z eventami |

---

## 7. Changelog

| Data | Wersja | Zmiana | Autor |
|------|--------|--------|-------|
| 2025-06-11 | 0.1.0 | Initial analytics plan — 40+ events, 15+ metrics, privacy-first architecture | AI Analysis |
