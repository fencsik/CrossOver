### data02
###
### Compute d' and associated statistics aggregated by subjects, stim set,
### and setsize

f.data02 <- function () {
    infile <- "data01.rda"
    outfile <- "data02.rda"
    load(infile)

    ## split data
    targ <- data01$target
    index <- names(data01) != "target"
    ta <- data01[targ == "absent", index]
    tp <- data01[targ == "present", index]

    ## create new data table with appropriate IVs and check that everything is
    ## ordered correctly
    if (!all(tp$setsize == ta$setsize & tp$cond == ta$cond &
             tp$subject == ta$subject)) {
        stop("mismatch between target-present and target-absent factors")
    }
    data02 <- tp[,c("setsize", "cond", "subject")]
    rownames(data02) <- as.character(1:dim(data02)[1])

    ## place basic DVs into data table
    data02$npos <- tp$nobs
    data02$nneg <- ta$nobs
    data02$nhits <- tp$ncor
    data02$nfa <- ta$nobs - ta$ncor

    ## correct HR for p={0,1}
    adjHR <- data02$nhits
    index <- adjHR == 0
    if (any(index)) adjHR[index] <- 0.5
    index <- adjHR == data02$npos
    if (any(index)) adjHR[index] <- data02$npos[index] - 0.5
    adjHR <- adjHR / data02$npos

    ## correct CR for p={0,1}
    adjFA <- data02$nfa
    index <- adjFA == 0
    if (any(index)) adjFA[index] <- 0.5
    index <- adjFA == data02$nneg
    if (any(index)) adjFA[index] <- data02$nneg[index] - 0.5
    adjFA <- adjFA / data02$nneg

    ## compute d' and criterion
    data02$dprime <- qnorm(adjHR) - qnorm(adjFA)
    data02$crit <- -0.5 * (qnorm(adjHR) + qnorm(adjFA))

    ## compute CI around d'
    phiFA <- 1 / sqrt(2 * pi) * exp(-0.5 * qnorm(adjFA))
    phiHR <- 1 / sqrt(2 * pi) * exp(-0.5 * qnorm(adjHR))
    data02$dpci <- with(data02,
                        1.96 * sqrt(adjHR * (1 - adjHR) / npos / (phiHR^2) +
                                    adjFA * (1 - adjFA) / nneg / (phiFA^2)))

    ## save data
    save(data02, file=outfile)
    invisible(data02)
}

f.data02()
rm(f.data02)
