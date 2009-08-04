### Fit a max-rule search model to each subject's hit rate and false-alarm
### rate by varying the model's sensitivity and criterion to minimize
### sum-squared error between observed and predicted results.
###
### This version is based on a limited-capacity model, one criterion across
### setsizes, and collapses across the palmer flag.

FitMaxCapSSE <- function () {
    thisfile <- "FitMaxCapSSE.r"
    infile <- "data00.rda"
    outfile <- "FitMaxCapSSE.rda"

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

    factors <- with(data00, list(sub, cond, setsize))
    obs.hr <- with(data00, tapply(hr, factors, mean))
    obs.fa <- with(data00, tapply(fa, factors, mean))
    obs.npos <- with(data00, tapply(npos, factors, sum))
    obs.nneg <- with(data00, tapply(nneg, factors, sum))

    pred.hr <- array(NA, dim(obs.hr), dimnames(obs.hr))
    pred.fa <- array(NA, dim(obs.fa), dimnames(obs.fa))

    output <- array(NA, dim=c(nSubjects, 9, nStimsets),
                    dimnames=list(subjects,
                      c("s", "c", "k",
                        "iter", "code", "sse", "rmse", "r", "rsq"),
                      stimsets))

### Fit function
    GoodnessOfFit <- function (p, obs) {
        pred <- maxrule(p[1], p[2], setsizes, p[3])
        return(sum((c(obs$hr, obs$fa) - c(pred$hr, pred$fa)) ^ 2))
    }

### Actual fitting

    for (sub in subjects) {
        for (cond in stimsets) {
            p <- c(3, 2, 4) # sensitivity, criterion, and capacity
            obs <- list(hr=obs.hr[sub, cond, ], fa=obs.fa[sub, cond, ])
            o <- nlminb(p, GoodnessOfFit, obs=obs)

            output[sub, "s", cond] <- o$par[1]
            output[sub, "c", cond] <- o$par[2]
            output[sub, "k", cond] <- o$par[3]
            output[sub, "iter", cond] <- o$iterations
            output[sub, "code", cond] <- o$convergence
            output[sub, "sse", cond] <- GoodnessOfFit(o$par, obs)

            pred <- maxrule(o$par[1], o$par[2], setsizes, o$par[3])
            pred.hr[sub, cond, ] <- pred$hr
            pred.fa[sub, cond, ] <- pred$fa

            output[sub, "rmse", cond] <-
                sqrt(mean((c(pred$hr, pred$fa) - c(obs$hr, obs$fa)) ^ 2))
            output[sub, "r", cond] <-
                cor(c(pred$hr, pred$fa), c(obs$hr, obs$fa))
            output[sub, "rsq", cond] <- output[sub, "r", cond] ^ 2
        }
    }

### convert back to data frames
    data <- as.data.frame(as.table(obs.npos))
    names(data) <- c("sub", "cond", "setsize", "npos")
    data$nneg <- as.data.frame(as.table(obs.nneg))$Freq
    data$obs.hr <- as.data.frame(as.table(obs.hr))$Freq
    data$obs.fa <- as.data.frame(as.table(obs.fa))$Freq
    data$pred.hr <- as.data.frame(as.table(pred.hr))$Freq
    data$pred.fa <- as.data.frame(as.table(pred.fa))$Freq
    data <- data[with(data, order(sub, cond, setsize)), ]

    fit <- list(data=data, out=output,
                rsq=with(data,
                  cor(c(obs.hr, obs.fa), c(pred.hr, pred.fa))^2),
                rule="max", crit="SSE")
    save(fit, file=outfile)
    print(output)
}

FitMaxCapSSE()
rm(FitMaxCapSSE)

