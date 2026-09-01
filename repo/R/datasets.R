## Two fully public individual-level cohorts. Criteria sets are chosen so that
## the PRIMARY analysis contains no logical implications (see tp_implications);
## a nested criterion is added only in the detector demonstration.

## --- A. colon: randomised adjuvant trial, clean testbed --------------------
colon_data <- function() {
  cl <- survival::colon
  d <- cl[cl$etype == 2 & cl$rx %in% c("Obs", "Lev+5FU"), , drop = FALSE]
  d$trt <- as.integer(d$rx == "Lev+5FU")
  d$nodes_i  <- ifelse(is.na(d$nodes),  2, d$nodes)     # PS model only
  d$differ_i <- ifelse(is.na(d$differ), 2, d$differ)
  d
}
colon_criteria <- list(
  AGE75  = function(x) x$age      <= 75,   # upper age limit
  AGE40  = function(x) x$age      >= 40,   # lower age limit
  NOOBS  = function(x) x$obstruct == 0,    # no bowel obstruction
  NOPRF  = function(x) x$perfor   == 0,    # no perforation
  NOADH  = function(x) x$adhere   == 0,    # not adherent to adjacent organs
  DIFF12 = function(x) x$differ   <= 2,    # well / moderately differentiated
  EXT13  = function(x) x$extent   <= 3,    # no extension beyond serosa
  SURG0  = function(x) x$surg     == 0,    # short interval since surgery
  NOD4   = function(x) x$node4    == 0     # fewer than 4 positive nodes
)
## deliberately nested: nodes<=10 is implied by node4==0. Used ONLY to show the
## implication detector doing its job.
colon_criteria_nested <- c(colon_criteria, list(ND10 = function(x) x$nodes <= 10))
colon_ps <- c("age","sex","nodes_i","differ_i","extent","surg","obstruct","perfor","adhere")

## --- B. rotterdam: registry cohort, the RWD-like companion ----------------
rott_data <- function() {
  r <- survival::rotterdam
  r$trt <- r$chemo
  r$size_n <- as.integer(r$size)                        # 1 <=20, 2 20-50, 3 >50
  r
}
rott_criteria <- list(
  AGE70 = function(x) x$age    <= 70,
  AGE30 = function(x) x$age    >= 30,
  ND9   = function(x) x$nodes  <= 9,
  NDPOS = function(x) x$nodes  >= 1,
  SZ50  = function(x) x$size_n <= 2,
  ERP   = function(x) x$er     >= 10,
  PGRP  = function(x) x$pgr    >= 10,
  YR85  = function(x) x$year   >= 1985,
  YR90  = function(x) x$year   <= 1990
)
rott_ps <- c("age","meno","size_n","grade","nodes","pgr","er","year")
