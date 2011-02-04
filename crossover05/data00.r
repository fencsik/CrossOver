### data00
###
### Filter raw data and output to binary file

f.data00 <- function () {
    infile <- "rawdata.rda"
    outfile <- "data00.rda"
    data00 <- load(infile)

    ## Filter out unwanted trials
    rawdata <- rawdata[rawdata$Block == "experimental" &
                  rawdata$Accuracy >= 0 &
                  rawdata$RT <= 2000, ]

    ## Fix factors
    rawdata$Subject <- factor(toupper(substr(as.character(rawdata$Subject), 1, 3)))
    rawdata$Block <- factor(rawdata$Block)
    rawdata$Target <- factor(rawdata$Target, levels=c(0, 1),
                             labels=c("absent", "present"))
    rawdata$SetSize <- factor(rawdata$SetSize)
    rawdata$Precue <- factor(rawdata$Precue)
    rawdata$Response <- factor(rawdata$Response)

    data00 <- rawdata
    save(data00, file=outfile)
    invisible(data00)
}

f.data00()
rm(f.data00)
