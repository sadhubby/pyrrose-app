# backend/

There is no server code — **Supabase is the backend** (Postgres + Storage + RLS).

## Contents

- `supabase/migrations/0001_init.sql` — `bouquets` table + anon read/insert policies.

## Applying migrations (Phase 5, once your Supabase project exists)

**Option A — Dashboard**

1. Create a project at https://supabase.com (free tier is enough).
2. Open **SQL Editor**, paste `supabase/migrations/0001_init.sql`, run.

**Option B — CLI**

```sh
npm i -g supabase
supabase login
supabase link --project-ref <your-project-ref>
supabase db push
```

## Wiring the app

Pass credentials at build/run time (see `app/lib/core/config/app_config.dart`):

```sh
flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=<anon key> \
            --dart-define=WEB_VIEWER_BASE_URL=https://sadhubby.github.io/pyrrose-app/viewer
```

The anon key is public by design (it ships in clients); RLS is what keeps data safe.

## Future (Phase 6+)

Media attachments (voice/video) go to Supabase Storage. If outgrowing it,
a Cloudflare R2 worker could serve heavy media instead — this folder would
then hold that worker's code.
