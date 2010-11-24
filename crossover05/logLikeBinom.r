### Compute log-likelihood of observing some data at some setsizes given a
### max rule search model with a particular sensitivity, criterion, and
### optional capacity.  Assume accuracy data are i.i.d. binomial.
###
### The arguments hit and fa must be provided as counts, not proportions

logLikeBinom <- function(hit, fa, npos, nneg, setsize,
                         sensitivity, criterion, capacity,
                         correct=NULL) {

    ## Make sure all necessary arguments were provided
    for (arg in names(formals())) {
        if (arg == "capacity" || arg == "correct") next
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
