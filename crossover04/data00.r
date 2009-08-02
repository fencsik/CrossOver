### Add hit and CR rates, and standard d' and criterion, to raw data

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

    ## compute rates and SDT measures
    data00$pHit <- with(data00, nHits / nPos)
    data00$pCR <- with(data00, nCR / nNeg)
    pFA <- 1 - data00$pCR
    data00$dprime <- with(data00, qnorm(pHit) - qnorm(pFA))
    data00$crit <- with(data00, -0.5 * (qnorm(pHit) + qnorm(pFA)))

    ## compute CI around d'
    phiFA <- with(data00, 1 / sqrt(2 * pi) * exp(-0.5 * qnorm(pFA)))
    phiHR <- with(data00, 1 / sqrt(2 * pi) * exp(-0.5 * qnorm(pHit)))
    data00$dpci <- with(data00,
                        1.96 * sqrt(pHit * (1 - pHit) / nPos / (phiHR^2) +
                                    pFA * (1 - pFA) / nNeg / (phiFA^2)))

    save(data00, file=outfile)
}

f.data00()
rm(f.data00)
