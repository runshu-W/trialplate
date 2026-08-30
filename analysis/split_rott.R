source("analysis/_setup.R")
prep <- tp_prepare(rott_data(), rott_criteria, "trt","dtime","death", rott_ps, tau=2555)
fit <- tp_fit(prep)
M <- tp_split_eval(prep, fit, R = 300L, cores = 1L)
M <- M[complete.cases(M), , drop=FALSE]; g <- M[,"gap"]
ci <- quantile(g, c(.025,.975), names=FALSE)
cat(sprintf("[rotterdam] R=%d  gap mean %+.1f d  median %+.1f d  95%% [%+.1f, %+.1f]  P(>0) %.3f  same %.3f\n",
    nrow(M), mean(g), median(g), ci[1], ci[2], mean(g>0), mean(M[,"same"])))
saveRDS(M, "analysis/out/split_rotterdam.rds")
