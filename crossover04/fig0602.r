### fig0602.r: plot individual observed and predicted hit and CR rates as a
### function of setsize, with separate plots for each stim set

f.fig0602 <- function () {
    infile <- "data06.rda"
    outfile <- "fig0602.pdf"
    ## error checking
    on.exit(if (exists("opar")) par(opar))
    on.exit(while (dev.cur() != 1) dev.off(), add=TRUE)
    load(infile)

    ## define stim-set plot parameters (ordering is hit, CR)
    dvs <- c("Hits", "CR")
    col <- c("green4", "blue")
    bg <- c("white", "white")
    pch <- c(21, 22)
    lty <- c(1, 1)
    lwd <- c(2, 2)
    cex <- c(1.5, 1.5)
    lty.model <- c(1, 1)
    lwd.model <- c(2, 2)
    ylim <- c(0.5, 1.0)

    ## open PDF file
    pdf(outfile, width = 6, height = 6, pointsize = 12)
    opar <- par(mfrow = c(2, 2), las = 1, pty = "m", cex.axis = .6,
                xpd = NA, bg = "white")

    ## extract data
    npos <- with(data06$data,
                       tapply(npos, list(setsize, cond, sub), sum))
    nneg <- with(data06$data,
                       tapply(nneg, list(setsize, cond, sub), sum))
    obse.nhits <- with(data06$data,
                       tapply(obse.nhits, list(setsize, cond, sub), sum))
    obse.nfa <- with(data06$data,
                     tapply(obse.nfa, list(setsize, cond, sub), sum))
    pred.nhits <- with(data06$data,
                       tapply(pred.nhits, list(setsize, cond, sub), sum))
    pred.nfa <- with(data06$data,
                     tapply(pred.nfa, list(setsize, cond, sub), sum))
    obse <- list()
    pred <- list()
    obse[["Hits"]] <- obse.nhits / npos
    obse[["CR"]] <- 1 - obse.nfa / nneg
    pred[["Hits"]] <- pred.nhits / npos
    pred[["CR"]] <- 1 - pred.nfa / nneg
    x <- as.numeric(dimnames(obse.nhits)[[1]])
    conditions <- dimnames(obse.nhits)[[2]]

    ## assign names to plotting parameters
    names(col) <- names(bg) <- names(pch) <- names(lty) <- names(lwd) <-
        names(cex) <- names(lty.model) <- names(lwd.model) <- dvs

    counter <- 0
    for (sub in dimnames(obse[["Hits"]])[[3]]) {
        for (cond in dimnames(obse[["Hits"]])[[2]]) {
            matplot(x, obse[["Hits"]][, , sub], type="n", axes=F, ylim=ylim,
                    xlab="", ylab="", main=paste(sub, cond))
            axis(1, x)
            axis(2)
            for (dv in dvs) {
                lines(x, pred[[dv]][, cond, sub], type="l",
                      col=col[dv],
                      lty=lty.model[dv], lwd=lwd.model[dv])
                lines(x, obse[[dv]][, cond, sub], type="p",
                      col=col[dv], lty=lty[dv], lwd=lwd[dv],
                      pch=pch[dv], bg=bg[dv], cex=cex[dv])
                if (counter %% 4 >= 2) title(xlab = "Setsize")
                if (counter %% 2 == 0) title(ylab = "Proportion")
                if (counter %% 4 == 0) {
                    legend("bottomright", dvs,
                           inset=c(-0.5, -0.75),
                           bty="n", ncol=2, cex=1.0,
                           col=col, pch=pch, pt.bg=bg, lty=lty, lwd=lwd)
                }
            }
            counter <- counter + 1
        }
    }
}


f.fig0602()
rm(f.fig0602)
