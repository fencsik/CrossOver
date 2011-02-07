### data02
###
### Compute d' and associated statistics aggregated by subjects, stim set,
### and setsize.  Collapses across precue conditions.

f.data02 <- function () {
    infile <- "data.txt"
    outfile <- "data02.rda"
    compute.dprime.file <- "ComputeDprime.r"
    source(compute.dprime.file)

    ## load data file and revise variables
    dt <- read.delim(infile)
    dt$cond <- factor(as.character(dt$cond),
                          levels=c("2v5", "OrFeat"),
                          labels=c("2v5", "Orientation"))
    dt$setsize <- factor(dt$setsize)
    dt$palmer <- factor(dt$palmer, levels=0:1,
                            labels=c("no-precues", "precues"))
    dt$nfa <- with(dt, nneg - ncr)

    ## aggregate data
    factors <- with(dt, list(sub=sub, cond=cond, setsize=setsize))
    data02 <- aggregate(data.frame(npos=dt$npos), factors, sum)
    data02$nneg <- aggregate(dt$nneg, factors, sum)$x
    data02$nhits <- aggregate(dt$nhits, factors, sum)$x
    data02$nfa <- aggregate(dt$nfa, factors, sum)$x

    ## compute d', criterion, and CIs
    out <- with(data02, ComputeDprime(nhits, nfa, npos, nneg))
    data02$dprime <- out$dprime
    data02$crit <- out$criterion
    data02$dpci <- out$ci

    ## save data
    save(data02, file=outfile)
    invisible(data02)
}

f.data02()
rm(f.data02)
