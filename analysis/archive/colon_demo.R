source("/home/claude/trialplate/R/core.R")

d <- subset(survival::colon, etype == 2 & rx %in% c("Obs", "Lev+5FU"))
d$trt <- as.integer(d$rx == "Lev+5FU")
d$differ2 <- d$differ; d$nodes2 <- d$nodes
d$differ2[is.na(d$differ2)] <- 2; d$nodes2[is.na(d$nodes2)] <- 2   # PS model only

criteria <- list(
  AGE75  = function(x) x$age    <= 75,   # upper age limit
  NOOBS  = function(x) x$obstruct == 0,  # no bowel obstruction
  NOPRF  = function(x) x$perfor   == 0,  # no perforation
  NOADH  = function(x) x$adhere   == 0,  # no adherence to adjacent organs
  DIFF12 = function(x) x$differ   <= 2,  # well/moderately differentiated
  EXT13  = function(x) x$extent   <= 3,  # no extension beyond serosa
  SURG0  = function(x) x$surg     == 0,  # short interval since surgery
  ND10   = function(x) x$nodes    <= 10, # nodal burden cap
  NOD4   = function(x) x$node4    == 0,  # < 4 positive nodes
  NDPOS  = function(x) x$nodes    >= 1   # node-positive required
)

t0 <- Sys.time()
fit <- trialplate_fit(d, criteria, "trt", "time", "status",
                      ps_covars = c("age","sex","nodes2","differ2","extent","surg",
                                    "obstruct","perfor","adhere"))
cat("elapsed:", round(as.numeric(difftime(Sys.time(), t0, units="secs")),1), "s\n")
cat("NA logHR subsets:", sum(is.na(fit$V[,"logHR"])), "/", nrow(fit$V), "\n")
cat("N no criteria :", round(fit$n_empty), "  HR:", round(exp(fit$v_empty[1]),3), "\n")
cat("N all criteria:", round(fit$n_full),  "  HR:", round(exp(fit$v_full[1]),3), "\n\n")

res <- data.frame(criterion = fit$names,
                  phi_logHR = round(fit$phi_HR, 4),
                  dHR_pct   = round(100*(exp(fit$phi_HR)-1), 1),
                  phi_logN  = round(fit$phi_N, 4),
                  dN_pct    = round(100*(exp(fit$phi_N)-1), 1))
print(res[order(-res$phi_logHR), ], row.names = FALSE)

cat("\n-- efficiency check (Shapley axiom) --\n")
cat("sum phi_HR =", round(sum(fit$phi_HR),5), " v(N)-v(0) =",
    round(fit$v_full[1]-fit$v_empty[1],5), "\n")
cat("sum phi_N  =", round(sum(fit$phi_N),5),  " v(N)-v(0) =",
    round(fit$v_full[2]-fit$v_empty[2],5), "\n")
saveRDS(fit, "/home/claude/trialplate/out/colon_fit.rds")
