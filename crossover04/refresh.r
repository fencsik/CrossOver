### Refresh all analysis files in this directory

refresh <- function () {
    targetFiles <- c("data00.r",
                     "FitMaxSSE.r",
                     "FitMaxCapSSE.r",
                     "FitMaxML.r",
                     "FitMaxCapML.r",
                     "PlotFits.r")

    for (fname in targetFiles) {
        if (!file.exists(fname)) stop(paste("File", fname, "not found"))
        cat("Refreshing", fname, "\n")
        flush.console()
        source(fname)
    }
}

refresh()
rm(refresh)
