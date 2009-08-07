### Calculate predicted hit rate and false-alarm rate for a max-rule based
### search model, given sensitivity, criterion, setsize, and an optional
### capacity.
###
### Sensitivity and criterion must be scalar, capacity can be scalar or
### empty, and setsize can be a vector of any length greater than 0.

maxrule <- function (sensitivity, criterion, setsize, capacity) {

    ## Error-checking
    if (missing(sensitivity) || length(sensitivity) != 1 ||
        !is.numeric(sensitivity))
        stop("sensitivity must be a single numeric value")
    if (missing(criterion) || length(criterion) < 1 ||
        !is.numeric(criterion) ||
        (!is.null(dim(criterion)) && length(setsize) != max(dim(setsize))))
        stop("criterion must be an Nx1 vector, with N >= 1")
    if (missing(setsize) || length(setsize) < 1 ||
        (!is.null(dim(setsize)) &&length(setsize) != max(dim(setsize))))
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
    if (length(criterion) > 1 && length(criterion) != length(setsize)) {
        stop("criterion must be either a single value, or one per setsize")
    }

    k <- pmin(setsize, capacity)

    fa <- 1 - pnorm(criterion) ^ k
    hr <- 1 - k / setsize * pnorm(criterion - sensitivity) *
        (pnorm(criterion) ^ (k - 1)) - (setsize - k) / setsize *
            (pnorm(criterion) ^ k)

    return(list(hr=hr, fa=fa))
}
