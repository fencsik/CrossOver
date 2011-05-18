### tab0602.r: goodness-of-fit tests comparing unlimited- to
### limited-capacity models with fixed capacity.  Tests include the
### generalized likelihood ratio test, Akaike information criterion (AIC),
### and Bayes information criterion (BIC).

f.tab0602 <- function () {
    an1 <- "data05"
    an2 <- "data06"
    nPar1 <- 2
    nPar2 <- 3
    outfile <- "tab0602.txt"
    log.like.file <- "logLikeBinom.r"
    source(log.like.file)

    myeval <- function (s, env=parent.frame()) {
        eval(parse(text=s), envir=env)
    }

    on.exit(while (sink.number() > 0) sink())
    on.exit(while (substr(search()[2], 1, 7) != "package") detach(), TRUE)

    for (i in as.character(1:2)) {
        myeval(sprintf("name <- an%s", i))
        load(sprintf("%s.rda", name))
        myeval(sprintf("attach(%s$data)", name))
        factors <- list(sub, cond, setsize)
        myeval(sprintf("npos%s <- tapply(npos, factors, sum)", i))
        myeval(sprintf("nneg%s <- tapply(nneg, factors, sum)", i))
        myeval(sprintf("nhits%s <- tapply(obse.nhits, factors, sum)", i))
        myeval(sprintf("nfa%s <- tapply(obse.nfa, factors, sum)", i))
        detach()
        myeval(sprintf("par%s <- %s$par", i, name))
    }

    indexc1 <- grep("c[1-9]{0,3}$", dimnames(par1)[[2]])
    indexc2 <- grep("c[1-9]{0,3}$", dimnames(par2)[[2]])

    subjects <- dimnames(npos1)[[1]]
    stimsets <- dimnames(npos1)[[2]]
    setsizes <- as.numeric(dimnames(npos1)[[3]])
    stats <- array(NA, dim=c(length(subjects), 7, length(stimsets)),
                   dimnames=list(subjects,
                     c("glrt", "df", "p",
                       "aic1", "aic2", "bic1", "bic2"),
                     stimsets))

    for (s in subjects) {
        for (stim in stimsets) {
            index <- par1$sub==s & par1$cond==stim
            llike1 <-
                logLikeBinom(nhits1[s, stim, ], nfa1[s, stim, ],
                             npos1[s, stim, ], nneg1[s, stim, ],
                             setsizes,
                             par1[index, "s"],
                             as.numeric(par1[index, indexc1]),
                             par1[index, "k"], correct=0.5)
            nobs1 <- sum(npos1[s, stim, ] + nneg1[s, stim, ])
            stats[s, "aic1", stim] <- 2 * nPar1 - 2 * llike1
            stats[s, "bic1", stim] <-
                nPar1 * log(nobs1) - 2 * llike1

            index <- par2$sub==s & par2$cond==stim
            llike2 <-
                logLikeBinom(nhits2[s, stim, ], nfa2[s, stim, ],
                             npos2[s, stim, ], nneg2[s, stim, ],
                             setsizes,
                             par2[index, "s"],
                             as.numeric(par2[index, indexc2]),
                             par2[index, "k"], correct=0.5)
            nobs2 <- sum(npos2[s, stim, ] + nneg2[s, stim, ])
            stats[s, "aic2", stim] <- 2 * nPar2 - 2 * llike2
            stats[s, "bic2", stim] <-
                nPar2 * log(nobs2) - 2 * llike2

            stats[s, "glrt", stim] <- x <- -2 * (llike1 - llike2)
            stats[s, "df", stim] <- df <- nPar2 - nPar1
            stats[s, "p", stim] <- 1 - pchisq(x, df)
        }
    }
    sink(outfile)
    print(round(stats, 6))
    cat("\n\n")
    sink()
}

f.tab0602()
rm(f.tab0602)
