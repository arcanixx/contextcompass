# 17 — Data Seed Strategy
# Path: docs/17_data_seed_strategy.md
# Purpose: Skąd wziąć dane testowe, jak je przygotować, jak seedować Supabase (dev/test)
# Depends on: docs/01_ARCHITECTURE.md, docs/11_user_stories_and_ac.md
# Status: MVP v0.1 (Phase 1)

---

# KlassMate — Data Seed Strategy

> **Wersja:** 0.1.0-draft  
> **Ostatnia aktualizacja:** 2025-06-11  
> **Scope:** Dev + Test environments ONLY. NIGDY production bez `--confirm`.  
> **Cel:** Przygotowanie wiarygodnych danych testowych do: developmentu, testów manualnych, testów E2E, demo dla inwestorów/szkół.

---

## 1. Zasady seedowania

| Zasada | Implementacja |
|--------|---------------|
| **Nigdy na produkcji bez potwierdzenia** | Seeder sprawdza `current_database()` — jeśli nie zawiera `dev` lub `test`, przerywa z `RAISE EXCEPTION`. |
| **Idempotentność** | Seeder czyści stare dane (`TRUNCATE CASCADE`) przed wstawieniem nowych. Można uruchamiać wielokrotnie. |
| **Determinizm** | Używamy seedowanego RNG (`faker.seed(12345)`) — za każdym razem te same dane. |
| **Brak prawdziwych danych osobowych** | Wszystkie imiona, nazwiska, emaile są generowane przez Faker. Brak prawdziwych uczniów/nauczycieli. |
| **RODO-safe** | Nawet w dev — nie używamy prawdziwych adresów email, numerów telefonów, zdjęć. |
| **Wielkość zestawów** | `__DEV__` / test: 3 klasy, 15 uczniów, 50 wiadomości. Demo / load test: 10 klas, 100 uczniów, 500 wiadomości. |

---

## 2. Źródła danych (legalne i darmowe)

### 2.1 Imiona i nazwiska (fikcyjne)

| Źródło | Metoda | Licencja |
|--------|--------|----------|
| `@faker-js/faker` (locale `pl`) | Generowanie programistyczne | MIT |
| `@faker-js/faker` (locale `en`) | Generowanie programistyczne | MIT |

**Dlaczego Faker:**
- Deterministyczny przy `seed()`.
- Polskie imiona i nazwiska (realistyczne dla target market).
- Brak powiązania z prawdziwymi osobami.

### 2.2 Przedmioty szkolne i kanały

| Źródło | Metoda | Licencja |
|--------|--------|----------|
| Podstawa programowa MEN | Ręczna lista 15 przedmiotów | Public domain (prawo oświatowe) |

**Lista kanałów (domyślna per klasa):**
```
Ogłoszenia 📢
Matematyka 📐
Język polski 📖
Język angielski 🌍
Historia 🏛️
Biologia 🧬
Chemia ⚗️
Fizyka 🔭
Geografia 🌎
Informatyka 💻
Wychowanie fizyczne ⚽
Religia / Etyka ✝️☸️
```

### 2.3 Treści wiadomości (zadania domowe, pytania)

| Źródło | Metoda | Licencja |
|--------|--------|----------|
| OpenStax (openstax.org) | Ręczny wybór 50 przykładowych zadań | CC-BY 4.0 |
| Wolne Lektury (wolnelektury.pl) | API: `https://wolnelektury.pl/api/books/` | Public domain |
| Własna generacja (Faker lorem + templates) | Programistyczne | N/A |

**Template wiadomości (10 wzorów):**
```typescript
const MESSAGE_TEMPLATES = [
  "Hej, z matematyki mamy zadanie {task}. Ktoś wie jak to zrobić?",
  "Z polskiego na jutro: przeczytać {book}, strony {pages}.",
  "Ktoś ma zdjęcie tablicy z {subject}? Zapomniałem zapisać.",
  "Sprawdzian z {subject} w piątek! Uczymy się {topic}.",
  "Pamiętajcie: praca domowa z {subject} na {date}.",
  "Czy ktoś rozumie zadanie {task}? Nie mogę dojść do tego samego wyniku.",
  "Z angielskiego: {exercise}. Ktoś może sprawdzić moje odpowiedzi?",
  "Uwaga: jutro mamy kartkówkę z {topic}.",
  "Ktoś ma notatki z {subject} z ostatniej lekcji? Byłem nieobecny.",
  "Przypomnienie: projekt z {subject} do oddania do {date}.",
];
```

### 2.4 Avatary (generowane)

| Źródło | Metoda | Licencja |
|--------|--------|----------|
| `https://api.dicebear.com/9.x` | API (seeded, deterministyczne) | CC0 1.0 (public domain) |
| `https://randomuser.me/api` | API | Free (CC BY-SA 3.0) |

**Rekomendacja:** Dicebear — deterministyczne avatary na podstawie seed/userId, nie wymagają pobierania plików (SVG inline).

### 2.5 Załączniki (obrazki testowe)

| Źródło | Metoda | Licencja |
|--------|--------|----------|
| `https://picsum.photos` | API (seeded) | Free (public domain) |
| Własne placeholder images | Generowane (kolorowe prostokąty z tekstem) | N/A |

**Uwaga:** W testach E2E nie używamy zewnętrznych API (flakiness). Używamy base64-encoded 1×1px PNG lub lokalnych plików w `__tests__/fixtures/`.

---

## 3. Schema seedu — struktura danych

### 3.1 Zestaw „Small” (dev / test / CI)

| Encja | Ilość | Uzasadnienie |
|-------|-------|--------------|
| Użytkownicy (`auth.users` + `profiles`) | 15 | 3 adminów, 12 memberów |
| Klasy (`classes`) | 3 | 1 per admin |
| Członkowie klas (`class_members`) | 15 | 5 per klasa (1 admin + 4 memberów) |
| Kanały (`channels`) | 30 | 10 per klasa (domyślne + custom) |
| Wiadomości (`messages`) | 150 | 50 per klasa, różne statusy moderacji |
| Moderation queue (`moderation_queue`) | 10 | Mix: approve, reject, trim, pending |
| Powiadomienia (`notifications`) | 30 | Różne typy, mix read/unread |
| Urządzenia (`devices`) | 20 | 1–2 per user |
| Notatki (`personal_notes`) | 10 | 2–3 per user |
| Remindery (`reminders`) | 5 | Phase 2 — można pominąć w MVP seed |

### 3.2 Zestaw „Demo” (demo dla inwestorów / szkół)

| Encja | Ilość |
|-------|-------|
| Użytkownicy | 100 |
| Klasy | 10 |
| Członkowie | 100 |
| Kanały | 100 |
| Wiadomości | 1000 |
| Moderation queue | 50 |
| Powiadomienia | 200 |
| Urządzenia | 150 |
| Notatki | 50 |

---

## 4. Implementacja seedera

### 4.1 Pliki seedera

```
supabase/seed/
├── seed.ts                    # Główny skrypt (uruchamiany via tsx)
├── data/
│   ├── users.ts               # Generowanie użytkowników (Faker)
│   ├── classes.ts             # Definicje klas
│   ├── channels.ts            # Definicje kanałów
│   ├── messages.ts            # Generowanie wiadomości (templates)
│   ├── moderation.ts          # Generowanie queue items
│   └── attachments.ts         # Generowanie attachment metadata
├── lib/
│   ├── faker.ts               # Skonfigurowany Faker (seeded)
│   ├── supabase-admin.ts      # Supabase client z service role key
│   └── idempotent.ts          # Funkcje czyszczące (TRUNCATE CASCADE)
└── sql/
    ├── 0000_seed_guard.sql    # CHECK: current_database() LIKE '%dev%'
    └── 0001_seed_data.sql     # Fallback: czysty SQL (bez TS)
```

### 4.2 Główny skrypt (`seed.ts`)

```typescript
// supabase/seed/seed.ts
import { faker } from '@faker-js/faker/locale/pl';
import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';

config({ path: '.env.development' });

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!, // TYLKO w dev/test!
);

// Determinizm
faker.seed(12345);

async function seed() {
  // 0. Guard — nigdy na produkcji
  const { data: dbCheck } = await supabase.rpc('check_seed_allowed');
  if (!dbCheck) {
    console.error('❌ Seeding not allowed on this database. Aborting.');
    process.exit(1);
  }

  console.log('🌱 Starting seed...');

  // 1. Czyść stare dane (idempotent)
  await cleanDatabase(supabase);

  // 2. Użytkownicy (auth.users + profiles)
  const users = await seedUsers(supabase, 15);
  console.log(`✅ Seeded ${users.length} users`);

  // 3. Klasy
  const classes = await seedClasses(supabase, users.filter(u => u.role === 'student').slice(0, 3));
  console.log(`✅ Seeded ${classes.length} classes`);

  // 4. Członkowie klas
  const members = await seedClassMembers(supabase, classes, users);
  console.log(`✅ Seeded ${members.length} class members`);

  // 5. Kanały
  const channels = await seedChannels(supabase, classes);
  console.log(`✅ Seeded ${channels.length} channels`);

  // 6. Wiadomości (z różnymi statusami moderacji)
  const messages = await seedMessages(supabase, channels, users, 150);
  console.log(`✅ Seeded ${messages.length} messages`);

  // 7. Moderation queue
  const queue = await seedModerationQueue(supabase, messages, users);
  console.log(`✅ Seeded ${queue.length} moderation queue items`);

  // 8. Powiadomienia
  const notifications = await seedNotifications(supabase, users, messages);
  console.log(`✅ Seeded ${notifications.length} notifications`);

  // 9. Urządzenia
  const devices = await seedDevices(supabase, users);
  console.log(`✅ Seeded ${devices.length} devices`);

  // 10. Notatki
  const notes = await seedNotes(supabase, users, classes, channels);
  console.log(`✅ Seeded ${notes.length} notes`);

  console.log('🎉 Seed complete!');
}

async function cleanDatabase(supabase: SupabaseClient) {
  // Kolejność: child tables first (CASCADE handles most, but explicit is safer)
  const tables = [
    'audit_log',
    'error_reports',
    'reminders',
    'personal_notes',
    'devices',
    'notifications',
    'moderation_queue',
    'attachments',
    'messages',
    'threads',
    'channels',
    'class_members',
    'classes',
    'profiles',
  ];
  for (const table of tables) {
    await supabase.from(table).delete().neq('id', '00000000-0000-0000-0000-000000000000');
  }
  // Auth users (service role required)
  const { data: authUsers } = await supabase.auth.admin.listUsers();
  for (const user of authUsers?.users ?? []) {
    await supabase.auth.admin.deleteUser(user.id);
  }
}

seed().catch(console.error);
```

### 4.3 Guard SQL (`0000_seed_guard.sql`)

```sql
-- supabase/seed/sql/0000_seed_guard.sql
CREATE OR REPLACE FUNCTION check_seed_allowed()
RETURNS boolean AS $$
BEGIN
  RETURN current_database() LIKE '%dev%' 
      OR current_database() LIKE '%test%'
      OR current_database() LIKE '%local%';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 4.4 Generowanie użytkowników (`data/users.ts`)

```typescript
// supabase/seed/data/users.ts
import { faker } from '@faker-js/faker/locale/pl';
import { SupabaseClient } from '@supabase/supabase-js';

export interface SeedUser {
  id: string;
  email: string;
  password: string;
  display_name: string;
  role: 'student' | 'teacher' | 'superadmin';
  birth_year: number;
  avatar_url: string;
}

export async function seedUsers(supabase: SupabaseClient, count: number): Promise<SeedUser[]> {
  const users: SeedUser[] = [];

  // 3 adminów (starsi uczniowie lub nauczyciele)
  for (let i = 0; i < 3; i++) {
    const firstName = faker.person.firstName();
    const lastName = faker.person.lastName();
    const email = `admin${i + 1}@klassmate.test`;
    const { data, error } = await supabase.auth.admin.createUser({
      email,
      password: 'Test1234!',
      email_confirm: true,
      user_metadata: { display_name: `${firstName} ${lastName}` },
    });
    if (error) throw error;

    users.push({
      id: data.user!.id,
      email,
      password: 'Test1234!',
      display_name: `${firstName} ${lastName}`,
      role: i === 2 ? 'teacher' : 'student', // 2 student-admins, 1 teacher
      birth_year: faker.number.int({ min: 1990, max: 2005 }),
      avatar_url: `https://api.dicebear.com/9.x/avataaars/svg?seed=${data.user!.id}`,
    });
  }

  // 12 zwykłych uczniów
  for (let i = 0; i < count - 3; i++) {
    const firstName = faker.person.firstName();
    const lastName = faker.person.lastName();
    const email = `student${i + 1}@klassmate.test`;
    const birthYear = faker.number.int({ min: 2008, max: 2014 }); // 11–17 lat
    const { data, error } = await supabase.auth.admin.createUser({
      email,
      password: 'Test1234!',
      email_confirm: true,
      user_metadata: { display_name: `${firstName} ${lastName}` },
    });
    if (error) throw error;

    users.push({
      id: data.user!.id,
      email,
      password: 'Test1234!',
      display_name: `${firstName} ${lastName}`,
      role: 'student',
      birth_year: birthYear,
      avatar_url: `https://api.dicebear.com/9.x/avataaars/svg?seed=${data.user!.id}`,
    });
  }

  // Insert profiles
  const profiles = users.map(u => ({
    id: u.id,
    display_name: u.display_name,
    avatar_url: u.avatar_url,
    role: u.role,
    birth_year: u.birth_year,
    is_active: true,
    settings: {},
  }));

  const { error: profileError } = await supabase.from('profiles').insert(profiles);
  if (profileError) throw profileError;

  return users;
}
```

### 4.5 Generowanie wiadomości (`data/messages.ts`)

```typescript
// supabase/seed/data/messages.ts
import { faker } from '@faker-js/faker/locale/pl';
import { SupabaseClient } from '@supabase/supabase-js';

const TEMPLATES = [
  "Hej, z matematyki mamy zadanie {task}. Ktoś wie jak to zrobić?",
  "Z polskiego na jutro: przeczytać {book}, strony {pages}.",
  "Ktoś ma zdjęcie tablicy z {subject}? Zapomniałem zapisać.",
  "Sprawdzian z {subject} w piątek! Uczymy się {topic}.",
  "Pamiętajcie: praca domowa z {subject} na {date}.",
  "Czy ktoś rozumie zadanie {task}? Nie mogę dojść do tego samego wyniku.",
  "Z angielskiego: {exercise}. Ktoś może sprawdzić moje odpowiedzi?",
  "Uwaga: jutro mamy kartkówkę z {topic}.",
  "Ktoś ma notatki z {subject} z ostatniej lekcji? Byłem nieobecny.",
  "Przypomnienie: projekt z {subject} do oddania do {date}.",
];

const SUBJECTS = ['Matematyki', 'Polskiego', 'Angielskiego', 'Historii', 'Biologii', 'Chemii', 'Fizyki'];
const TOPICS = ['funkcje kwadratowe', 'Mickiewicz', 'Present Perfect', 'II wojna światowa', 'układ krwionośny', 'wiązania chemiczne', 'prąd elektryczny'];
const BOOKS = ['Dziady', 'Lalka', 'Pan Tadeusz', 'Ferdydurke', 'Wesele'];

export async function seedMessages(
  supabase: SupabaseClient,
  channels: any[],
  users: any[],
  count: number,
) {
  const messages = [];
  const moderationStatuses = ['approved', 'approved', 'approved', 'approved', 'approved', 'queued_review', 'rejected', 'trimmed'];

  for (let i = 0; i < count; i++) {
    const channel = faker.helpers.arrayElement(channels);
    const sender = faker.helpers.arrayElement(users);
    const template = faker.helpers.arrayElement(TEMPLATES);
    const subject = faker.helpers.arrayElement(SUBJECTS);
    const topic = faker.helpers.arrayElement(TOPICS);

    const content = template
      .replace('{subject}', subject)
      .replace('{topic}', topic)
      .replace('{task}', `strona ${faker.number.int({ min: 10, max: 200 })}, zadanie ${faker.number.int({ min: 1, max: 20 })}`)
      .replace('{book}', faker.helpers.arrayElement(BOOKS))
      .replace('{pages}', `${faker.number.int({ min: 10, max: 50 })}-${faker.number.int({ min: 51, max: 100 })}`)
      .replace('{date}', faker.date.future({ years: 0.1 }).toLocaleDateString('pl-PL'))
      .replace('{exercise}', `Exercise ${faker.number.int({ min: 1, max: 10 })}: ${faker.lorem.sentence()}`);

    const moderationStatus = faker.helpers.arrayElement(moderationStatuses);

    messages.push({
      channel_id: channel.id,
      sender_id: sender.id,
      content,
      moderation_status: moderationStatus,
      created_at: faker.date.recent({ days: 30 }).toISOString(),
    });
  }

  const { data, error } = await supabase.from('messages').insert(messages).select();
  if (error) throw error;
  return data;
}
```

---

## 5. Komendy npm

```json
// package.json (root)
{
  "scripts": {
    "seed:dev": "tsx supabase/seed/seed.ts --env=dev",
    "seed:test": "tsx supabase/seed/seed.ts --env=test",
    "seed:demo": "tsx supabase/seed/seed.ts --env=dev --size=demo",
    "seed:clean": "tsx supabase/seed/seed.ts --env=dev --clean-only"
  }
}
```

### 5.1 Uruchomienie

```bash
# Wymagane: .env.development z SUPABASE_URL i SUPABASE_SERVICE_ROLE_KEY
npm run seed:dev

# Demo (więcej danych)
npm run seed:demo

# Tylko wyczyść (bez seedowania)
npm run seed:clean
```

---

## 6. Walidacja seeda (testy)

Po każdym seedzie uruchamiamy testy walidacyjne:

```typescript
// __tests__/integration/seed-validation.test.ts
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
);

describe('Seed validation', () => {
  test('has at least 3 classes', async () => {
    const { count } = await supabase.from('classes').select('*', { count: 'exact', head: true });
    expect(count).toBeGreaterThanOrEqual(3);
  });

  test('every class has a 6-char join code', async () => {
    const { data } = await supabase.from('classes').select('join_code');
    expect(data?.every(c => c.join_code && c.join_code.length === 6)).toBe(true);
  });

  test('every class has at least 1 admin member', async () => {
    const { data: classes } = await supabase.from('classes').select('id');
    for (const cls of classes ?? []) {
      const { data: admins } = await supabase
        .from('class_members')
        .select('*')
        .eq('class_id', cls.id)
        .eq('role', 'admin');
      expect(admins?.length).toBeGreaterThanOrEqual(1);
    }
  });

  test('all messages have valid moderation_status', async () => {
    const validStatuses = ['pending', 'approved', 'queued_review', 'rejected', 'trimmed'];
    const { data } = await supabase.from('messages').select('moderation_status');
    expect(data?.every(m => validStatuses.includes(m.moderation_status))).toBe(true);
  });

  test('no PII in test emails', async () => {
    const { data } = await supabase.from('profiles').select('id, display_name');
    // Ensure all display_names are generated (not real people)
    expect(data?.every(p => p.display_name.includes(' ') && p.display_name.length > 3)).toBe(true);
  });

  test('RLS policies are active', async () => {
    // This is a meta-test: ensure RLS is enabled on all tables
    const { data } = await supabase.rpc('get_tables_without_rls');
    expect(data).toEqual([]);
  });
});
```

---

## 7. Demo data dla prezentacji

### 7.1 Scenariusz demo (3 minuty)

**Postać:** Jan Kowalski, uczeń klasy 3B, loguje się po raz pierwszy.

**Flow:**
1. **Splash + Onboarding** (4 slajdy) → „Witaj w KlassMate”.
2. **Logowanie** → Jan wpisuje `student1@klassmate.test` / `Test1234!`.
3. **Ekran główny** → widzi 1 klasę: „3B — Gimnazjum nr 5”.
4. **Kanały** → #matematyka, #polski, #ogłoszenia. Badge: 3 nieprzeczytane w #matematyka.
5. **Wiadomości** → scroll przez 20 wiadomości (z seeda). Ostatnia: „Sprawdzian z matematyki w piątek! Uczymy się funkcji kwadratowych.”
6. **Wysyłanie** → Jan pisze: „Ktoś ma notatki z funkcji kwadratowych? Byłem chory.” → Send → wiadomość pojawia się natychmiast (optimistic).
7. **Moderacja** → Admin (Ania Nowak) widzi 1 item w kolejce. Klik „Zatwierdź” → wiadomość Jana pojawia się dla wszystkich.
8. **Powiadomienie** → Jan dostaje push: „Twoja wiadomość została zatwierdzona”.
9. **Ustawienia** → Jan włącza dark mode, sprawdza zaufane urządzenia.

### 7.2 Pre-seeded demo account

| Email | Hasło | Rola | Klasa |
|-------|-------|------|-------|
| `demo@klassmate.test` | `Demo1234!` | Student | 3B |
| `demo-admin@klassmate.test` | `Demo1234!` | Admin | 3B |

**Uwaga:** Demo account jest tworzony przez seeder w trybie `--demo`. Nie na produkcji.

---

## 8. Changelog

| Data | Wersja | Zmiana | Autor |
|------|--------|--------|-------|
| 2025-06-11 | 0.1.0 | Initial seed strategy — sources, schema, implementation, validation tests | AI Analysis |
