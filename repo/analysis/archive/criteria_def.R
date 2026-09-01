d <- subset(survival::colon, etype == 2 & rx %in% c("Obs", "Lev+5FU"))
d$trt <- as.integer(d$rx == "Lev+5FU")
d$differ2 <- d$differ; d$nodes2 <- d$nodes
d$differ2[is.na(d$differ2)] <- 2; d$nodes2[is.na(d$nodes2)] <- 2
criteria <- list(
  AGE75  = function(x) x$age      <= 75,
  NOOBS  = function(x) x$obstruct == 0,
  NOPRF  = function(x) x$perfor   == 0,
  NOADH  = function(x) x$adhere   == 0,
  DIFF12 = function(x) x$differ   <= 2,
  EXT13  = function(x) x$extent   <= 3,
  SURG0  = function(x) x$surg     == 0,
  ND10   = function(x) x$nodes    <= 10,
  NOD4   = function(x) x$node4    == 0,
  NDPOS  = function(x) x$nodes    >= 1
)
crit_label <- c(AGE75="Age <= 75", NOOBS="No obstruction", NOPRF="No perforation",
  NOADH="No adherence", DIFF12="Differ. grade 1-2", EXT13="Extent <= serosa",
  SURG0="Short interval since surgery", ND10="Nodes <= 10", NOD4="< 4 positive nodes",
  NDPOS="Node-positive required")
ps_covars <- c("age","sex","nodes2","differ2","extent","surg","obstruct","perfor","adhere")
