#!/usr/bin/env bash
# End-to-end check against the LOCAL stack only (supabase start, then
# `supabase functions serve --env-file supabase/functions/.env.local`).
# Signs up a throwaway local user, calls generate-recipe, and checks the
# database. Refuses to run against anything but 127.0.0.1.
set -euo pipefail
eval "$(supabase status -o env 2>/dev/null | grep -E '^(API_URL|ANON_KEY|SERVICE_ROLE_KEY|DB_URL)=')"
case "$API_URL" in http://127.0.0.1:*|http://localhost:*) ;; *) echo "refusing: not local"; exit 1;; esac
fail() { echo "FAIL: $*"; exit 1; }
email="it-$RANDOM$RANDOM@example.test"
auth=$(curl -s "$API_URL/auth/v1/signup" -H "apikey: $ANON_KEY" -H 'content-type: application/json' \
  -d "{\"email\":\"$email\",\"password\":\"local-test-password-1\"}")
token=$(echo "$auth" | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
uid=$(echo "$auth" | python3 -c 'import sys,json; print(json.load(sys.stdin)["user"]["id"])')
key="itkey-$RANDOM$RANDOM"
body="{\"idempotency_key\":\"$key\",\"phase\":\"luteal\",\"protein_id\":\"tofu\",\"base_id\":\"farro\",\"plant_ids\":[\"kale\",\"carrot\"]}"
call() { curl -s -w '\n%{http_code}' "$API_URL/functions/v1/generate-recipe" -H "authorization: Bearer $token" -H "apikey: $ANON_KEY" -H 'content-type: application/json' -d "$1"; }
psqlq() { docker exec -i supabase_db_moon-cycle-flutter psql -U postgres -tA -c "$1"; }

# 1. signed out
code=$(curl -s -o /dev/null -w '%{http_code}' "$API_URL/functions/v1/generate-recipe" -H "apikey: $ANON_KEY" -H 'content-type: application/json' -d "$body")
[ "$code" = 401 ] || fail "signed-out expected 401, got $code"

# 2. a new user without Premium is refused when the local bypass is off
psqlq "delete from public.app_config where key='dev_generation_bypass'" >/dev/null
out=$(call "$body"); code=${out##*$'\n'}
[ "$code" = 403 ] || fail "not entitled expected 403, got $code ($out)"

# 3. with the local bypass restored, a recipe is created and saved
psqlq "insert into public.app_config values ('dev_generation_bypass','true') on conflict (key) do update set value='true'" >/dev/null
out=$(call "$body"); code=${out##*$'\n'}
[ "$code" = 200 ] || fail "create expected 200, got $code ($out)"
[ "$(psqlq "select count(*) from public.generated_recipes where user_id='$uid'")" = 1 ] || fail "recipe not saved"
[ "$(psqlq "select generations_used from public.usage_counters where user_id='$uid'")" = 1 ] || fail "quota not charged once"
[ "$(psqlq "select origin from public.generated_recipes where user_id='$uid'")" = local_stub ] || fail "origin should be local_stub"

# 4. the same key again: same recipe, nothing new, nothing charged
out=$(call "$body"); code=${out##*$'\n'}
[ "$code" = 200 ] || fail "repeat expected 200, got $code"
echo "$out" | grep -q '"existing":true' || fail "repeat should say existing"
[ "$(psqlq "select count(*) from public.generated_recipes where user_id='$uid'")" = 1 ] || fail "duplicate recipe"
[ "$(psqlq "select generations_used from public.usage_counters where user_id='$uid'")" = 1 ] || fail "charged twice"

# 5. the user can read only their own recipe through the API
rows=$(curl -s "$API_URL/rest/v1/generated_recipes?select=id,title" -H "authorization: Bearer $token" -H "apikey: $ANON_KEY")
[ "$(echo "$rows" | python3 -c 'import sys,json; print(len(json.load(sys.stdin)))')" = 1 ] || fail "own recipes: $rows"
# ...and cannot grant themselves Premium or edit content
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API_URL/rest/v1/entitlements" -H "authorization: Bearer $token" -H "apikey: $ANON_KEY" -H 'content-type: application/json' -d "{\"user_id\":\"$uid\",\"tier\":\"premium\",\"source\":\"purchase\"}")
[ "$code" = 401 ] || [ "$code" = 403 ] || fail "client entitlement insert should be refused, got $code"

# 6. clean up the throwaway user
psqlq "select public.delete_user_data('$uid')" >/dev/null
echo "integration: all checks passed"
