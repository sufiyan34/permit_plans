# WorkBridge AI Edge Function

This function authenticates the caller with their Supabase JWT, reads their
protected `user_roles` record, enforces the per-user request quota from
migration `022_workbridge_ai_assistant_limits.sql`, and then calls OpenAI's
Responses API from the server.

## Required secret

Set `OPENAI_API_KEY` as a Supabase Edge Function Secret. `OPENAI_MODEL` is
optional and defaults to `gpt-6-luna`.

Do not put the OpenAI key in Flutter/Dart code, `--dart-define`, app assets, or
any client-side `.env` file.

## Deploy

Supabase CLI expects Edge Functions under the repository's root `supabase/`
directory by default. This uploaded project snapshot stores Supabase files
under `lib/supabase/` because the supplied archive was a `lib/` snapshot. Before
using the CLI, copy this function folder to:

`<project-root>/supabase/functions/workbridge-ai/`

and copy migration `022_workbridge_ai_assistant_limits.sql` to:

`<project-root>/supabase/migrations/`

Then, from the Flutter project root:

```bash
supabase functions deploy workbridge-ai
```

Set the production secret in Supabase Dashboard → Edge Functions → Secrets:

- `OPENAI_API_KEY` = your OpenAI API key
- `OPENAI_MODEL` = `gpt-6-luna` (optional)

For local Edge Function development, put the real key in the root
`supabase/functions/.env` file (not `.env.example`), add `.env` to `.gitignore`,
and run:

```bash
supabase functions serve workbridge-ai --env-file supabase/functions/.env
```

Apply migration 022 in the database before testing. The function allows only
signed-in users with a `client`, `engineer`, or `admin` role. It accepts up to
12 recent text messages, 3,000 characters each, and allows up to 10 requests
per user per minute. It does not read project/account records or process
attachments. Chat history remains local to the current widget session and is
not saved in Supabase by this first integration.
