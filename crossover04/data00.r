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
    data00$hr <- with(data00, nhits / npos)
    data00$fa <- with(data00, 1 - ntneg / nneg)
    data00$dprime <- with(data00, qnorm(hr) - qnorm(fa))
    data00$crit <- with(data00, -0.5 * (qnorm(hr) + qnorm(fa)))

    ## compute CI around d'
    phiFA <- with(data00, 1 / sqrt(2 * pi) * exp(-0.5 * qnorm(fa)))
    phiHR <- with(data00, 1 / sqrt(2 * pi) * exp(-0.5 * qnorm(hr)))
    data00$dpci <- with(data00,
                        1.96 * sqrt(hr * (1 - hr) / npos / (phiHR^2) +
                                    fa * (1 - fa) / nneg / (phiFA^2)))

    save(data00, file=outfile)
}

f.data00()
rm(f.data00)
