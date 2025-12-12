# FinMate – Personal Finance & Crypto Tracker (Flutter + Supabase)

FinMate helps you track cash and crypto holdings in one place. It syncs with Supabase for auth and storage, supports offline queuing for holdings changes, and surfaces your net worth and allocation on a modern dashboard.

## Tech stack
- Flutter / Dart (Material 3)
- Supabase (Postgres + Auth)
- Hive for local offline queue
- BLoC/Cubit architecture for state management

## How to run
Prerequisites: Flutter SDK, a Supabase project, Chrome.

1) Install dependencies:
```bash
flutter pub get
```
2) Run the app (web example):
```bash
flutter run -d chrome --dart-define-from-file=env/dev.json
```
`env/dev.json` must define `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

## Supabase schema (minimum)
- `auth.users` (managed by Supabase)
- `public.profiles`  
  - `id uuid primary key references auth.users`  
  - `display_name text`  
  - `base_currency text`  
  - `theme text`
- `public.holdings`  
  - `id uuid primary key`  
  - `user_id uuid references auth.users`  
  - `type text check in ('crypto','cash')`  
  - `symbol text`  
  - `quantity numeric`  
  - `cost_basis numeric`  
  - `note text`  
  - `created_at timestamptz`  
  - `updated_at timestamptz`  
- RLS enabled so each user only sees/changes their own rows.

## Main features (Sprint 1)
- Auth: Supabase email/password, login/logout, session persistence.
- Navigation & routing: Home, Auth, Dashboard, Settings, Holdings list & edit; protected routes via `RequireAuth`.
- Data management: Holdings stored in Supabase; offline queue in Hive for create/update/delete retries when back online.
- Dashboard: total net worth v0 (sum of `cost_basis`), per-type allocation (crypto vs cash), pending offline operations indicator.
- Settings: edit profile (name, base currency, theme), sign out.
- Security: automatic logout on JWT/401/forbidden errors.

## Architecture
- Domain layer: models and repository contracts.
- Data layer: Supabase implementations.
- Application layer: Cubits for dashboard, holdings, profile, auth session.
- Presentation layer: Flutter pages/widgets (dashboard, holdings list/edit, settings, etc.).

## Screenshots (placeholders)
- Dashboard view
- Holdings list and edit
- Settings/profile
