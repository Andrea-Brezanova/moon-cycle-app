# Enabling the Recipe API evaluation key (local only)

The key never goes in chat, source code, git or the app. It lives in one of two
git-ignored places on your Mac.

## 1. Get the key
Create the free evaluation account at recipe-api.com and copy the key from its
dashboard. Do not choose a paid plan.

## 2a. Probe the real API (capped, no app needed)
```bash
mkdir -p ~/.moon-cycle && read -s -p "Recipe API key: " K && printf '%s' "$K" > ~/.moon-cycle/recipe_api_key && chmod 600 ~/.moon-cycle/recipe_api_key; unset K
dart run tool/recipe_api_probe.dart --foods chickpea,spinach --details 2
```
`read -s` hides what you type, so the key is not echoed or kept in shell history.
The probe makes at most 12 free calls and 2 detail lookups, keeps a lifetime
paid-lookup limit of 40 (`.recipeapi_usage.json`) and saves responses to
`tool/captures/` (git-ignored). Tell me when it has run; I will compare the real
responses with the adapter's assumptions.

## 2b. Local Supabase proxy (later, for the app)
Put `RECIPE_API_KEY=<key>` in `supabase/functions/.env.local` (git-ignored; the
`.example` file stays empty). Run `supabase functions serve --env-file
supabase/functions/.env.local`. Providers start disabled in the local database
(`provider_configs`), so nothing is called until you enable `recipeapi` there.

## Safety
- Never commit either file; `git status` must not list them.
- If a key is ever pasted somewhere by mistake, rotate it in the dashboard.
