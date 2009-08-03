### Refresh all experiments

refresh.all <- function () {
    exps <- c("crossover04")

    refreshFile <- "refresh.r"

    pwd <- getwd()
    on.exit(setwd(pwd))

    for (x in exps) {
        if (!file.exists(x))
            stop("experiment ", x, " is missing")
        if (!file.exists(file.path(x, refreshFile)))
            stop("experiment ", x, " is missing file ", refreshFile)
        cat(rep("-", 75), "\n", sep="")
        cat("Refreshing ", x, "/\n\n", sep="")
        flush.console()
        setwd(x)
        source(refreshFile)
        setwd(pwd)
    }
}

refresh.all()
rm(refresh.all)
