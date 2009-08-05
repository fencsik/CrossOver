### Tweak the data and add standard SDT measures to raw data

f.data00 <- function () {
    thisfile <- "data00.r"
    infile <- "data.txt"
    outfile <- "data00.rda"

    if (!file.exists(infile)) stop("cannot open file ", infile)
    if (IsFileUpToDate(outfile, c(thisfile, infile))) {
        warning("Output file is up to date, no action taken");
        return(invisible(NULL));
    }

    data00 <- read.delim(infile)

    ## create factors where needed
    data00$palmer <- factor(data00$palmer)

    ## convert CR to FA
    data00$nfa <- with(data00, nneg - ncr)
    data00 <- data00[, -which(names(data00) == "ncr")]

    ## compute rates
    hr <- with(data00, nhits / npos)
    fa <- with(data00, nfa / nneg)

    ## correct HR for p={0,1}
    adjHR <- data00$nhits
    index <- adjHR == 0
    if (any(index)) adjHR[index] <- 0.5
    index <- adjHR == data00$npos
    if (any(index)) adjHR[index] <- data00$npos[index] - 0.5
    adjHR <- adjHR / data00$npos

    ## correct CR for p={0,1}
    adjFA <- data00$nfa
    index <- adjFA == 0
    if (any(index)) adjFA[index] <- 0.5
    index <- adjFA == data00$nneg
    if (any(index)) adjFA[index] <- data00$nneg[index] - 0.5
    adjFA <- adjFA / data00$nneg

    data00$dprime <- qnorm(adjHR) - qnorm(adjFA)
    data00$crit <- -0.5 * (qnorm(adjHR) + qnorm(adjFA))

    ## compute CI around d'
    phiFA <- 1 / sqrt(2 * pi) * exp(-0.5 * qnorm(adjFA))
    phiHR <- 1 / sqrt(2 * pi) * exp(-0.5 * qnorm(adjHR))
    data00$dpci <- with(data00,
                        1.96 * sqrt(adjHR * (1 - adjHR) / npos / (phiHR^2) +
                                    adjFA * (1 - adjFA) / nneg / (phiFA^2)))

    save(data00, file=outfile)
}

f.data00()
rm(f.data00)
