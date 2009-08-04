### Fit a max-rule search model to each subject's hit rate and false-alarm
### rate using a maximum likehihood procedure.
###
### This version is based on a limited-capacity model, one criterion
### across setsizes, and collapses across the palmer flag.

FitMaxCapML <- function () {
    thisfile <- "FitMaxCapML.r"
    infile <- "data00.rda"
    outfile <- "FitMaxCapML.rda"

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
    obs.npos <- with(data00, tapply(npos, factors, sum))
    obs.nneg <- with(data00, tapply(nneg, factors, sum))
    obs.hr <- with(data00, tapply(nhits, factors, sum))
    obs.fa <- obs.nneg - with(data00, tapply(ntneg, factors, sum))

    pred.hr <- array(NA, dim(obs.hr), dimnames(obs.hr))
    pred.fa <- array(NA, dim(obs.fa), dimnames(obs.fa))

    output <- array(NA, dim=c(nSubjects, 9, nStimsets),
                    dimnames=list(subjects,
                      c("s", "c", "k",
                        "iter", "code", "ml", "rmse", "r", "rsq"),
                      stimsets))

### Fit function
    GoodnessOfFit <- function (p, obs) {
        return(-1 * maxrulelike(obs$hr, obs$fa, obs$npos, obs$nneg,
                                setsizes, p[1], p[2], p[3]))
    }

### Actual fitting

    for (sub in subjects) {
        for (cond in stimsets) {
            p <- c(3, 2, 4) # sensitivity, criterion, and capacity
            obs <- list(hr=obs.hr[sub, cond, ], fa=obs.fa[sub, cond, ],
                        npos=obs.npos[sub, cond, ],
                        nneg=obs.nneg[sub, cond, ])
            o <- nlminb(p, GoodnessOfFit, obs=obs)

            output[sub, "s", cond] <- o$par[1]
            output[sub, "c", cond] <- o$par[2]
            output[sub, "k", cond] <- o$par[3]
            output[sub, "iter", cond] <- o$iterations
            output[sub, "code", cond] <- o$convergence
            output[sub, "ml", cond] <- GoodnessOfFit(o$par, obs)

            pred <- maxrule(o$par[1], o$par[2], setsizes, o$par[3])
            pred.hr[sub, cond, ] <- pred$hr
            pred.fa[sub, cond, ] <- pred$fa

            ## convert observed hr and fa back to proportions
            obs$hr <- obs$hr / obs.npos[sub, cond, ]
            obs$fa <- obs$fa / obs.nneg[sub, cond, ]
            obs.hr[sub, cond, ] <- obs$hr
            obs.fa[sub, cond, ] <- obs$fa

            output[sub, "rmse", cond] <-
                sqrt(mean((c(pred$hr, pred$fa) - c(obs$hr, obs$fa)) ^ 2))
            output[sub, "r", cond] <-
                cor(c(pred$hr, pred$fa), c(obs$hr, obs$fa))
            output[sub, "rsq", cond] <- output[sub, "r", cond] ^ 2
        }
    }

### convert back to data frames
    data <- as.data.frame(as.table(obs.hr))
    names(data) <- c("sub", "cond", "setsize", "obs.hr")
    data$obs.fa <- as.data.frame(as.table(obs.fa))$Freq
    data$pred.hr <- as.data.frame(as.table(pred.hr))$Freq
    data$pred.fa <- as.data.frame(as.table(pred.fa))$Freq
    data <- data[with(data, order(sub, cond, setsize)), ]

    fit <- list(data=data, out=output,
                rsq=with(data,
                  cor(c(obs.hr, obs.fa), c(pred.hr, pred.fa))^2),
                rule="max", crit="ML")
    save(fit, file=outfile)
    print(output)
}

FitMaxCapML()
rm(FitMaxCapML)

