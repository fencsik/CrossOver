### data02
###
### Compute d' and associated statistics aggregated by subjects, stim set,
### and setsize

f.data02 <- function () {
    infile <- "data01.rda"
    outfile <- "data02.rda"
    compute.dprime.file <- "ComputeDprime.r"
    load(infile)
    source(compute.dprime.file)

    ## split data
    targ <- data01$target
    index <- names(data01) != "target"
    ta <- data01[targ == "absent", index]
    tp <- data01[targ == "present", index]

    ## create new data table with appropriate IVs and check that everything is
    ## ordered correctly
    if (!all(tp$setsize == ta$setsize & tp$cond == ta$cond &
             tp$sub == ta$sub)) {
        stop("mismatch between target-present and target-absent factors")
    }
    data02 <- tp[,c("setsize", "cond", "sub")]
    rownames(data02) <- as.character(1:dim(data02)[1])

    ## place basic DVs into data table
    data02$npos <- tp$nobs
    data02$nneg <- ta$nobs
    data02$nhits <- tp$ncor
    data02$nfa <- ta$nobs - ta$ncor

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
