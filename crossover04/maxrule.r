##### This file contains functions to help fit max-rule models to search
##### data.  It includes:
#####
##### 1. a function to calculate predicted hit and false-alarm rates based
#####    on a set of parameters
#####
##### 2. a function to calculate the log-likelihood of a given set of
#####    parameters based on a set of observed data

### Calculate predicted hit rate and false-alarm rate for a max-rule based
### search model, given sensitivity, criterion, setsize, and optionally a
### capacity and/or standard-deviation slope parameter.
###
### Sensitivity and criterion must be scalar, capacity can be scalar or
### empty, sdslope can be scalar or empty, and setsize can be a vector of
### any length greater than 0.

maxrule <- function (sensitivity, criterion, setsize, capacity, sdslope) {

    ## Error-checking
    if (missing(sensitivity) || length(sensitivity) != 1 ||
        !is.numeric(sensitivity))
        stop("sensitivity must be a single numeric value")
    if (missing(criterion) || length(criterion) < 1 ||
        !is.numeric(criterion) ||
        (!is.null(dim(criterion)) && length(criterion) != max(dim(criterion))))
        stop("criterion must be an Nx1 vector, with N >= 1")
    if (missing(setsize) || length(setsize) < 1 ||
        (!is.null(dim(setsize)) && length(setsize) != max(dim(setsize))))
        stop("setsize must be an Nx1 vector, with N >= 1")
    if (missing(capacity) || is.null(capacity) ||
        !is.finite(capacity) || capacity < 0) {
        capacity <- max(setsize)
        limitedCapacity <- FALSE
    } else if (length(capacity) != 1 || !is.numeric(capacity)) {
        stop("capacity must be a single value that is numeric, non-finite, or NULL")
    } else {
        limitedCapacity <- TRUE
    }
    if (missing(sdslope) || is.null(sdslope) || !is.finite(sdslope)) {
        sdslope <- NULL
    } else if (length(sdslope) != 1) {
        stop("sdslope must be empty, NULL, or a single number")
    }
    if (length(criterion) > 1 && length(criterion) != length(setsize)) {
        stop("criterion must be either a single value, or one per setsize")
    }

    k <- pmin(setsize, capacity)
    if (!is.null(sdslope)) {
        Phi <- function(x) pnorm(x, mean=0, sd=(setsize - 1) * sdslope + 1)
    } else {
        Phi <- function(x) pnorm(x, mean=0, sd=1)
    }

    fa <- 1 - Phi(criterion) ^ k
    hr <- 1 - k / setsize * Phi(criterion - sensitivity) *
        (Phi(criterion) ^ (k - 1)) - (setsize - k) / setsize *
            (Phi(criterion) ^ k)

    names(fa) <- NULL
    names(hr) <- NULL

    return(list(hr=hr, fa=fa))
}


### Compute log-likelihood of observing some data at some setsizes given a
### max rule search model with a particular sensitivity, criterion, and
### optionally a capacity and/or standard-deviation slope parameter.
### Assume accuracy data are i.i.d. binomial.
###
### The arguments hit and fa must be provided as counts, not proportions

logLikeBinom <- function(hit, fa, npos, nneg, setsize,
                         sensitivity, criterion, capacity, sdslope,
                         correct=NULL) {

    if (length(hit) != length(fa) ||
        length(hit) != length(npos) ||
        length(hit) != length(nneg))
        stop("all data arguments must have the same length")
    if (length(hit) != length(setsize))
        stop("hit rate and setsize must be the same length")

    pred <- maxrule(sensitivity, criterion, setsize, capacity, sdslope)

    if (!is.null(correct)) {
        if (correct == TRUE)
            correct <- 0.5
        ## correct 0s and 1s
        index <- round(pred$fa, 6) == 0
        if (any(index)) pred$fa[index] <- correct / nneg[index]
        index <- round(pred$fa, 6)  == 1
        if (any(index)) pred$fa[index] <- 1 - correct / nneg[index]
        index <- round(pred$hr, 6) == 0
        if (any(index)) pred$hr[index] <- correct / npos[index]
        index <- round(pred$hr, 6) == 1
        if (any(index)) pred$hr[index] <- 1 - correct / npos[index]
    }

    return(sum(log(dbinom(c(hit, fa), c(npos, nneg), c(pred$hr, pred$fa)))))
}
