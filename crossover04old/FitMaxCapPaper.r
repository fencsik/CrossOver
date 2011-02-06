### Generates a fit object from the limited capacity model presented in the
### first submitted version of the Crossover paper.
###
### The model parameters come from Table 1 of that paper.  The output
### matches the standard output from the other fitting functions (e.g.,
### FitMaxSSE.r).

FitMaxCapPaper <- function () {
    thisfile <- "FitMaxCapPaper.r"
    infile <- "data00.rda"
    outfile <- "FitMaxCapPaper.rda"

    on.exit(while (substr(search()[2], 1, 7) != "package") detach())

### Hard-code model parameters
    output <- array(NA, dim=c(5, 9, 2),
                    dimnames=list(
                      c("AES", "CAT", "EMP", "KWP", "RER"),
                      c("s", "c", "k", "iter", "psse",
                        "sse", "rmse", "r", "rsq"),
                      c("2v5", "OrFeat")))
    output[, "s", "2v5"]    <- c(2.402, 2.178, 2.174, 2.733, 2.855)
    output[, "s", "OrFeat"] <- c(2.961, 4.065, 2.287, 3.033, 2.226)
    output[, "c", "2v5"]    <- c(1.055, 1.412, 0.911, 1.618, 1.022)
    output[, "c", "OrFeat"] <- c(1.933, 2.281, 1.533, 2.015, 1.179)
    output[, "k", "2v5"]    <- c(2.348, 6.187, 2.711, 5.841, 2.995)
    output[, "k", "OrFeat"] <- c(6.165, 8.000, 5.606, 7.815, 4.935)

### Load files

    if (!file.exists(infile))
        stop("cannot open file ", infile)
    if (IsFileUpToDate(outfile, c(thisfile, infile))) {
        warning("Output file is up to date, no action taken");
        return(invisible(NULL));
    }

    load(infile)

    if (!file.exists("maxrule.r"))
        stop("cannot open file maxrule.r")
    source("maxrule.r")

### Extract information from data file

    attach(data00)
    factors <- list(sub, cond, setsize)
    npos <- tapply(npos, factors, sum)
    nneg <- tapply(nneg, factors, sum)
    obs.nhits <- tapply(nhits, factors, sum)
    obs.nfa <- tapply(nfa, factors, sum)
    detach()

    pred.nhits <- array(NA, dim(obs.nhits), dimnames(obs.nhits))
    pred.nfa <- array(NA, dim(obs.nfa), dimnames(obs.nfa))
    setsizes <- as.numeric(dimnames(npos)[[3]])

### Pseudo-fitting: Compute the predicted data and fit statistics
    for (sub in dimnames(output)[[1]]) {
        for (cond in dimnames(output)[[3]]) {
            o.nhits <- obs.nhits[sub, cond, ]
            o.nfa <- obs.nfa[sub, cond, ]
            np <- npos[sub, cond, ]
            nn <- npos[sub, cond, ]

            sens <- output[sub, "s", cond]
            crit <- output[sub, "c", cond]
            k <- output[sub, "k", cond]

            pred <- maxrule(sens, crit, setsizes, k)
            p.nhits <- pred$hr * npos[sub, cond, ]
            p.nfa <- pred$fa * nneg[sub, cond, ]
            pred.nhits[sub, cond, ] <- p.nhits
            pred.nfa[sub, cond, ] <- p.nfa

            output[sub, "psse", cond] <-
                sum((c(o.nhits / npos[sub, cond, ],
                       o.nfa / nneg[sub, cond, ]) -
                     c(pred$hr, pred$fa))^2)
            output[sub, "sse", cond] <-
                sum((c(o.nhits, o.nfa) - c(p.nhits, p.nfa))^2)
            output[sub, "rmse", cond] <-
                sqrt(mean((c(p.nhits, p.nfa) - c(o.nhits, o.nfa))^2))
            output[sub, "r", cond] <-
                cor(c(p.nhits, p.nfa), c(o.nhits, o.nfa))
            output[sub, "rsq", cond] <- output[sub, "r", cond]^2
        }
    }

### convert back to data frames
    data <- as.data.frame(as.table(npos))
    names(data) <- c("sub", "cond", "setsize", "npos")
    data$nneg <- as.data.frame(as.table(nneg))$Freq
    data$obs.nhits <- as.data.frame(as.table(obs.nhits))$Freq
    data$obs.nfa <- as.data.frame(as.table(obs.nfa))$Freq
    data$pred.nhits <- as.data.frame(as.table(pred.nhits))$Freq
    data$pred.nfa <- as.data.frame(as.table(pred.nfa))$Freq
    data <- data[with(data, order(sub, cond, setsize)), ]

    fit <- list(data=data, out=output,
                rsq=with(data,
                  cor(c(obs.nhits, obs.nfa), c(pred.nhits, pred.nfa))^2),
                rule="max", crit="SSE", type="counts")
    save(fit, file=outfile)
}

FitMaxCapPaper()
rm(FitMaxCapPaper)
