### Fit a max-rule search model to each subject's hit rate and false-alarm
### rate using a maximum likehihood procedure.
###
### This version is based on an unlimited-capacity model, one criterion
### across setsizes, and collapses across the palmer flag.

FitMaxML <- function () {
    thisfile <- "FitMaxML.r"
    infile <- "data00.rda"
    outfile <- "FitMaxML.rda"

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
    if (!file.exists("maxrulelike.r"))
        stop("cannot open file maxrulelike.r")
    source("maxrulelike.r")

### Prepare data and output

    if (is.factor(data00$setsize))
        data00$setsize <- as.numeric(as.character(data00$setsize))

    subjects <- sort(levels(factor(data00$sub)))
    stimsets <- sort(levels(factor(data00$cond)))
    setsizes <- sort(unique(data00$setsize))

    nSubjects <- length(subjects)
    nStimsets <- length(stimsets)
    nSetsizes <- length(setsizes)

    factors <- with(data00, list(sub, cond, setsize))
    npos <- with(data00, tapply(npos, factors, sum))
    nneg <- with(data00, tapply(nneg, factors, sum))
    obs.nhits <- with(data00, tapply(nhits, factors, sum))
    obs.nfa <- with(data00, tapply(nfa, factors, sum))

    pred.nhits <- array(NA, dim(obs.nhits), dimnames(obs.nhits))
    pred.nfa <- array(NA, dim(obs.nfa), dimnames(obs.nfa))

    output <- array(NA, dim=c(nSubjects, 9, nStimsets),
                    dimnames=list(subjects,
                      c("s", "c", "k",
                        "iter", "code", "ml", "rmse", "r", "rsq"),
                      stimsets))

### Fit function
    GoodnessOfFit <- function (p, obs) {
        return(-1 * maxrulelike(obs$nhits, obs$nfa, obs$npos, obs$nneg,
                                setsizes, p[1], p[2]))
    }

### Actual fitting

    for (sub in subjects) {
        for (cond in stimsets) {
            p <- c(3, 2) # sensitivity and criterion
            obs <- list(nhits=obs.nhits[sub, cond, ],
                        nfa=obs.nfa[sub, cond, ],
                        npos=npos[sub, cond, ],
                        nneg=nneg[sub, cond, ])
            o <- nlminb(p, GoodnessOfFit, obs=obs)

            output[sub, "s", cond] <- o$par[1]
            output[sub, "c", cond] <- o$par[2]
            output[sub, "k", cond] <- Inf
            output[sub, "iter", cond] <- o$iterations
            output[sub, "code", cond] <- o$convergence
            output[sub, "ml", cond] <- GoodnessOfFit(o$par, obs)

            ## Store predicted counts
            pred <- maxrule(o$par[1], o$par[2], setsizes)
            pred$nhits <- pred$hr * npos[sub, cond, ]
            pred$nfa <- pred$fa * nneg[sub, cond, ]
            pred.nhits[sub, cond, ] <- pred$nhits
            pred.nfa[sub, cond, ] <- pred$nfa

            output[sub, "rmse", cond] <-
                sqrt(mean((c(pred$nhits, pred$nfa) -
                           c(obs$nhits, obs$nfa)) ^ 2))
            output[sub, "r", cond] <-
                cor(c(pred$nhits, pred$nfa), c(obs$nhits, obs$nfa))
            output[sub, "rsq", cond] <- output[sub, "r", cond] ^ 2
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
                rule="max", crit="ML")
    save(fit, file=outfile)
    print(output)
}

FitMaxML()
rm(FitMaxML)

