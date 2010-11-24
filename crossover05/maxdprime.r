### Calculate sensitivity and criterion for a search task assuming that
### response is based on the maximum of target and distractor signals.
###
### Currently, requires hit rate (hr), false-alarm rate (fa), and setsize
### to be vectors of length N such that N is the same for each.  Capacity
### can be left out, or set to any single value.

maxdprime <- function (hr, fa, setsize, capacity=NULL) {

    ## Need to add error-checking to ensure dimensions are correct

    ## If no capacity given, then set capacity to max setsize, which
    ## effectively means unlimited capacity
    if (is.null(capacity) || capacity < 0) {
        capacity <- max(setsize)
        limitedCapacity <- FALSE
    } else {
        limitedCapacity <- TRUE
    }

    k <- pmin(setsize, capacity)
    n <- setsize

    crit <- qnorm((1 - fa) ^ (1 / k))
    p <- pnorm(crit)
    sens <- crit -
        qnorm(n * (1 - hr) / k / (p ^ (k - 1)) - (n - k) / k * p)

    if (!limitedCapacity)
        capacity <- NULL

    return(list(sensitivity=sens, criterion=crit))
}
