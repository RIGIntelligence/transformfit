// Cross-runtime parity harness: runs the shared input vectors through the
// Deno plan-generation engine and writes results to a JSON the Dart test
// reads. Run: deno run --allow-all supabase/functions/_shared/engines/run_parity.ts
//
// The Dart side reads
// supabase/functions/_shared/engines/parity_results.json and asserts the Dart
// engine produces IDENTICAL outputs for the same inputs → proves the Dart/Deno
// engines agree (VAL-ONB-056 cross-runtime, the central deliverable of this
// feature).
import { generatePlan, type PlanIntake } from "./plan_generation.ts";

const spec = JSON.parse(
  await Deno.readTextFile(
    new URL("./parity_vectors.json", import.meta.url),
  ),
) as Array<{ name: string; intake: PlanIntake }>;

const out: Array<
  { name: string; intake: PlanIntake; result: ReturnType<typeof generatePlan> }
> = [];
for (const v of spec) {
  out.push({ name: v.name, intake: v.intake, result: generatePlan(v.intake) });
}

const outPath = new URL("./parity_results.json", import.meta.url);
await Deno.writeTextFile(outPath, JSON.stringify(out, null, 0));
console.log(`Wrote ${out.length} parity results to ${outPath.pathname}`);
