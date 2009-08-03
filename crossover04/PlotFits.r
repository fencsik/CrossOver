### Plots averaged observed and predicted hit rates and false-alarm rates
### for all fits present in the current directory.

PlotFits <- function () {
    thisfile <- "PlotFits.r"
    infiles <- list.files(pattern="Fit.*\\.rda")
    outfiles <- sub("\\.rda", ".pdf", infiles)

    ## Add up-to-date check

    ## Add actual plotting
}

PlotFits()
rm(PlotFits)
