# Chinese explainer

`文章解读_中文.docx` — a three-page plain-language account of what this study
does and what it concludes, written for clinical and statistical collaborators
who will not read the manuscript first. `make_cn.js` regenerates it:

```
node explainer/make_cn.js
```

It requires the `docx` npm package and a CJK font (Noto Serif/Sans CJK SC).
It reads `analysis/out/numbers.json` at build time, exactly as the manuscript
does, so its figures cannot drift from the code.

The current version reflects the major revision. Its conclusions differ from the
first draft's: the eligibility promise is presented as monotone by construction
rather than as a validated benefit, the 3000-patient threshold is replaced by the
finding that the binding constraint is how concentrated the effect modification
is, and the regret result (below ~1000 fitting patients the rule does harm) is
new.
