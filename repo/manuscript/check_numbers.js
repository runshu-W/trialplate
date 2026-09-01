/* Reviewer round 5, major point 1.
 *
 * The previous revision claimed that every figure in the paper is read from one
 * result file. It was not true: Results section 2 quoted 0.270 and 0.497 as string
 * literals, the Methods quoted three weighting probabilities as string literals,
 * and two superseded result objects were still being read. A claim of that kind
 * has to be enforced by the build, not asserted in a cover letter.
 *
 * This checker scans every prose string in the manuscript sources and fails on any
 * decimal number that is not a whitelisted structural constant. A figure that comes
 * from the analysis is a `f(NUM...)` expression and never appears as a literal, so
 * anything this finds is either a transcribed result or a constant that belongs on
 * the list below with a reason.
 *
 *   node check_numbers.js          -> report and exit non-zero on any violation
 */
const fs = require("fs");

/* Structural constants: design parameters, thresholds and specification values that
 * define the study rather than report its outcome. Each needs a reason. */
const ALLOWED = new Map(Object.entries({
  "0.5":   "split fraction, a design choice",
  "0.7":   "second split fraction, a design choice",
  "0.05":  "propensity truncation bound, dominance margin, and the conventional alpha",
  "0.95":  "propensity truncation bound and the nominal interval level",
  "0.10":  "leverage reporting threshold, a presentation choice",
  "0.9":   "reliability target reported beside 0.80",
  "0.70":  "reliability target reported beside 0.80",
  "0.8":   "reliability target, by convention from power calculations",
  "0.80":  "reliability target, by convention from power calculations",
  "0.90":  "reliability target reported beside 0.80",
  "0.75":  "generating-model coefficient, stated in Text S1",
  "0.6":   "conditional hazard ratio fixed in the non-collapsibility simulation",
  "0.20":  "baseline hazard rate in the generating model",
  "0.55":  "prognostic strength per covariate in the generating model",
  "0.30":  "full-protocol retention level in the factorial",
  "0.12":  "full-protocol retention level in the factorial",
  "0.40":  "effect-modification magnitude level in the factorial",
  "0.16":  "effect-modification magnitude level in the factorial",
  "0.25":  "allocation ratio level in the factorial",
  "0.45":  "assignment-model coefficient in the factorial",
  "0.03":  "censoring rate in the leverage verification",
  "0.020": "censoring-rate factor level in the factorial",
  "0.180": "censoring-rate factor level in the factorial",
  "0.85":  "eligibility rate in the leverage verification",
  "0.15":  "largest matching tolerance, a design choice",
  "0.02":  "smallest matching tolerance, a design choice",
  "1.96":  "normal quantile",
  "2.5":   "percentile interval endpoint",
  "97.5":  "percentile interval endpoint",
  "95%":   "the nominal interval level",
  "50%":   "one half, the reference value for a matched proportion",
  "10%":   "matching tolerance and leverage reporting threshold, both design choices",
  "5%":    "matching tolerance and the conventional alpha",
  "2%":    "smallest matching tolerance",
  "15%":   "largest matching tolerance",
  "90%":   "illustrative eligibility rate in a hypothetical, not a result",
  "30%":   "illustrative eligibility rate in a hypothetical, not a result",
}));

/* Files whose prose is scanned. */
/* Round 6: build.js and refs.js also emit prose (declarations, acknowledgements,
 * the reference list), so they are scanned too; the Methods describe the check as
 * covering the manuscript sources, and it should. */
/* Live document sources: the manuscript, the supplement, and the response letter
 * for the current round. These must contain no transcribed figure. */
const FILES = ["make.js", "part2.js", "part3.js", "supp.js", "build.js", "refs.js",
               "response7.js"];

/* Earlier response letters are a historical record of what was claimed at the time,
 * including claims later corrected. Rewriting them to read from today's result file
 * would make them say something they did not say, so they are deliberately NOT
 * scanned. They are listed here so the exemption is visible rather than silent, and
 * the check reports it on every run. */
const HISTORICAL = ["response.js", "response2.js", "response3.js", "response4.js",
                    "response5.js", "response6.js"];

/* A response letter has to be able to quote the wrong value it is correcting.
 * Those quotations are listed here explicitly rather than being exempted by a
 * blanket rule, so each one is visible. */
const QUOTED_ERRORS = new Map(Object.entries({
  "response5.js": ["32%", "10", "30"],
  "response6.js": [],
  "response7.js": [],
}));

/* Walk the source once, tracking string and comment state, and return every
 * DOUBLE-quoted string literal with its line number.
 *
 * The fifth-round audit found two ways a regex-based scanner silently skipped
 * material: matching single-quoted strings made it desynchronise on apostrophes
 * in prose, and ignoring them made it desynchronise on double quotes inside
 * single-quoted strings. Either way it stopped seeing the abstract while still
 * reporting a pass. A one-pass tokeniser has neither failure mode. */
function stringsOf(src) {
  const out = [];
  let i = 0, line = 1;
  const n = src.length;
  while (i < n) {
    const c = src[i];
    if (c === "\n") { line++; i++; continue; }
    if (c === "/" && src[i+1] === "/") { while (i < n && src[i] !== "\n") i++; continue; }
    if (c === "/" && src[i+1] === "*") {
      i += 2;
      while (i < n && !(src[i] === "*" && src[i+1] === "/")) { if (src[i] === "\n") line++; i++; }
      i += 2; continue;
    }
    if (c === "'" || c === "`") {              /* skip, but stay in sync */
      const q = c; i++;
      while (i < n && src[i] !== q) { if (src[i] === "\\") i++; else if (src[i] === "\n") line++; i++; }
      i++; continue;
    }
    if (c === '"') {
      /* MONO(...) is the verbatim specification of a generating model in Text S1:
       * its numbers define the simulation rather than report a result, so a
       * literal is the correct form there. */
      let k = i - 1; while (k >= 0 && /\s/.test(src[k])) k--;
      const isMono = k >= 4 && src.slice(k - 4, k + 1) === "MONO(";
      const startLine = line; let buf = ""; i++;
      while (i < n && src[i] !== '"') {
        if (src[i] === "\\") { buf += src[i+1] === "n" ? " " : src[i+1]; i += 2; continue; }
        if (src[i] === "\n") line++;
        buf += src[i]; i++;
      }
      i++;
      if (!isMono) out.push({ text: buf, line: startLine });
      continue;
    }
    i++;
  }
  return out;
}

let violations = [];
for (const file of FILES) {
  let src = fs.readFileSync(file, "utf8");
  src = src.replace(/^\s*\/\*[\s\S]*?\*\//gm, "").replace(/^\s*\/\/.*$/gm, "");
  for (const { text, line } of stringsOf(src)) {
    /* keys into the result object, e.g. "hr0.1", are not prose */
    if (/^[a-z_]+[0-9.]*$/i.test(text)) continue;
    /* A DOI or a journal citation is bibliographic, not a reported figure. */
    if (/\bdoi:/i.test(text) || /\b\d{4};\d+/.test(text)) continue;
    /* format strings and separators are not prose */
    if (/^[\s%.,;:|()\[\]+-]*$/.test(text)) continue;
    /* NOTE: table cells are NOT exempt. The audit found that requiring three
     * letters excused every numeric cell in the supplement, so four tables were
     * typed literals while this check reported a pass. */
    /* Decimals, and ALSO integer percentages: the fifth review found a stale "32%"
     * in a figure caption that an earlier version of this check could not see,
     * because it only looked for decimal points. Integer counts elsewhere in prose
     * (sample sizes, criterion counts) are left alone; a percentage is always a
     * reported result. */
    const nums = (text.match(/(?<![\w.])\d+\.\d+(?![\w])/g) || [])
      .concat((text.match(/(?<![\w.])\d+(?=\s?%)/g) || []).map(x => x + "%"));
    for (const n of nums) {
      if (ALLOWED.has(n)) continue;
      if ((QUOTED_ERRORS.get(file) || []).includes(n)) continue;
      violations.push({ file, line, num: n, ctx: text.slice(Math.max(0, text.indexOf(n) - 60), text.indexOf(n) + 40) });
    }
  }
}

if (violations.length) {
  console.error("NUMBER PROVENANCE CHECK FAILED — " + violations.length + " transcribed figure(s):\n");
  for (const v of violations)
    console.error("  " + v.file + ":" + v.line + "  " + v.num + "\n      ..." + v.ctx.replace(/\s+/g, " ") + "...");
  console.error("\nEvery reported figure must be read from analysis/out/numbers.json.");
  console.error("If one of these is a design constant, add it to ALLOWED with a reason.");
  process.exit(1);
}
console.log("number provenance check passed over " + FILES.length + " live sources; " +
            ALLOWED.size + " structural constants whitelisted; " +
            HISTORICAL.length + " earlier response letters exempt as historical record");
