<!-- =============================================================================
 FILE: 10_SESSION_AND_STATE.md
 PATH: docs/10_SESSION_AND_STATE.md
 VERSION: 0.1.0
 PURPOSE: Zarządzanie stanem aplikacji — offline mode, optymistyczne aktualizacje,
          Zustand store design, konflikty sesji między urządzeniami.
 FUNCTIONS: -
 DEPENDS ON: docs/01_ARCHITECTURE.md, docs/04_SECURITY.md
 ============================================================================= -->

# 10 — Zarządzanie sesją i stanem aplikacji

---

## 1. Architektura stanu — przegląd

```
┌─────────────────────────────────────────────────────────┐
│                   ZUSTAND STORES                         │
│                                                          │
│  authStore      classStore     messageStore              │
│  (sesja, user)  (klasy, kanały)(wiadomości per kanał)    │
│                                                          │
│  notificationStore  uiStore    noteStore                 │
│  (badge counts)     (modals,   (notatki, OCR state)      │
│                      theme)                              │
└──────────────────────┬──────────────────────────────────┘
                       │ reads/writes
┌──────────────────────▼──────────────────────────────────┐
│              SUPABASE CLIENT (singleton)                  │
│  Auth · PostgREST · Realtime subscriptions               │
└──────────────────────┬──────────────────────────────────┘
                       │
              Online ◄─┴─► Offline
                       │
┌──────────────────────▼──────────────────────────────────┐
│           OFFLINE QUEUE (SecureStore)                     │
│  Pending messages, pending reads — wysyłane po reconnect  │
└──────────────────────────────────────────────────────────┘
```

---

## 2. Zustand stores — szczegółowy design

### 2.1. `authStore`

```typescript
// src/store/authStore.ts
/**
 * @file authStore.ts
 * @path src/store/authStore.ts
 * @description Stan uwierzytelnienia, profil użytkownika, device trust.
 * @exports useAuthStore
 * @dependsOn src/types/auth.types.ts, src/lib/auth/session.ts
 */
interface AuthState {
  user: Profile | null;
  session: Session | null;
  deviceTrusted: boolean;
  isLoading: boolean;
  isInitialized: boolean;     // true po pierwszym sprawdzeniu sesji przy starcie
}

interface AuthActions {
  setUser: (user: Profile | null) => void;
  setSession: (session: Session | null) => void;
  setDeviceTrusted: (trusted: boolean) => void;
  signOut: () => Promise<void>;
  refreshProfile: () => Promise<void>;
}
```

### 2.2. `classStore`

```typescript
// src/store/classStore.ts
/**
 * @file classStore.ts
 * @path src/store/classStore.ts
 * @description Lista klas, kanałów, liczniki nieprzeczytanych.
 * @exports useClassStore
 * @dependsOn src/types/class.types.ts, src/lib/supabase/queries/classes.ts
 */
interface ClassState {
  classes: Record<string, Class>;          // keyed by classId
  channels: Record<string, Channel[]>;     // keyed by classId
  members: Record<string, ClassMember[]>;  // keyed by classId
  unreadCounts: Record<string, number>;    // keyed by channelId
  activeClassId: string | null;
  activeChannelId: string | null;
  isLoading: boolean;
}
```

### 2.3. `messageStore`

```typescript
// src/store/messageStore.ts
/**
 * @file messageStore.ts
 * @path src/store/messageStore.ts
 * @description Wiadomości per kanał, optymistyczne aktualizacje, offline queue.
 * @exports useMessageStore
 * @dependsOn src/types/message.types.ts
 */
interface MessageState {
  // Wiadomości per kanał (ostatnie 50 w pamięci)
  messages: Record<string, Message[]>;

  // Optymistyczne wiadomości (wysłane lokalnie, czekają na potwierdzenie serwera)
  pendingMessages: Record<string, PendingMessage[]>;

  // Offline queue (do wysłania po reconnect)
  offlineQueue: OfflineQueueItem[];

  // Czy jest więcej wiadomości do załadowania (paginacja)
  hasMore: Record<string, boolean>;

  // Cursor do paginacji (last message id per kanał)
  cursors: Record<string, string>;
}

interface PendingMessage {
  localId: string;           // tymczasowy UUID generowany kliencko
  channelId: string;
  content: string;
  createdAt: string;
  status: 'sending' | 'moderating' | 'failed';
}

interface OfflineQueueItem {
  localId: string;
  channelId: string;
  content: string;
  voiceUrl?: string;
  attachmentPath?: string;
  queuedAt: string;
}
```

### 2.4. `uiStore`

```typescript
// src/store/uiStore.ts
/**
 * @file uiStore.ts
 * @path src/store/uiStore.ts
 * @description Stan UI: theme, modalne, loading, preferencje sortowania.
 * @exports useUiStore
 * @dependsOn src/types/index.ts
 */
interface UiState {
  theme: 'light' | 'dark' | 'system';
  resolvedTheme: 'light' | 'dark';      // po rozwiązaniu 'system'
  isOnline: boolean;
  activeModal: ModalConfig | null;
  toasts: Toast[];
  uiPrefs: UiPreferences;               // sortowanie, filtry — persystowane
  seenTooltips: SeenTooltips;           // które tooltips zostały już pokazane
}
```

---

## 3. Offline mode

### 3.1. Wykrywanie stanu sieci

```typescript
// src/contexts/NetworkContext.tsx
/**
 * @file NetworkContext.tsx
 * @path src/contexts/NetworkContext.tsx
 * @description Kontekst stanu sieci — online/offline, auto-reconnect.
 * @exports NetworkProvider, useNetwork
 * @dependsOn src/store/uiStore.ts
 */
import NetInfo from '@react-native-community/netinfo';

export const NetworkProvider = ({ children }: { children: React.ReactNode }) => {
  const { setOnline } = useUiStore();

  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener(state => {
      const online = state.isConnected ?? false;
      setOnline(online);

      if (online) {
        // Reconnect: flush offline queue, refresh realtime subscriptions
        flushOfflineQueue();
        resubscribeRealtime();
      }
    });
    return unsubscribe;
  }, []);

  return <>{children}</>;
};
```

### 3.2. Offline banner

Gdy `isOnline === false`, wyświetlamy persystentny banner na górze ekranu:

```
┌──────────────────────────────────────────────────────┐
│  📡 Brak połączenia — wiadomości zostaną wysłane     │
│     automatycznie po przywróceniu połączenia         │
└──────────────────────────────────────────────────────┘
```

Komponent: `src/components/shared/OfflineBanner.tsx`

### 3.3. Offline queue — wysyłanie wiadomości bez sieci

```typescript
// src/hooks/useMessages.ts — fragment

const sendMessage = async (content: string): Promise<void> => {
  const localId = generateUUID();

  // 1. Natychmiast dodaj do pendingMessages (optymistyczna aktualizacja)
  addPendingMessage({ localId, channelId, content, status: 'sending' });

  if (!isOnline) {
    // 2a. Offline — dodaj do kolejki, pokaż info
    addToOfflineQueue({ localId, channelId, content });
    updatePendingStatus(localId, 'failed');
    showToast({ type: 'info', message: t('errors.queued_offline') });
    return;
  }

  try {
    // 2b. Online — wyślij przez Edge Function moderacji
    const result = await moderateAndSend({ content, channelId });

    if (result.decision === 'approve') {
      removePendingMessage(localId);  // serwer wyemituje przez Realtime
    } else if (result.decision === 'review') {
      updatePendingStatus(localId, 'moderating');
      showToast({ type: 'info', message: t('message.moderation.pending') });
    } else {
      removePendingMessage(localId);
      showToast({ type: 'error', message: t('message.moderation.rejected') });
    }
  } catch (error) {
    logger.error('sendMessage failed', { error, channelId });
    updatePendingStatus(localId, 'failed');
    showToast({
      type: 'error',
      message: t('message.send.failed'),
      action: { label: t('common.retry'), onPress: () => sendMessage(content) },
    });
  }
};
```

### 3.4. Flush offline queue po reconnect

```typescript
// src/lib/offlineQueue.ts
export const flushOfflineQueue = async (): Promise<void> => {
  const queue = useMessageStore.getState().offlineQueue;
  if (!queue.length) return;

  logger.info('Flushing offline queue', { count: queue.length });

  for (const item of queue) {
    try {
      await moderateAndSend({ content: item.content, channelId: item.channelId });
      removeFromOfflineQueue(item.localId);
    } catch (error) {
      logger.warn('Offline queue item failed', { localId: item.localId, error });
      // Zostaje w kolejce — spróbujemy następnym razem
    }
  }
};
```

---

## 4. Optymistyczne aktualizacje

### 4.1. Zasada

Każda akcja użytkownika natychmiast aktualizuje UI lokalnie — nie czeka na odpowiedź serwera. Jeśli serwer zwróci błąd, stan jest cofany (rollback).

```
Użytkownik wysyła wiadomość
    │
    ├─► [NATYCHMIAST] Wiadomość pojawia się w UI (dimmed, ze spinnerem)
    │
    ├─► Serwer potwierdza
    │       │
    │   OK ─┴─► Wiadomość "rozjaśniona", spinner znika, Realtime ją odświeża
    │   ERR ────► Wiadomość znika, toast z błędem + przycisk "Spróbuj ponownie"
```

### 4.2. Wzorzec — optymistyczne like/read

```typescript
// Oznaczanie kanału jako przeczytanego — natychmiastowe, bez czekania
const markChannelRead = (channelId: string) => {
  // 1. Lokalnie — od razu (UI)
  setUnreadCount(channelId, 0);

  // 2. Serwer — fire and forget (nie blokuje UI)
  supabase
    .from('channel_reads')
    .upsert({ channel_id: channelId, profile_id: userId, read_at: new Date().toISOString() })
    .then(({ error }) => {
      if (error) logger.warn('markChannelRead sync failed', { channelId, error });
      // Nie cofamy — dla "read" optymizm jest zawsze bezpieczny
    });
};
```

---

## 5. Realtime subscriptions — zarządzanie

### 5.1. Jeden subscriber per kanał

```typescript
// src/hooks/useChannelMessages.ts
useEffect(() => {
  if (!channelId) return;

  const subscription = supabase
    .channel(`messages:${channelId}`)
    .on('postgres_changes', {
      event: 'INSERT',
      schema: 'public',
      table: 'messages',
      filter: `channel_id=eq.${channelId}`,
    }, (payload) => {
      const newMessage = payload.new as Message;
      // Ignoruj wiadomości pending (już je mamy lokalnie)
      if (newMessage.moderation_status === 'approved') {
        addMessage(channelId, newMessage);
        removePendingMessage(newMessage.id); // usuń optimistic jeśli istnieje
      }
    })
    .subscribe();

  // KRYTYCZNE: cleanup przy unmount
  return () => {
    supabase.removeChannel(subscription);
  };
}, [channelId]);
```

### 5.2. Reconnect po utracie połączenia

Supabase Realtime automatycznie próbuje reconnectować, ale subskrypcje mogą wymagać odświeżenia:

```typescript
// src/lib/supabase/client.ts
export const supabase = createClient(url, anonKey, {
  realtime: {
    params: {
      eventsPerSecond: 10,
    },
    reconnectAfterMs: (tries) => Math.min(tries * 1000, 10000), // max 10s
  },
});
```

---

## 6. Konflikty sesji między urządzeniami

### 6.1. Scenariusz: użytkownik zalogowany na telefonie i tablecie

```
Telefon (trusted):     sesja aktywna, brak timeoutu
Tablet szkolny (untrusted): sesja wygasa po 4h bezczynności

Serwer (Supabase Auth): jeden refresh token per urządzenie
```

Supabase Auth obsługuje multi-device natively — każde urządzenie ma osobny `refresh_token`. Wylogowanie z jednego urządzenia nie wylogowuje z innych (chyba że wywołamy `signOut({ scope: 'global' })`).

### 6.2. Scenariusz: force logout ze zdalnego urządzenia

Gdy użytkownik odwołuje urządzenie z panelu Settings:

```typescript
// src/lib/auth/session.ts
export const revokeDevice = async (deviceId: string): Promise<Result<void, AppError>> => {
  try {
    // 1. Usuń push token (urządzenie nie będzie dostawać powiadomień)
    await supabase.from('devices').update({ push_token: null, is_trusted: false })
      .eq('id', deviceId);

    // 2. Oznacz sesję jako unieważnioną (na urządzeniu sprawdzone przy kolejnym requestcie)
    await supabase.from('devices').delete().eq('id', deviceId);

    // 3. Na samym urządzeniu (jeśli to aktywna sesja) — sprawdzone przez useAuth hook
    // przy każdym uruchomieniu app porównujemy device_id z tabelą devices

    logger.info('Device revoked', { deviceId });
    return { ok: true, value: undefined };
  } catch (error) {
    logger.error('revokeDevice failed', { deviceId, error });
    return { ok: false, error: toAppError(error) };
  }
};
```

### 6.3. Detekcja odwołanego urządzenia

```typescript
// src/hooks/useAuth.ts — sprawdzane przy każdym foreground
const checkDeviceValidity = async () => {
  const deviceId = await SecureStore.getItemAsync('device_id');
  if (!deviceId) return;

  const { data } = await supabase
    .from('devices')
    .select('id')
    .eq('id', deviceId)
    .single();

  if (!data) {
    // Urządzenie zostało odwołane — wyloguj
    logger.warn('Device revoked remotely, signing out');
    await signOut();
    showToast({ type: 'warning', message: t('auth.device_revoked') });
  }
};
```

---

## 7. Paginacja wiadomości

### 7.1. Cursor-based pagination (nie offset)

```typescript
// src/lib/supabase/queries/messages.ts
export const fetchMessages = async (
  channelId: string,
  cursor?: string,   // ostatni message.id z poprzedniej strony
  limit = 50,
): Promise<Result<Message[], AppError>> => {
  try {
    let query = supabase
      .from('messages')
      .select('*, profiles!sender_id(display_name, avatar_url), attachments(*)')
      .eq('channel_id', channelId)
      .in('moderation_status', ['approved', 'trimmed'])
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (cursor) {
      // Pobierz wiadomości starsze niż cursor
      query = query.lt('id', cursor);
    }

    const { data, error } = await query;
    if (error) throw error;

    return { ok: true, value: data ?? [] };
  } catch (error) {
    logger.error('fetchMessages failed', { channelId, error });
    return { ok: false, error: toAppError(error) };
  }
};
```

### 7.2. Infinite scroll w FlatList

```typescript
// W komponencie kanału:
const handleLoadMore = () => {
  if (!hasMore[channelId] || isLoadingMore) return;
  const oldestMessage = messages[channelId]?.at(-1);
  if (oldestMessage) fetchMoreMessages(channelId, oldestMessage.id);
};

<FlatList
  data={messages[channelId]}
  inverted                          // najnowsze na dole
  onEndReached={handleLoadMore}
  onEndReachedThreshold={0.3}       // załaduj więcej gdy 30% od końca
  ListFooterComponent={isLoadingMore ? <Skeleton /> : null}
  keyExtractor={(item) => item.id}
/>
```

---

## 8. Persystencja stanu między sesjami

### 8.1. Co jest persystowane

| Dane | Gdzie | Szyfrowanie |
|------|-------|-------------|
| Token sesji (JWT) | `expo-secure-store` | ✅ Keychain/Keystore |
| Refresh token | `expo-secure-store` | ✅ Keychain/Keystore |
| Device ID | `expo-secure-store` | ✅ Keychain/Keystore |
| Biometric preference | `expo-secure-store` | ✅ Keychain/Keystore |
| UI preferences (sortowanie, theme) | Supabase `profiles.settings` | Na serwerze |
| Seen tooltips | Supabase `profiles.settings` | Na serwerze |
| Offline queue | `expo-secure-store` | ✅ (małe dane, max 20 wiadomości) |
| In-app logs (warn/error) | `expo-secure-store` | ✅ (max 100 wpisów) |

### 8.2. Co NIE jest persystowane lokalnie

- Treść wiadomości (zawsze fetchowana z Supabase)
- Pliki / attachmenty (Supabase Storage URL)
- Pełna lista członków klasy
- Kolejka moderacji

---

## 9. Inicjalizacja aplikacji — boot sequence

```
App uruchamia się
    │
    1. SplashScreen widoczny (expo-splash-screen)
    │
    2. Sprawdź token sesji w SecureStore
    │       │
    │   brak ─────────────────────────────────────► Ekran logowania
    │   jest ─┐
    │         │
    3.        Sprawdź czy device_id istnieje w tabeli devices (Supabase)
    │         │
    │     brak ──────────────────────────────────► Wyloguj (urządzenie odwołane)
    │     jest ─┐
    │           │
    4.          Odśwież profil użytkownika (display_name, settings, plan)
    │           │
    5.          Zasubskrybuj Realtime dla aktywnych klas
    │           │
    6.          Sprawdź offline queue → jeśli online: flush
    │           │
    7.          SplashScreen ukryty
    │           │
    └───────────┴────────────────────────────────► Main app (lista klas)
```

Implementacja w `src/app/_layout.tsx` — główny layout Expo Router.
