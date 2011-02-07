### ComputeDprime.r: Provides a function to calculate d' from the number of
### hits, false alarms, total positive trials, and total negative trials.
###
### Returns a list with elements dprime, criterion, and ci.  The last
### element is the 95% confidence intervals around d'.

ComputeDprime <- function (nhits, nfa, npos, nneg, correction=0.5) {
    ## correct HR for {0,1}
    adjHR <- nhits
    index <- adjHR == 0
    if (any(index)) adjHR[index] <- 0.5
    index <- adjHR == npos
    if (any(index)) adjHR[index] <- npos[index] - 0.5
    adjHR <- adjHR / npos

    ## correct FA for {0,1}
    adjFA <- nfa
    index <- adjFA == 0
    if (any(index)) adjFA[index] <- 0.5
    index <- adjFA == nneg
    if (any(index)) adjFA[index] <- nneg[index] - 0.5
    adjFA <- adjFA / nneg

    ## compute d' and criterion
    dprime <- qnorm(adjHR) - qnorm(adjFA)
    crit <- -0.5 * (qnorm(adjHR) + qnorm(adjFA))

    ## compute CI around d'
    phiFA <- 1 / sqrt(2 * pi) * exp(-0.5 * qnorm(adjFA))
    phiHR <- 1 / sqrt(2 * pi) * exp(-0.5 * qnorm(adjHR))
    ci <- 1.96 * sqrt(adjHR * (1 - adjHR) / npos / (phiHR^2) +
                      adjFA * (1 - adjFA) / nneg / (phiFA^2))

    return(list(dprime=dprime, criterion=crit, ci=ci))
}
