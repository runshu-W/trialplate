## One representative split of colon, scored on the held-out half: every one of the
## 512 subsets, the rule's own choice, and the full protocol. Uses primary.R's seed
## so the split is one of the 500 the paper reports, not a fresh one.
source("analysis/_setup.R")
SEED <- 101L * 1000L + 1L
dat <- colon_data(); crit <- colon_criteria; ps <- colon_ps
trt <- "trt"; tm <- "time"; st <- "status"; tau <- 1825
p <- length(crit); bits <- bitwShiftL(1L, 0:(p - 1))

set.seed(SEED)
ix  <- strat_split(dat, trt, st, 0.5)
fit <- tp_prepare(dat[ix, , drop = FALSE],  crit, trt, tm, st, ps, tau = tau)
sc  <- tp_prepare(dat[-ix, , drop = FALSE], crit, trt, tm, st, ps, tau = tau)
Vf  <- tp_enumerate(fit)
S   <- which(tp_shapley(Vf, p, 1L) < 0)          # criteria the rule KEEPS
Vs  <- tp_enumerate(sc)
ok  <- Vs[, "feasible"] == 1
N   <- exp(Vs[, "logN"]); H <- Vs[, "logHR"]
kR  <- sum(bits[S]) + 1L                          # the rule's subset
kF  <- sum(bits[seq_len(p)]) + 1L                 # the full protocol

dom <- ok & N >= N[kR] & H <= H[kR] & (N > N[kR] | H < H[kR])
out <- data.frame(k = seq_along(N), n = N, loghr = H, feasible = as.integer(ok),
                  is_rule = as.integer(seq_along(N) == kR),
                  is_full = as.integer(seq_along(N) == kF),
                  dominates = as.integer(dom))
write.csv(out, "/tmp/claude-0/-home-claude/fecdb169-27b0-5eaf-b723-425ba66180a5/scratchpad/fig/subsets_colon.csv", row.names = FALSE)
cat(sprintf("rule keeps %d of %d criteria; n_rule %.0f n_full %.0f; logHR rule %.3f full %.3f; dominators %d; feasible %d\n",
            length(S), p, N[kR], N[kF], H[kR], H[kF], sum(dom), sum(ok)))
