### Fit a max-rule search model to each subject's hit rate and false-alarm
### rate by minimizing sum-squared error.  Uses proportions instead of
### counts.
###
### This version is based on a limited-capacity model, one criterion across
### setsizes, and collapses across the palmer flag.

FitPMaxCapSSE <- function () {
    thisfile <- "FitPMaxCapSSE.r"
    infile <- "data00.rda"
    outfile <- "FitPMaxCapSSE.rda"

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

### Prepare data and output

    if (is.factor(data00$setsize))
        data00$setsize <- as.numeric(as.character(data00$setsize))

    subjects <- sort(levels(factor(data00$sub)))
    stimsets <- sort(levels(factor(data00$cond)))
    setsizes <- sort(unique(data00$setsize))

    nSubjects <- length(subjects)
    nStimsets <- length(stimsets)
    nSetsizes <- length(setsizes)

    ## Calculate proportions
    data00$phits <- with(data00, nhits / npos)
    data00$pfa <- with(data00, nfa / nneg)

    ## Extract conditions
    factors <- with(data00, list(sub, cond, setsize))
    npos <- with(data00, tapply(npos, factors, sum))
    nneg <- with(data00, tapply(nneg, factors, sum))
    obs.phits <- with(data00, tapply(phits, factors, mean))
    obs.pfa <- with(data00, tapply(pfa, factors, mean))

    pred.phits <- array(NA, dim(obs.phits), dimnames(obs.phits))
    pred.pfa <- array(NA, dim(obs.pfa), dimnames(obs.pfa))

    output <- array(NA, dim=c(nSubjects, 9, nStimsets),
                    dimnames=list(subjects,
                      c("s", "c", "k",
                        "iter", "code", "sse", "rmse", "r", "rsq"),
                      stimsets))

### Fit function
    GoodnessOfFit <- function (p, obs) {
        pred <- maxrule(p[1], p[2], setsizes, p[3])
        return(sum((c(obs$phits, obs$pfa) - c(pred$hr, pred$fa)) ^ 2))
    }

### Actual fitting

    for (sub in subjects) {
        for (cond in stimsets) {
            p <- c(3, 2, 4) # sensitivity and criterion
            obs <- list(phits=obs.phits[sub, cond, ],
                        pfa=obs.pfa[sub, cond, ])
            o <- nlminb(p, GoodnessOfFit, obs=obs)

            output[sub, "s", cond] <- o$par[1]
            output[sub, "c", cond] <- o$par[2]
            output[sub, "k", cond] <- o$par[3]
            output[sub, "iter", cond] <- o$iterations
            output[sub, "code", cond] <- o$convergence
            output[sub, "sse", cond] <- GoodnessOfFit(o$par, obs)

            ## Store predicted counts
            pred <- maxrule(o$par[1], o$par[2], setsizes, o$par[3])
            pred.phits[sub, cond, ] <- pred$hr
            pred.pfa[sub, cond, ] <- pred$fa

            output[sub, "rmse", cond] <-
                sqrt(mean((c(pred$hr, pred$fa) -
                           c(obs$phits, obs$pfa)) ^ 2))
            output[sub, "r", cond] <-
                cor(c(pred$hr, pred$fa), c(obs$phits, obs$pfa))
            output[sub, "rsq", cond] <- output[sub, "r", cond] ^ 2
        }
    }

### convert back to data frames
    data <- as.data.frame(as.table(npos))
    names(data) <- c("sub", "cond", "setsize", "npos")
    data$nneg <- as.data.frame(as.table(nneg))$Freq
    data$obs.phits <- as.data.frame(as.table(obs.phits))$Freq
    data$obs.pfa <- as.data.frame(as.table(obs.pfa))$Freq
    data$pred.phits <- as.data.frame(as.table(pred.phits))$Freq
    data$pred.pfa <- as.data.frame(as.table(pred.pfa))$Freq
    data <- data[with(data, order(sub, cond, setsize)), ]

    ## add in counts estimated from proportions
    data$obs.nhits <- with(data, obs.phits * npos)
    data$obs.nfa <- with(data, obs.pfa * nneg)
    data$pred.nhits <- with(data, pred.phits * npos)
    data$pred.nfa <- with(data, pred.pfa * nneg)

    fit <- list(data=data, out=output,
                rsq=with(data,
                  cor(c(obs.phits, obs.pfa), c(pred.phits, pred.pfa))^2),
                rule="max", crit="SSE", type="proportions")
    save(fit, file=outfile)
}

FitPMaxCapSSE()
rm(FitPMaxCapSSE)

