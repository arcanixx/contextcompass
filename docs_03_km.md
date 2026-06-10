# 03_AI_RULES.md
# Path: docs/03_AI_RULES.md
# Purpose: Rules and constraints for AI coding assistants working on this project
# Depends on: 00_PROJECT_OVERVIEW.md, 01_ARCHITECTURE.md, 02_CODE_STANDARDS.md

---

# KlassMate — AI Coding Assistant Rules

> This file is the **first thing any AI assistant must read** before writing any code.
> These rules exist to prevent the most common failure modes when AI generates code for this project.

---

## 🔴 NEVER DO — Hard Prohibitions

### Architecture
- **NEVER** use `any` in TypeScript. Use `unknown` and narrow, or define a proper type.
- **NEVER** import from another store directly inside a store. Use selectors or pass values via hooks.
- **NEVER** create barrel `index.ts` files that re-export everything from a folder unless explicitly instructed.
- **NEVER** write a file longer than 200 lines. Split it before it gets there.
- **NEVER** put business logic inside a screen/page component. Logic goes in hooks (`useXxx.ts`).
- **NEVER** access `supabase` client directly from a component. Always go through a hook or lib function.
- **NEVER** store API keys or secrets in source code or `.env.development` files committed to git.
- **NEVER** hardcode strings visible to the user. Use `t('key')` from i18next.
- **NEVER** hardcode icon names as string literals in components. Use `ICONS.xxx` from constants.
- **NEVER** hardcode hex color values in components. Use theme tokens from `constants/colors.ts`.
- **NEVER** hardcode pixel/size values that belong in `constants/spacing.ts`.
- **NEVER** write a SQL migration that does a hard `DELETE` on user content tables. Use soft delete (`deleted_at`).
- **NEVER** skip RLS policies on a new table. Every table must have RLS enabled and explicit policies.
- **NEVER** use the Supabase service role key on the client side. It belongs only in Edge Functions.

### Safety & Children
- **NEVER** store a user's full birth date. Store only `birth_year` for age category checks.
- **NEVER** send user content (message text, images) to external third-party APIs without going through a server-side Edge Function.
- **NEVER** allow image sending in Direct Messages (DM). Text and voice only in DMs.
- **NEVER** bypass the moderation Edge Function for any message type, including DMs.
- **NEVER** show rejected message content to anyone other than class admins in the moderation queue.

### Debug / Dev
- **NEVER** leave `console.log` statements in production code paths. Use `logger.debug()` which is stripped in production.
- **NEVER** enable debug panels, mock screens, or seed data in production builds. Guard with `__DEV__ && FEATURES.DEBUG_PANEL`.
- **NEVER** commit `.env.development` or `.env.production` files with real values.

---

## 🟢 ALWAYS DO — Mandatory Practices

### Every file
- **ALWAYS** write the file header block (see `02_CODE_STANDARDS.md` section 2) at the top of every `.ts` / `.tsx` file.
- **ALWAYS** use named exports for types, default export for the main component.

### TypeScript
- **ALWAYS** type all function parameters and return values explicitly.
- **ALWAYS** use `Result<T, E>` pattern for async operations that can fail.
- **ALWAYS** use `satisfies` operator when validating config objects.

### Error handling
- **ALWAYS** wrap async Supabase calls in `try/catch`.
- **ALWAYS** log errors via `logger.error()` with context (what failed, relevant IDs).
- **ALWAYS** return user-friendly error messages via i18n keys, never raw error messages.
- **ALWAYS** handle the offline/network-unavailable case for all network operations.

### Components
- **ALWAYS** wrap list-rendering components in `React.memo`.
- **ALWAYS** use `useCallback` for event handlers passed as props to list items.
- **ALWAYS** provide a loading state (Skeleton component) and an empty state (EmptyState component).
- **ALWAYS** provide accessible labels (`accessibilityLabel`, `accessibilityHint`) on interactive elements.
- **ALWAYS** add a `displayName` to memoised components for easier debugging.

### Biometrics & Auth
- **ALWAYS** offer biometric unlock (Face ID / Touch ID / Fingerprint) as an option on supported devices after the first successful login.
- **ALWAYS** fall back gracefully to PIN/password if biometrics are unavailable or fail.
- **ALWAYS** store the biometric preference in the device keychain, never in AsyncStorage.
- **ALWAYS** re-authenticate biometrically (or via password) before any sensitive action: changing email, deleting account, exporting data, revoking trusted device.

### UX — Help System
- **ALWAYS** add a `tooltip` or `accessibilityHint` to any UI element that is not immediately self-explanatory.
- **ALWAYS** add Toast feedback for every user action (send message, upload file, save note, block user, etc.).
- **ALWAYS** add a contextual help icon (?) next to admin-only features (moderation queue, member approval).
- **ALWAYS** implement error toasts that suggest an action ("Spróbuj ponownie", "Sprawdź połączenie").

### i18n
- **ALWAYS** add translation keys to both `pl.json` AND `en.json` at the same time.
- **ALWAYS** use `t('key', { count })` for pluralisation, never string concatenation.

### Testing
- **ALWAYS** write a unit test for every new utility function in `utils/`.
- **ALWAYS** write an integration test for every new Supabase query function in `lib/supabase/queries/`.
- **ALWAYS** mock Supabase calls in tests using the mock client in `__tests__/mocks/supabase.mock.ts`.

### Database
- **ALWAYS** add `updated_at` trigger to every table that has an `updated_at` column.
- **ALWAYS** create an index on foreign key columns and any column used in WHERE clauses.
- **ALWAYS** write migrations as incremental files, never modify existing migration files.

---

## 🟡 BE CAREFUL — Common Mistakes

- **Realtime subscriptions** must be unsubscribed in the hook cleanup (`useEffect` return). Leaked subscriptions cause memory issues and duplicate messages.
- **Zustand selectors** — select only what the component needs, not the whole store slice, to avoid unnecessary re-renders.
- **Expo Router params** — always validate route params before use. A missing `classId` param should redirect to home, not crash.
- **Image compression** — always compress before upload, never after. The upload size limit check happens on the client before sending.
- **Voice recording** — always request microphone permission before showing the recorder UI. Handle "denied" gracefully with a toast + link to system settings.
- **Push notifications** — always request permission, handle "denied" gracefully (don't spam the user with re-requests). Permission state is stored in the user's `settings` JSONB.
- **Screenshot prevention** — this is best-effort only on iOS (detection, not blocking). On Android, `FLAG_SECURE` prevents screenshots. On web — impossible. Do not promise full prevention to users; use softer language: "Staramy się chronić zawartość ekranu".
- **Biometrics on web** — Web Authn is available on web but has different UX. On web, skip biometric prompt and use session-based auth only. The biometric flow is mobile-only.
- **OCR** — Tesseract.js is large (~10 MB WASM). Load it lazily only when the Notes module is opened. Never import it at app startup.
- **DM moderation** — DMs go through the same Edge Function as channel messages, but the moderation result is NOT visible to class admins. Only the system acts on DM violations (auto-reject). A user can report a DM separately.

---

## 📋 Feature Flag Checklist

Before implementing any new feature, check `src/config/features.config.ts`.

If the feature has a flag set to `false`:
- Implement the feature fully
- Gate the UI with `{FEATURES.MY_FEATURE && <MyFeature />}`
- Gate the route with an early return redirect if navigated to directly
- Do NOT skip implementation — features with `false` flags are "built but not released"

If the feature is `DEV_ONLY` (has `__DEV__ &&`):
- The feature must be completely absent from production bundles
- Use `Platform.select` or environment checks, not just conditional rendering

---

## 📋 Pre-PR Checklist for AI

Before submitting any code:

- [ ] File header present on every new file
- [ ] No `any` types
- [ ] No hardcoded strings (checked `t()` is used)
- [ ] No hardcoded colors or icon names
- [ ] File is under 200 lines
- [ ] Error handling present for all async operations
- [ ] Logger used (not `console.log`)
- [ ] Loading + empty states present for lists/async views
- [ ] Accessibility labels on interactive elements
- [ ] i18n keys added to both `pl.json` and `en.json`
- [ ] Unit test written (or existing test updated)
- [ ] RLS policy written if new table created
- [ ] Feature flag check if applicable
- [ ] Biometric re-auth added if the action is sensitive
- [ ] Toast feedback present for user actions
