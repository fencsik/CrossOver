### Perform various goodness-of-fit tests comparing limited-capacity and
### unlimited-capacity models.  Tests include the generalized likelihood
### ratio test, Akaike information criterion (AIC), and Bayes information
### criterion (BIC).
###
### Analyses are specified in rows, with each row containing the two models
### to compare, followed by the respective number of parameters of each
### model.

TestFits <- function () {
    analyses <- matrix(c("FitMaxSSE", "FitMaxCapSSE", 2, 3,
                         "FitMaxCritSSE", "FitMaxCapCritSSE", 5, 6,
                         "FitMaxML", "FitMaxCapML", 2, 3,
                         "FitMaxPaper", "FitMaxCapPaper", 2, 3),
                       ncol=4, byrow=T)

    thisfile <- "TestFits.r"
    infiles <- paste(analyses[, 1:2], ".rda", sep="")
    outfile <- "TestFits.txt"

    on.exit(while (sink.number() > 0) sink())
    on.exit(while (substr(search()[2], 1, 7) != "package") detach(), TRUE)

    if (IsFileUpToDate(outfile, c(thisfile, infiles, "logLikeBinom.r"))) {
        warning("Output file is up to date, no action taken")
        return(invisible(NULL))
    }

    if (!file.exists("logLikeBinom.r")) stop("cannot find logLikeBinom.r")
    source("logLikeBinom.r")

    sink(outfile)

    for (i in 1:nrow(analyses)) {
        ## extract information from first analysis
        load(paste(analyses[i, 1], ".rda", sep=""))
        attach(fit$data)
        factors <- list(sub, cond, setsize)
        npos1 <- tapply(npos, factors, sum)
        nneg1 <- tapply(nneg, factors, sum)
        nhits1 <- tapply(obs.nhits, factors, sum)
        nfa1 <- tapply(obs.nfa, factors, sum)
        detach()
        out1 <- fit$out

        ## extract information from second analysis
        load(paste(analyses[i, 2], ".rda", sep=""))
        attach(fit$data)
        factors <- list(sub, cond, setsize)
        npos2 <- tapply(npos, factors, sum)
        nneg2 <- tapply(nneg, factors, sum)
        nhits2 <- tapply(obs.nhits, factors, sum)
        nfa2 <- tapply(obs.nfa, factors, sum)
        detach()
        out2 <- fit$out

        k1 <- as.numeric(analyses[i, 3])
        k2 <- as.numeric(analyses[i, 4])

        indexc1 <- grep("c[1-9]{0,3}$", dimnames(out1)[[2]])
        indexc2 <- grep("c[1-9]{0,3}$", dimnames(out2)[[2]])

        subjects <- dimnames(npos1)[[1]]
        stimsets <- dimnames(npos1)[[2]]
        setsizes <- as.numeric(dimnames(npos1)[[3]])
        stats <- array(NA, dim=c(length(subjects), 6, length(stimsets)),
                       dimnames=list(subjects,
                         c("glrt", "p", "aic1", "aic2", "bic1", "bic2"),
                         stimsets))

        for (s in subjects) {
            for (stim in stimsets) {
                llike1 <-
                    logLikeBinom(nhits1[s, stim, ], nfa1[s, stim, ],
                                 npos1[s, stim, ], nneg1[s, stim, ],
                                 setsizes,
                                 out1[s, "s", stim],
                                 out1[s, indexc1, stim],
                                 out1[s, "k", stim], correct=0.5)
                stats[s, "aic1", stim] <- 2 * k1 - 2 * llike1
                stats[s, "bic1", stim] <-
                    k1 * log(200) - 2 * llike1

                llike2 <-
                    logLikeBinom(nhits2[s, stim, ], nfa2[s, stim, ],
                                 npos2[s, stim, ], nneg2[s, stim, ],
                                 setsizes,
                                 out2[s, "s", stim],
                                 out2[s, indexc2, stim],
                                 out2[s, "k", stim], correct=0.5)
                stats[s, "aic2", stim] <- 2 * k2 - 2 * llike2
                stats[s, "bic2", stim] <-
                    k2 * log(200) - 2 * llike2

                stats[s, "glrt", stim] <- x <- -2 * (llike1 - llike2)
                stats[s, "p", stim] <- 1 - pchisq(x, 1)
            }
        }
        cat(analyses[i, 1], "vs.", analyses[i, 2], "\n")
        print(round(stats, 6))
        cat("\n\n")
    }
    sink()
}

TestFits()
rm(TestFits)
