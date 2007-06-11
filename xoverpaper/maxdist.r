### maxdist.r: test formulations for max model distributions
###
### $LastChangedDate$

maxdist <- function () {
   thisfile <- "maxdist.r";
   outfile <- "maxdist.pdf";

   exit.function <- function () {
      if (exists("opar")) par(opar);
      if (any(names(dev.cur()) == c("postscript", "pdf"))) dev.off();
   }
   on.exit(exit.function());

   ## adjustable settings
   dprime <- 1.5;
   setsize <- 4;
   ntrials <- 200000;
   xval <- seq(-3, 5, by = .01);

   ## plot settings
   ylim <- c(0, .6);
   col.raw <- rainbow(2, s = 0.25);
   col.max <- rainbow(2, s = 1.0);
   lwd.pred <- 1;
   lwd.obse <- 2;

   ## open pdf file
   pdf(outfile, width = 9.5, height = 7, pointsize = 12);
   opar <- par(mfrow = c(1, 1), las = 1, pty = "m", cex.axis = .6,
               xpd = NA, bg = "transparent");

   ## compute
   criterion <- dprime / 2.0;
   target <- rep(c(0, 1), rep(ntrials, 2));
   values <- matrix(rnorm(setsize * ntrials * 2),
                    ncol = setsize, nrow = ntrials * 2);
   values[target == 1, 1] <- rnorm(sum(target == 1), mean = dprime);
   maxval <- apply(values, 1, max);

   ## plot raw theoretical distributions
   pred.raw <- matrix(NA, ncol = 2, nrow = length(xval));
   pred.raw[, 1] <- dnorm(xval);
   pred.raw[, 2] <- dnorm(xval, mean = dprime);
   matplot(xval, pred.raw, type = "l", ylim = ylim,
           xlab = "Signal value", ylab = "Proportion", bty = "l",
           col = col.raw, lwd = lwd.pred, lty = 1);

###    h1 <- hist(matrix(values[target == 0, ], ncol = 1), breaks = 30, plot = F);
###    h2 <- hist(matrix(values[target == 1, 1], ncol = 1), breaks = 30, plot = F);
###    lines(h1$mids, h1$density, col = col.max[1], lwd = lwd.obse, lty = 1);
###    lines(h2$mids, h2$density, col = col.max[2], lwd = lwd.obse, lty = 1);

   ## plot max empirical distributions
   h1 <- hist(maxval[target == 0], plot = F, breaks = "FD");
   h2 <- hist(maxval[target == 1], plot = F, breaks = "FD");
   print(length(h1$mids));
   print(length(h2$mids));
   lines(h1$mids, h1$density, col = col.max[1], lwd = lwd.obse, lty = 1);
   lines(h2$mids, h2$density, col = col.max[2], lwd = lwd.obse, lty = 1);

   ## plot max theoretical distributions
   lines(xval, setsize * dnorm(xval) * pnorm(xval) ^ (setsize - 1),
         col = col.max[1], lwd = lwd.pred, lty = 1);
   lines(xval,
         dnorm(xval, mean = dprime) * pnorm(xval) ^ (setsize - 1) +
         (setsize - 1) * dnorm(xval) * pnorm(xval, mean = dprime) * pnorm(xval) ^ (setsize - 2),
         col = col.max[2], lwd = lwd.pred, lty = 1);

}

maxdist();
rm(maxdist);
