### Compute log-likelihood of observing some data at some setsizes given a
### max rule search model with a particular sensitivity, criterion, and
### optional capacity.  Assume accuracy data are i.i.d. binomial.
###
### The arguments hit and fa must be provided as counts, not proportions

logLikeBinom <- function(hit, fa, npos, nneg, setsize,
                         sensitivity, criterion, capacity) {

    ## Make sure all necessary arguments were provided
    for (arg in names(formals())) {
        if (arg == "capacity") next
        eval(parse(text=sprintf(
                     "if (missing(%s)) stop(\"argument %s missing\")",
                     arg, arg)))
    }
    if (missing(capacity) || !is.finite(capacity)) capacity <- NULL

    if (length(hit) != length(fa))
        stop("hit rate and false-alarm rate must be the same length")
    if (length(hit) != length(setsize))
        stop("hit rate and setsize must be the same length")
    if (length(criterion) != 1 && length(criterion) != length(setsize)) {
        print(criterion)
        stop("length of criterion must be 1 or the same as setsize")
    }

    if (!file.exists("maxrule.r"))
        stop("cannot find file maxrule.r")
    source("maxrule.r")

    pred <- maxrule(sensitivity, criterion, setsize, capacity)

    return(sum(log(dbinom(c(hit, fa), c(npos, nneg), c(pred$hr, pred$fa)))))
}
