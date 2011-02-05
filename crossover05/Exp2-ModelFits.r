### Exp2-ModelFits.r: output a tab-delimited table of the observed and
### predicted hit rate, false-alarm rate, and d' for both the unlimited-
### and limited-capacity models from data03 and data04

f.exp2.modelfits <- function () {
    infile1 <- "data03.rda"
    infile2 <- "data04.rda"
    outfile <- "Exp2-ModelFits.txt"
    load(infile1)
    dt.unlim <- data03$data
    load(infile2)
    dt.lim <- data04$data

    dt.out <- dt.unlim[, c("sub", "cond", "setsize")]
    dt.out$hr.obse <- with(dt.unlim, obse.nhits / npos)
    dt.out$fa.obs <- with(dt.unlim, obse.nfa / nneg)
    unlim <- with(dt.unlim,
                  data.frame(hr.pred.u=pred.nhits / npos,
                             fa.pred.u=pred.nfa / nneg))
    lim <- with(dt.lim,
                data.frame(hr.pred.l=pred.nhits / npos,
                           fa.pred.l=pred.nfa / nneg))
    dt.out <- cbind(dt.out, unlim, lim)
    dt.out$dprime.obse <- dt.unlim$obse.dprime
    dt.out$dprime.pred.u <- dt.unlim$pred.dprime
    dt.out$dprime.pred.l <- dt.unlim$pred.dprime

    write.table(dt.out, file=outfile, quote=FALSE, sep="\t",
                row.names=FALSE)
}

f.exp2.modelfits()
rm(f.exp2.modelfits)
