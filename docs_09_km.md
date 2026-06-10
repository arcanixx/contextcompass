<!-- =============================================================================
 FILE: 09_NOTIFICATIONS_AND_REMINDERS.md
 PATH: docs/09_NOTIFICATIONS_AND_REMINDERS.md
 VERSION: 0.1.0
 PURPOSE: Pełna specyfikacja systemu powiadomień push, in-app i przypomnień (Reminders).
 FUNCTIONS: -
 DEPENDS ON: docs/01_ARCHITECTURE.md, docs/01b_ARCHITECTURE_SUPPLEMENT.md, docs/06_FEATURES_SPEC.md
 UWAGA: Przypomnienia to faza 2 (FEATURES.REMINDERS = false w MVP).
         Powiadomienia push są w MVP (FEATURES.PUSH_NOTIFICATIONS = true).
 ============================================================================= -->

# 09 — Powiadomienia i Przypomnienia

---

## 1. Architektura powiadomień — przegląd

```
ŹRÓDŁO ZDARZENIA                    PRZETWARZANIE              DOSTARCZENIE
────────────────                    ─────────────              ────────────
Nowa wiadomość w DB         ──►     Supabase DB trigger   ──►  Edge Function
Zmiana status moderacji     ──►     (pg_net webhook)      ──►  send-push-notification
Nowy request do klasy       ──►                           ──►  Expo Push API
Czas remind_at nadszedł     ──►     CRON Edge Function    ──►  Expo Push API
                                                               │
                                                               ▼
                                                    Urządzenia użytkownika
                                                    (iOS / Android / Web Push)
                                                               │
                                                    Supabase: INSERT notifications
                                                    (in-app badge + historia)
```

---

## 2. Typy powiadomień

### 2.1. Tabela typów i priorytetów

| Typ | `type` key | Push | In-app badge | In-app toast | Konfigurowalny | Priorytet |
|-----|-----------|------|-------------|-------------|----------------|-----------|
| Nowa wiadomość w kanale | `new_message` | ✅ | ✅ | ✅ (gdy app otwarta) | Per kanał | normal |
| @wzmianka | `mention` | ✅ | ✅ | ✅ | Globalny on/off | high |
| Odpowiedź w wątku | `thread_reply` | ✅ | ✅ | ✅ | Per kanał | normal |
| Nowa wiadomość DM | `dm_new` | ✅ | ✅ | ✅ | Globalny on/off | high |
| Prośba o dołączenie do klasy | `join_request` | ✅ (admin) | ✅ | ✅ | Tylko dla admina | high |
| Twoja prośba zatwierdzona | `join_approved` | ✅ | ✅ | ✅ | — | high |
| Twoja prośba odrzucona | `join_rejected` | ✅ | ✅ | ✅ | — | high |
| Wiadomość w kolejce moderacji | `moderation_queued` | ✅ (admin) | ✅ | ✅ | Tylko dla admina | normal |
| Twoja wiadomość zatwierdzona | `message_approved` | ❌ | ❌ | ✅ | — | — |
| Twoja wiadomość odrzucona | `message_rejected` | ✅ | ✅ | ✅ | — | high |
| Twoja wiadomość przycięta | `message_trimmed` | ✅ | ✅ | ✅ | — | normal |
| Przypomnienie (reminder) | `reminder` | ✅ | ✅ | ✅ | Per reminder | high |
| Wygasająca sesja (30 min) | `session_expiring` | ❌ | ❌ | ✅ (banner) | — | — |

### 2.2. Payload powiadomienia push (Expo Push)

```typescript
// supabase/functions/send-push-notification/types.ts
interface PushPayload {
  to: string;              // Expo Push Token urządzenia
  title: string;           // Tytuł powiadomienia (i18n po stronie serwera — lang z profilu)
  body: string;            // Treść (max 150 znaków)
  data: {
    type: NotificationType;
    classId?: string;
    channelId?: string;
    threadId?: string;
    messageId?: string;
    reminderId?: string;
    dmConversationId?: string;
  };
  sound: 'default' | null;
  badge?: number;          // iOS badge count (total unread)
  priority: 'normal' | 'high';
  ttl?: number;            // Time to live w sekundach (domyślnie 24h = 86400)
  expiration?: number;     // Unix timestamp wygaśnięcia
  channelId?: string;      // Android notification channel
}
```

### 2.3. Android Notification Channels

Android wymaga przypisania powiadomień do kanałów (nie mylić z kanałami KlassMate):

```typescript
// src/services/NotificationService.ts
const ANDROID_CHANNELS = [
  {
    id: 'messages',
    name: 'Wiadomości',
    importance: AndroidImportance.DEFAULT,
    sound: 'default',
    vibrationPattern: [0, 250],
  },
  {
    id: 'mentions',
    name: 'Wzmianki i DM',
    importance: AndroidImportance.HIGH,
    sound: 'default',
    vibrationPattern: [0, 250, 250, 250],
  },
  {
    id: 'reminders',
    name: 'Przypomnienia',
    importance: AndroidImportance.HIGH,
    sound: 'default',
  },
  {
    id: 'moderation',
    name: 'Moderacja',
    importance: AndroidImportance.DEFAULT,
    sound: null,           // Ciche — adminowi nie przeszkadza
  },
] as const;
```

---

## 3. Edge Function: `send-push-notification`

```typescript
// supabase/functions/send-push-notification/index.ts
/**
 * @file index.ts
 * @path supabase/functions/send-push-notification/index.ts
 * @description
 * Edge Function wywoływana przez: DB trigger (pg_net) przy INSERT do tabeli notifications,
 * oraz przez CRON function przy dojrzałych reminderach.
 * Odpowiada za: pobranie tokenów push urządzenia, sprawdzenie preferencji wyciszenia,
 * wysłanie przez Expo Push API, aktualizację badge count.
 * @exports Deno.serve handler
 * @dependsOn supabase/functions/send-push-notification/types.ts
 */

import { createClient } from 'jsr:@supabase/supabase-js@2';

const EXPO_PUSH_URL = 'https://exp.host/--/api/v2/push/send';

Deno.serve(async (req) => {
  try {
    const { notification_id } = await req.json();
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // 1. Pobierz powiadomienie
    const { data: notification } = await supabase
      .from('notifications')
      .select('*, profiles!recipient_id(settings, birth_year)')
      .eq('id', notification_id)
      .single();

    if (!notification) throw new Error('NOTIFICATION_NOT_FOUND');

    const recipientSettings = notification.profiles.settings;

    // 2. Sprawdź preferencje — czy typ powiadomienia jest włączony?
    if (!isNotificationEnabled(recipientSettings, notification.type)) {
      return new Response(JSON.stringify({ skipped: 'user_preference' }), { status: 200 });
    }

    // 3. Sprawdź quiet hours
    if (isInQuietHours(recipientSettings)) {
      // Dla reminderów — wyślij mimo quiet hours jeśli user tak skonfigurował
      if (notification.type !== 'reminder' || !recipientSettings.reminder_ignore_quiet_hours) {
        return new Response(JSON.stringify({ skipped: 'quiet_hours' }), { status: 200 });
      }
    }

    // 4. Pobierz tokeny push urządzenia
    const { data: devices } = await supabase
      .from('devices')
      .select('push_token')
      .eq('profile_id', notification.recipient_id)
      .not('push_token', 'is', null);

    if (!devices?.length) {
      return new Response(JSON.stringify({ skipped: 'no_devices' }), { status: 200 });
    }

    // 5. Wyślij do wszystkich urządzeń użytkownika
    const messages = devices.map(device => buildPushMessage(device.push_token, notification));
    await fetch(EXPO_PUSH_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(messages),
    });

    return new Response(JSON.stringify({ sent: devices.length }), { status: 200 });

  } catch (error) {
    console.error('[send-push-notification] Error:', error);
    return new Response(JSON.stringify({ error: 'INTERNAL_ERROR' }), { status: 500 });
  }
});
```

---

## 4. Ustawienia powiadomień — pełna specyfikacja UI

### 4.1. Struktura preferencji w `profiles.settings`

```typescript
interface NotificationSettings {
  // Master switch
  push_enabled: boolean;                    // domyślnie: true (po akceptacji uprawnień)
  in_app_sounds: boolean;                   // domyślnie: true
  vibration: boolean;                       // domyślnie: true

  // Quiet hours
  quiet_hours_enabled: boolean;             // domyślnie: false
  quiet_hours_from: string;                 // "22:00" (HH:MM)
  quiet_hours_to: string;                   // "07:00"

  // Per-type overrides
  notify_mentions: boolean;                 // domyślnie: true
  notify_dm: boolean;                       // domyślnie: true
  notify_join_requests: boolean;            // domyślnie: true (tylko dla admina)
  notify_moderation: boolean;               // domyślnie: true (tylko dla admina)
  notify_my_message_moderated: boolean;     // domyślnie: true

  // Per-class overrides (klucz: classId)
  class_overrides: Record<string, {
    muted: boolean;                         // Wycisz całą klasę
    channel_overrides: Record<string, {     // klucz: channelId
      muted: boolean;
      mode: 'all' | 'mentions_only' | 'off';
    }>;
  }>;

  // Lock screen / preview
  show_preview_on_lock_screen: boolean;    // domyślnie: false (prywatność)

  // Reminder-specific
  reminder_ignore_quiet_hours: boolean;    // domyślnie: false
}
```

### 4.2. Ekran Settings → Powiadomienia (wireframe)

```
⚙️ Powiadomienia
────────────────────────────────────────────────
🔔 Powiadomienia push          [toggle: ON ]
    Wymaga uprawnień systemowych

─── Ogólne ────────────────────────────────────
🔊 Dźwięki w aplikacji         [toggle: ON ]
📳 Wibracje                    [toggle: ON ]
🔒 Podgląd na ekranie blokady  [toggle: OFF]
    Wiadomości nie pokazują się w powiadomieniach
    na zablokowanym ekranie (zalecane dla prywatności)

─── Ciche godziny ─────────────────────────────
🌙 Ciche godziny               [toggle: OFF]
    Od: [22:00 ▾]  Do: [07:00 ▾]
    ☑ Nie blokuj przypomnień w cichych godzinach

─── Typy powiadomień ──────────────────────────
💬 Wzmianki (@twoja_nazwa)     [toggle: ON ]
✉️ Wiadomości prywatne (DM)   [toggle: ON ]
🛡️ Kolejka moderacji          [toggle: ON ]  ← widoczne tylko dla adminów
❌ Moja wiadomość odrzucona    [toggle: ON ]

─── Klasy i kanały ────────────────────────────
Klasa 3B                       [Zarządzaj ›]
  ├ Wycisz całą klasę          [toggle: OFF]
  ├ #matematyka                [Wszystkie ▾]
  ├ #polski                    [Tylko wzmianki ▾]
  └ #historia                  [Wyłączone ▾]

+ Dodaj kolejną klasę
────────────────────────────────────────────────
```

---

## 5. Przypomnienia (Reminders) — Faza 2

> **Feature flag:** `FEATURES.REMINDERS = false` w MVP Sprint 1.
> Włącz w Sprint 2 po zaimplementowaniu tabeli i Edge Function.

### 5.1. CRON Edge Function

```typescript
// supabase/functions/process-reminders/index.ts
/**
 * @file index.ts
 * @path supabase/functions/process-reminders/index.ts
 * @description
 * CRON job uruchamiany co 1 minutę przez Supabase Scheduled Functions.
 * Pobiera przypomnienia z remind_at <= now(), wysyła push i oznacza jako is_sent = true.
 * Schedule: '* * * * *' (każda minuta)
 * @exports Deno.serve handler
 */

Deno.serve(async () => {
  try {
    const supabase = createClient(/* service role */);

    // Pobierz przypomnienia gotowe do wysłania
    const { data: dueReminders } = await supabase
      .from('reminders')
      .select(`
        *,
        profiles!owner_id(settings)
      `)
      .lte('remind_at', new Date().toISOString())
      .eq('is_sent', false)
      .eq('is_dismissed', false)
      .limit(100); // max 100 na raz, następna minuta ogarnie resztę

    if (!dueReminders?.length) {
      return new Response(JSON.stringify({ processed: 0 }), { status: 200 });
    }

    let sentCount = 0;
    for (const reminder of dueReminders) {
      // Sprawdź czy kanał/klasa wyciszona
      const settings = reminder.profiles.settings;
      if (reminder.channel_id && isChannelMuted(settings, reminder.channel_id)) {
        // Mimo wyciszenia kanału — reminder i tak wysyłamy (user świadomie go ustawił)
        // chyba że `notify_type = 'reminder'` jest wyłączony globalnie
      }

      // Utwórz notification record
      await supabase.from('notifications').insert({
        recipient_id: reminder.owner_id,
        type: 'reminder',
        payload: {
          title: reminder.title,
          note: reminder.note,
          class_id: reminder.class_id,
          channel_id: reminder.channel_id,
          reminder_id: reminder.id,
        },
      });
      // DB trigger wyśle push przez send-push-notification Edge Function

      // Oznacz jako wysłany
      await supabase
        .from('reminders')
        .update({ is_sent: true })
        .eq('id', reminder.id);

      // Jeśli repeat_type !== 'none' — utwórz następne
      if (reminder.repeat_type !== 'none') {
        await scheduleNextReminder(supabase, reminder);
      }

      sentCount++;
    }

    return new Response(JSON.stringify({ processed: sentCount }), { status: 200 });

  } catch (error) {
    console.error('[process-reminders] Error:', error);
    return new Response(JSON.stringify({ error: 'INTERNAL_ERROR' }), { status: 500 });
  }
});
```

### 5.2. Ekran przypomnień — widok listy

```
🔔 Moje przypomnienia
──────────────────────────────────────────────────
[Sortuj: Chronologicznie ▾]  [+ Nowe przypomnienie]

─── Nadchodzące ───────────────────────────────────
🔔  Praca domowa z matematyki
    #matematyka · Klasa 3B
    ⏰ Jutro, 18:00
    [Edytuj]  [Usuń 🗑️]

🔔  Sprawdzian z historii
    #historia · Klasa 3B
    ⏰ Piątek, 8:00
    Notatka: Rozdziały 12–15, mapy polityczne
    [Edytuj]  [Usuń 🗑️]

─── Wysłane (ostatnie 7 dni) ──────────────────────
✅  Angielski — słówka na kartkówkę      Wtorek, 19:00
✅  Oddać podpisaną zgodę na wycieczkę   Poniedziałek, 7:30

──────────────────────────────────────────────────
```

### 5.3. Tworzenie przypomnienia z wiadomości (long press)

Długie naciśnięcie wiadomości w kanale → context menu:

```
Context menu:
├── 💬 Odpowiedz w wątku
├── 📋 Skopiuj tekst
├── 🔔 Przypomnij mi o tym         ← nowa opcja (Phase 2)
├── 🚩 Zgłoś wiadomość
└── 🗑️ Usuń (tylko własne)
```

Po wybraniu "Przypomnij mi o tym" → otwiera się modal createReminder z pre-uzupełnionym tytułem z treści wiadomości (pierwszych 50 znaków) i powiązanym kanałem.

---

## 6. In-app notification center

### 6.1. Dostęp

- Ikona dzwonka w górnym prawym rogu głównego ekranu
- Badge z licznikiem nieprzeczytanych
- Tap → otwiera panel/ekran "Powiadomienia"

### 6.2. Widok listy powiadomień

```
🔔 Powiadomienia (5 nowych)
──────────────────────────────────────────────
[Wszystkie ▾]  [Oznacz wszystkie jako przeczytane]

─── Nowe ──────────────────────────────────────
● 👤 Ania Wiśniewska wspomniała o Tobie
  #matematyka · Klasa 3B
  "...czy @jan możesz wytłumaczyć zad. 5?"
  2 minuty temu  [→ Otwórz]

● 🛡️ Nowa wiadomość w kolejce moderacji
  #angielski · Klasa 3B  
  Oczekuje na Twoją decyzję
  15 minut temu  [→ Sprawdź]

● ✉️ Nowa wiadomość od Marty K.
  Wiadomość prywatna
  Godzinę temu  [→ Otwórz]

─── Wcześniejsze ──────────────────────────────
○ ✅ Tomek W. dołączył do klasy 3B
  Zatwierdzono przez Ciebie
  Wczoraj, 14:30

○ 🔔 Przypomnienie: Praca domowa z matmy
  #matematyka · Klasa 3B
  Wczoraj, 18:00

──────────────────────────────────────────────
```

### 6.3. Obsługa kliknięcia powiadomienia (deep link)

Każde kliknięcie powiadomienia (push lub in-app) naviguje do właściwego miejsca:

```typescript
// src/services/NotificationService.ts
const handleNotificationTap = (notification: Notification) => {
  const { type, payload } = notification;

  switch (type) {
    case 'new_message':
    case 'mention':
    case 'thread_reply':
      router.push(`/class/${payload.classId}/channel/${payload.channelId}`);
      break;
    case 'dm_new':
      router.push(`/dm/${payload.dmConversationId}`);
      break;
    case 'join_request':
    case 'moderation_queued':
      router.push(`/class/${payload.classId}/moderation`);
      break;
    case 'join_approved':
    case 'join_rejected':
      router.push(`/class/${payload.classId}`);
      break;
    case 'message_rejected':
    case 'message_trimmed':
      router.push(`/class/${payload.classId}/channel/${payload.channelId}`);
      break;
    case 'reminder':
      if (payload.channel_id) {
        router.push(`/class/${payload.classId}/channel/${payload.channelId}`);
      } else {
        router.push('/notes/reminders');
      }
      break;
  }

  // Oznacz jako przeczytane
  markNotificationRead(notification.id);
};
```

---

## 7. Uprawnienia i permission flow

### 7.1. Kiedy prosić o uprawnienia

**NIGDY przy starcie aplikacji.** Uprawnienia push prosimy o nie przy kontekście — po wykonaniu pierwszej sensownej akcji:

```
Użytkownik dołącza do klasy po raz pierwszy
    │
    ├──► Sukces → po 2s pokazuje się bottom sheet:
    │    "Włącz powiadomienia, żeby wiedzieć
    │     gdy ktoś napisze w #matematyka"
    │    [Włącz] [Nie teraz]
    │
    ├──► [Włącz] → SystemPermissionRequest → jeśli granted: zapisz token
    │
    └──► [Nie teraz] → zapisz w settings: `push_request_deferred: true`
         Nie pytaj ponownie przez 7 dni
```

### 7.2. Obsługa "Denied" (użytkownik odmówił systemowo)

```typescript
const handlePermissionDenied = () => {
  // Nie spamuj ponownymi prośbami
  // Pokaż informację w Settings → Powiadomienia:
  // "Powiadomienia wyłączone w ustawieniach systemu"
  // [Otwórz ustawienia systemu]  ← Linking.openSettings()

  // NIE pokazuj toast z błędem — po prostu app działa bez push
  // In-app notification center nadal działa
};
```

### 7.3. Token management

```typescript
// Przy każdym uruchomieniu aplikacji:
const refreshPushToken = async () => {
  const { data: token } = await Notifications.getExpoPushTokenAsync({
    projectId: Constants.expoConfig?.extra?.eas?.projectId,
  });

  // Zapisz/zaktualizuj token w tabeli devices
  await supabase.from('devices').upsert({
    profile_id: currentUserId,
    push_token: token.data,
    device_type: Platform.OS,
    last_seen_at: new Date().toISOString(),
  }, { onConflict: 'profile_id,device_type' });
};

// Przy wylogowaniu — usuń token (żeby nie dostawać powiadomień po logout)
const clearPushToken = async () => {
  await supabase.from('devices').update({ push_token: null })
    .eq('profile_id', currentUserId)
    .eq('device_type', Platform.OS);
};
```
