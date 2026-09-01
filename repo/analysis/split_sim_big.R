source("analysis/_setup.R")
src <- readLines("analysis/split_sim.R"); i0 <- grep("^P <- 6L", src); i1 <- grep("^prep_of <-", src)
eval(parse(text = paste(src[i0:i1], collapse = "\n")))
for (n in c(50000L)) {
  pr <- prep_of(gen(n, seed = 77)); ft <- tp_fit(pr)
  M <- tp_split_eval(pr, ft, R = 200L, cores = 2L); M <- M[complete.cases(M),,drop=FALSE]
  g <- M[,"gap"]
  cat(sprintf("n = %d  R=%d  mean %+.4f (se %.4f)  P(>0) %.3f  same %.3f\n",
      n, nrow(M), mean(g), sd(g)/sqrt(length(g)), mean(g>0), mean(M[,"same"])))
  saveRDS(M, sprintf("analysis/out/splitsim_%d.rds", n))
}
