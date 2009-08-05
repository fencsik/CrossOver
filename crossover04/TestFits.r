### Perform a generalized likelihood ratio test comparing the unlimited
### capacity max-rule models to the limited capacity max-rule models to
### determine whether the additional capacity parameter is justified.
###
### Analyses are specified in pairs, with the first member of each pair
### being the numerator and the second being the denominator in the ratio.

GLRT.Max <- function () {
    analyses <- matrix(c("FitMaxSSE", "FitMaxCapSSE",
                         "FitMaxML", "FitMaxCapML"),
                       nrow=2)

    thisfile <- "GLRT-Max.r"
    infiles <- paste(analyses, ".rda", sep="")
    outfile <- "GLRT-Max.txt"

    on.exit(while (sink.number() > 0) sink())
    on.exit(while (substr(search()[2], 1, 7) != "package") detach())

    if (IsFileUpToDate(outfile, c(thisfile, infiles))) {
        warning("Output file is up to date, no action taken")
        return(invisible(NULL))
    }

    if (!file.exists("maxrulelike.r")) stop("cannot find maxrulelike.r")
    source("maxrulelike.r")

    sink(outfile)

    for (i in 1:ncol(analyses)) {
        ## extract information from first analysis
        load(paste(analyses[1, i], ".rda", sep=""))
        attach(fit$data)
        factors <- list(sub, cond, setsize)
        npos1 <- tapply(npos, factors, sum)
        nneg1 <- tapply(nneg, factors, sum)
        nhits1 <- tapply(obs.nhits, factors, sum)
        nfa1 <- tapply(obs.nfa, factors, sum)
        detach()
        out1 <- fit$out

        ## extract information from second analysis
        load(paste(analyses[2, i], ".rda", sep=""))
        attach(fit$data)
        factors <- list(sub, cond, setsize)
        npos2 <- tapply(npos, factors, sum)
        nneg2 <- tapply(nneg, factors, sum)
        nhits2 <- tapply(obs.nhits, factors, sum)
        nfa2 <- tapply(obs.nfa, factors, sum)
        detach()
        out2 <- fit$out

        subjects <- dimnames(npos1)[[1]]
        stimsets <- dimnames(npos1)[[2]]
        setsizes <- as.numeric(dimnames(npos1)[[3]])
        stats <- array(NA, dim=c(length(subjects), 2, length(stimsets)),
                       dimnames=list(subjects, c("ratio", "p"),
                         stimsets))

        for (s in subjects) {
            for (stim in stimsets) {
                llike1 <-
                    maxrulelike(nhits1[s, stim, ], nfa1[s, stim, ],
                                npos1[s, stim, ], nneg1[s, stim, ],
                                setsizes,
                                out1[s, "s", stim],
                                out1[s, "c", stim],
                                out1[s, "k", stim])
                llike2 <-
                    maxrulelike(nhits2[s, stim, ], nfa2[s, stim, ],
                                npos2[s, stim, ], nneg2[s, stim, ],
                                setsizes,
                                out2[s, "s", stim],
                                out2[s, "c", stim],
                                out2[s, "k", stim])
                stats[s, "ratio", stim] <- x <- -2 * (llike1 - llike2)
                stats[s, "p", stim] <-
                    1 - pchisq(stats[s, "ratio", stim], 1)
            }
        }
        cat(analyses[1, i], "vs.", analyses[2, i], "\n")
        print(round(stats, 6))
        cat("\n\n")
    }
    sink()
}

GLRT.Max()
rm(GLRT.Max)
