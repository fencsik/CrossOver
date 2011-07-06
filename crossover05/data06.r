### data06.r: fits a max-rule model to the data.
###
### Assumptions: limited capacity, fixed criterion
###
### Fit Procedure: maximum likelihood

f.data06 <- function () {
    infile <- "data02.rda"
    outfile <- "data06.rda"
    max.rule.file <- "maxrule.r"
    compute.dprime.file <- "ComputeDprime.r"
    load(infile)
    source(max.rule.file)
    source(compute.dprime.file)
    starting.k <- list(list(AMS=2, ATM=2, CAC=4, CMB=4, EMP=2),
                       list(AMS=2, ATM=2, CAC=4, CMB=4, EMP=5))
    names(starting.k) <- c("2v5", "Orientation")

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
    obse.nhits <- with(data02, tapply(nhits, factors, sum))
    obse.nfa <- with(data02, tapply(nfa, factors, sum))

    pred.nhits <- array(NA, dim(obse.nhits), dimnames(obse.nhits))
    pred.nfa <- array(NA, dim(obse.nfa), dimnames(obse.nfa))

    output <- array(NA, dim=c(n.subjects, 9, n.stimsets),
                    dimnames=list(all.subjects,
                      c("s", "c", "k",
                        "iter", "code", "ml", "rmse", "r", "rsq"),
                      all.stimsets))

### Define fit function
    GoodnessOfFit <- function (p, obse) {
        return(-1 * logLikeBinom(obse$nhits, obse$nfa, obse$npos, obse$nneg,
                                 all.setsizes, p[1], p[2], capacity=p[3],
                                 correct=FALSE))
    }

### Actual fitting

    for (sub in all.subjects) {
        for (cond in all.stimsets) {
            p <- c(3, 2, starting.k[[cond]][[sub]])
            obse <- list(nhits=obse.nhits[sub, cond, ],
                        nfa=obse.nfa[sub, cond, ],
                        npos=npos[sub, cond, ],
                        nneg=nneg[sub, cond, ])
            o <- nlminb(p, GoodnessOfFit, obse=obse)

            output[sub, "s", cond] <- o$par[1]
            output[sub, "c", cond] <- o$par[2]
            output[sub, "k", cond] <- o$par[3]
            output[sub, "iter", cond] <- o$iterations
            output[sub, "code", cond] <- o$convergence
            output[sub, "ml", cond] <- GoodnessOfFit(o$par, obse)

            ## Store predicted counts
            pred <- maxrule(o$par[1], o$par[2],
                            all.setsizes, o$par[3])
            pred$nhits <- pred$hr * npos[sub, cond, ]
            pred$nfa <- pred$fa * nneg[sub, cond, ]
            pred.nhits[sub, cond, ] <- pred$nhits
            pred.nfa[sub, cond, ] <- pred$nfa

            output[sub, "rmse", cond] <-
                sqrt(mean((c(pred$nhits, pred$nfa) -
                           c(obse$nhits, obse$nfa)) ^ 2))
            output[sub, "r", cond] <-
                cor(c(pred$nhits, pred$nfa), c(obse$nhits, obse$nfa))
            output[sub, "rsq", cond] <- output[sub, "r", cond] ^ 2
        }
    }

### convert back to data frames
    data <- as.data.frame(as.table(npos))
    names(data) <- c("sub", "cond", "setsize", "npos")
    data$nneg <- as.data.frame(as.table(nneg))$Freq
    data$obse.nhits <- as.data.frame(as.table(obse.nhits))$Freq
    data$obse.nfa <- as.data.frame(as.table(obse.nfa))$Freq
    data$pred.nhits <- as.data.frame(as.table(pred.nhits))$Freq
    data$pred.nfa <- as.data.frame(as.table(pred.nfa))$Freq
    data <- data[with(data, order(sub, cond, setsize)), ]
    rownames(data) <- 1:length(rownames(data))

    ## compute observed and predicted dprime
    data$obse.dprime <- ComputeDprime(data$obse.nhits, data$obse.nfa,
                                      data$npos, data$nneg)$dprime
    data$pred.dprime <- ComputeDprime(data$pred.nhits, data$pred.nfa,
                                      data$npos, data$nneg)$dprime

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
    param <- param[with(param, order(cond, sub)), ]

    data06 <- list(data=data, par=param,
                rsq=with(data,
                  cor(c(obse.nhits, obse.nfa), c(pred.nhits, pred.nfa))^2),
                rule="max", crit="ML", type="counts")
    save(data06, file=outfile)
}

f.data06()
rm(f.data06)
