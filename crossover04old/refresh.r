### Refresh all analysis files in this directory

refresh <- function () {
    targetFiles <- c("data00.r",
                     "FitMaxSSE.r",
                     "FitMaxCapSSE.r",
                     "FitMaxCritSSE.r",
                     "FitMaxCapCritSSE.r",
                     "FitMaxML.r",
                     "FitMaxCapML.r",
                     "FitMaxPaper.r",
                     "FitMaxCapPaper.r",
                     "FitPMaxSSE.r",
                     "FitPMaxCapSSE.r",
                     "TestFits.r",
                     "PlotFits.r",
                     "PlotFitsSub.r")

    for (fname in targetFiles) {
        if (!file.exists(fname)) stop(paste("File", fname, "not found"))
        cat("Refreshing", fname, "\n")
        flush.console()
        source(fname)
    }
}

refresh()
rm(refresh)
