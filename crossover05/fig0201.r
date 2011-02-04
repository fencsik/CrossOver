### fig0201.r: plot individual d' as a function of setsize, separated by
### stim set

f.fig0201 <- function () {
    infile <- "data02.rda"
    outfile <- "fig0201.pdf"
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
    ylim <- c(0, 5)

    ## open PDF file
    pdf(outfile, width = 9, height = 6, pointsize = 12)
    opar <- par(mfrow = c(2, 3), las = 1, pty = "m", cex.axis = .6,
                xpd = NA, bg = "white")

    ## extract data
    dp <- with(data02, tapply(dprime, list(setsize, cond, subject), mean))
    err <- with(data02, tapply(dpci, list(setsize, cond, subject), mean))
    x <- as.numeric(dimnames(dp)[[1]])
    conditions <- dimnames(dp)[[2]]

    ## assign names to plotting parameters
    names(col) <- names(bg) <- names(pch) <- names(lty) <- names(lwd) <-
        names(cex) <- conditions

    counter <- 0
    for (sub in dimnames(dp)[[3]]) {
        matplot(x, dp[, , sub], type="n", axes=F, ylim=ylim,
                xlab="", ylab="", main=toupper(sub))
        axis(1, x)
        axis(2)
        for (cond in dimnames(dp)[[2]]) {
            dp1 <- dp[, cond, sub]
            er1 <- err[, cond, sub]
            arrows(x, dp1 - er1, x, dp1 + er1,
                   length=.03, angle=90, code=3,
                   col=col[cond], lty=1, lwd=1)
            lines(x, dp1, type="o",
                  col=col[cond], lty=lty[cond], lwd=lwd[cond],
                  pch=pch[cond], bg=bg[cond], cex=cex[cond])
        }
        if (counter %% 6 >= 0) title(xlab = "Setsize")
        if (counter %% 3 >= 0) title(ylab = "d'")
        if (counter %% 6 == 2) {
            legend("bottom", dimnames(dp)[[2]],
                   inset=c(0, -1),
                   bty="n", ncol=1, cex=1.0,
                   col=col, pch=pch, pt.bg=bg, lty=lty, lwd=lwd)
        }
        counter <- counter + 1
    }
}


f.fig0201()
rm(f.fig0201)
