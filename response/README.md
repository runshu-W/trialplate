# Response to review

`response_to_reviewer.docx` answers each of the nine major and ten minor points
and says where in the manuscript the change is.

The `.txt` files are the analysis outputs the response cites, committed so that
a reviewer can check a number without running anything. `numbers.json` is the
machine-readable export that the manuscript build reads: every figure quoted in
the text comes from it, so the prose cannot drift from the code.

Two comments identified errors rather than omissions.

- **Shapley efficiency.** The first version claimed the axiom held only
  approximately on the hazard-ratio scale. It holds exactly on any scale under
  exact enumeration. Corrected in the text and asserted in `tests/`.
- **The eligibility promise.** The rule retains a subset of the criteria, so the
  eligible set is a superset by construction and the reported probability was
  measuring how often a binding criterion is removed rather than a benefit.
  Reframed throughout, and `analysis/random_benchmark.R` adds the comparison
  that does have content.

A third sent us to look at Rotterdam's overlap, which turned out to violate
positivity inside the full protocol; its effect estimates are now reported as
descriptive.

Three findings in the revision were not in the first version and change the
conclusions:

1. Benchmarked against random relaxations of the same size, the rule shows **no
   enrolment advantage**, and in Rotterdam admits fewer patients (442 vs 664).
   Its contribution appears to lie in the effect estimate.
2. Across the factorial, the binding constraint is **not cohort size** but how
   concentrated the effect modification is. All eight diffuse-modification
   scenarios failed to reach threshold at any size tested.
3. Below roughly 1000 fitting patients the rule's protocol has **slightly higher
   regret than the full protocol** it was intended to improve, so the outcome
   there is a little worse than the starting protocol rather than simply an
   absent improvement.
