### Plots averaged observed and predicted hit rates and false-alarm rates
### for all fits present in the current directory.

PlotFits <- function () {
    analyses <- c("FitMaxSSE",
                  "FitMaxCapSSE",
                  "FitMaxML",
                  "FitMaxCapML",
                  "FitMaxPaper",
                  "FitMaxCapPaper")
    
    thisfile <- "PlotFits.r"
    infiles <- paste(analyses, ".rda", sep="")
    outfiles <- paste(analyses, ".pdf", sep="")

    if (IsFileUpToDate(outfiles, c(thisfile, infiles))) {
        warning("Output files are up to date, no action taken")
        return(invisible(NULL))
    }

    ## Plot settings
    ylim <- c(0, 1)
    pt.cex <- 1.5
    pt.bg <- "white"
    col <- c("navy", "orange") # HR and FA
    pch <- c(21, 21) # HR and FA
    lty <- c(1, 2) # obs and pred
    lwd <- c(2, 2) # obs and pred

    on.exit(if (exists("opar")) par(opar))
    on.exit(while (any(names(dev.cur()) == "pdf")) dev.off(), TRUE)

    for (i in seq_along(analyses)) {
        load(infiles[i])
        if (!exists("fit")) stop("fit not found in ", infiles[i])

        pdf(file=outfiles[i], width=9.5, height=6)
        opar <- par(mfrow=c(1, 2), las=1, pty="s", bg="white")

        factors <- with(fit$data, list(setsize, cond))
        obs.hr <- with(fit$data,
                       tapply(obs.nhits / npos, factors, mean))
        obs.fa <- with(fit$data,
                       tapply(obs.nfa / nneg, factors, mean))
        pred.hr <- with(fit$data,
                        tapply(pred.nhits / npos, factors, mean))
        pred.fa <- with(fit$data,
                        tapply(pred.nfa / nneg, factors, mean))
        x <- as.numeric(dimnames(obs.hr)[[1]])

        for (j in seq_along(dimnames(obs.hr)[[2]])) {
            cond <- dimnames(obs.hr)[[2]][j]
            plot(x, obs.hr[, cond], type="o",
                 bty="n", axes=F, ylim=ylim, xlab="", ylab="",
                 col=col[1], pch=pch[1], cex=pt.cex, bg=pt.bg,
                 lty=lty[1], lwd=lwd[1])
            lines(x, obs.fa[, cond], type="o",
                  col=col[2], pch=pch[2], cex=pt.cex, bg=pt.bg,
                  lty=lty[1], lwd=lwd[1])
            lines(x, pred.hr[, cond], type="o",
                  col=col[1], pch=pch[1], cex=pt.cex, bg=pt.bg,
                  lty=lty[2], lwd=lwd[2])
            lines(x, pred.fa[, cond], type="o",
                  col=col[2], pch=pch[2], cex=pt.cex, bg=pt.bg,
                  lty=lty[2], lwd=lwd[2])
            axis(1, x)
            axis(2)
            title(main=paste(analyses[i], cond))
            title(xlab="Setsize")
            if (j == 1) title(ylab="Proportion")
        }
    }
}

PlotFits()
rm(PlotFits)
