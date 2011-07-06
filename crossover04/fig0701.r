### fig0701.r: plot individual observed and predicted d' as a function of
### setsize, separated by stim set

f.fig0701 <- function () {
    infile <- "data07.rda"
    outfile <- "fig0701.pdf"
    ## error checking
    on.exit(if (exists("opar")) par(opar))
    on.exit(while (dev.cur() != 1) dev.off(), add=TRUE)
    load(infile)

    ## define plot parameters (ordering is 2v5, orientation)
    col <- c("green4", "blue")
    bg <- c("white", "white")
    pch <- c(21, 22)
    lty <- c(1, 1)
    lwd <- c(2, 2)
    cex <- c(1.5, 1.5)
    lty.model <- c(1, 1)
    lwd.model <- c(2, 2)
    ylim <- c(0, 5)

    ## open PDF file
    pdf(outfile, width = 9, height = 6, pointsize = 12)
    opar <- par(mfrow = c(2, 3), las = 1, pty = "m", cex.axis = .6,
                xpd = NA, bg = "white")

    ## extract data
    obse <- with(data07$data,
                 tapply(obse.dprime, list(setsize, cond, sub), mean))
    pred <- with(data07$data,
                 tapply(pred.dprime, list(setsize, cond, sub), mean))
    x <- as.numeric(dimnames(obse)[[1]])
    conditions <- dimnames(obse)[[2]]

    ## assign names to plotting parameters
    names(col) <- names(bg) <- names(pch) <- names(lty) <- names(lwd) <-
        names(cex) <- names(lty.model) <- names(lwd.model) <- conditions

    counter <- 0
    for (sub in dimnames(obse)[[3]]) {
        matplot(x, obse[, , sub], type="n", axes=F, ylim=ylim,
                xlab="", ylab="", main=sub)
        axis(1, x)
        axis(2)
        for (cond in dimnames(obse)[[2]]) {
            lines(x, pred[, cond, sub], type="l",
                  col=col[cond],
                  lty=lty.model[cond], lwd=lwd.model[cond])
            lines(x, obse[, cond, sub], type="p",
                  col=col[cond], lty=lty[cond], lwd=lwd[cond],
                  pch=pch[cond], bg=bg[cond], cex=cex[cond])
        }
        if (counter %% 6 >= 0) title(xlab = "Setsize")
        if (counter %% 3 >= 0) title(ylab = "d'")
        if (counter %% 6 == 2) {
            legend("bottom", dimnames(obse)[[2]],
                   inset=c(0, -1),
                   bty="n", ncol=1, cex=1.0,
                   col=col, pch=pch, pt.bg=bg, lty=lty, lwd=lwd)
        }
        counter <- counter + 1
    }
}


f.fig0701()
rm(f.fig0701)
