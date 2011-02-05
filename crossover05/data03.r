### data03.r: fits a max-rule model to the data.
###
### Assumptions: unlimited capacity, variable criterion
###
### Fit Procedure: maximum likelihood

f.data03 <- function () {
    infile <- "data02.rda"
    outfile <- "data03.rda"
    max.rule.file <- "maxrule.r"
    log.like.file <- "logLikeBinom.r"
    load(infile)
    source(max.rule.file)
    source(log.like.file)

### Prepare data and output

    if (is.factor(data02$setsize))
        data02$setsize <- as.numeric(as.character(data02$setsize))

    all.subjects <- sort(levels(factor(data02$sub)))
    all.stimsets <- sort(levels(factor(data02$cond)))
    all.setsizes <- sort(unique(data02$setsize))
    n.subjects <- length(all.subjects)
    n.stimsets <- length(all.stimsets)
    n.setsizes <- length(all.setsizes)

    factors <- with(data02, list(sub, cond, setsize))
    npos <- with(data02, tapply(npos, factors, sum))
    nneg <- with(data02, tapply(nneg, factors, sum))
    obs.nhits <- with(data02, tapply(nhits, factors, sum))
    obs.nfa <- with(data02, tapply(nfa, factors, sum))

    pred.nhits <- array(NA, dim(obs.nhits), dimnames(obs.nhits))
    pred.nfa <- array(NA, dim(obs.nfa), dimnames(obs.nfa))

    output <- array(NA, dim=c(n.subjects, 8 + n.setsizes, n.stimsets),
                    dimnames=list(all.subjects,
                      c("s", paste("c", all.setsizes, sep=""), "k",
                        "iter", "code", "ml", "rmse", "r", "rsq"),
                      all.stimsets))

### Define fit function
    GoodnessOfFit <- function (p, obs) {
        return(-1 * logLikeBinom(obs$nhits, obs$nfa, obs$npos, obs$nneg,
                                 all.setsizes, p[1], p[2:(n.setsizes+1)],
                                 capacity=Inf, correct=TRUE))
    }

### Actual fitting

    for (sub in all.subjects) {
        for (cond in all.stimsets) {
            p <- c(3, rep(2, n.setsizes)) # sens and crit
            obs <- list(nhits=obs.nhits[sub, cond, ],
                        nfa=obs.nfa[sub, cond, ],
                        npos=npos[sub, cond, ],
                        nneg=nneg[sub, cond, ])
            o <- nlminb(p, GoodnessOfFit, obs=obs)

            output[sub, "s", cond] <- o$par[1]
            output[sub, paste("c", all.setsizes, sep=""), cond] <-
                o$par[2:(n.setsizes+1)]
            output[sub, "k", cond] <- Inf
            output[sub, "iter", cond] <- o$iterations
            output[sub, "code", cond] <- o$convergence
            output[sub, "ml", cond] <- GoodnessOfFit(o$par, obs)

            ## Store predicted counts
            pred <- maxrule(o$par[1], o$par[2:(n.setsizes+1)],
                            all.setsizes, o$par[n.setsizes+2])
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

    ## convert output/parameters to a data frame
    first <- TRUE
    for (i in dimnames(output)[[2]]) {
        if (first) {
            param <- as.data.frame(as.table(output[, i, ]))
            names(param) <- c("sub", "cond", i)
            first <- FALSE
        } else {
            eval(parse(text=sprintf("param$%s <- as.data.frame(as.table(output[,i,]))$Freq", i)))
        }
    }

    data03 <- list(data=data, par=param,
                rsq=with(data,
                  cor(c(obs.nhits, obs.nfa), c(pred.nhits, pred.nfa))^2),
                rule="max", crit="ML", type="counts")
    save(data03, file=outfile)
}

f.data03()
rm(f.data03)
