// Runs the shared fixtures against the TypeScript validator.
//   deno test --allow-read supabase/functions/_shared/validator_test.ts
import { assertEquals } from "jsr:@std/assert@1";
import { validate } from "./validator.ts";

const cases = JSON.parse(
  Deno.readTextFileSync(
    new URL("../../../test/fixtures/generation/validator_cases.json", import.meta.url),
  ),
);

for (const c of cases) {
  Deno.test(`fixture: ${c.name}`, () => {
    const issues = validate(c.recipe, c.request, {
      diet: c.filter.diet,
      allergens: c.filter.allergens,
    });
    assertEquals(
      [...new Set(issues.map((i) => i.code))].sort(),
      [...c.expect].sort(),
      JSON.stringify(issues),
    );
  });
}
