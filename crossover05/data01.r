### data01
###
### Aggregate RT, accuracy, and # of observations by subject, stim set,
### target, and setsize

f.data01 <- function () {
    infile <- "data00.rda"
    outfile <- "data01.rda"
    load(infile)

    ## Extract factors for all trials and for correct trials
    dataCC <- data00[data00$Accuracy == 1, ]
    factorsAll <- with(data00, list(setsize=SetSize, target=Target,
                                    cond=StimSet, sub=Subject))
    factorsCor <- with(dataCC, list(setsize=SetSize, target=Target,
                                    cond=StimSet, sub=Subject))

    ## Aggregate across factors
    data01 <- aggregate(data.frame(nobs=data00$Accuracy), factorsAll, length)
    data01$ncor <- aggregate(data00$Accuracy, factorsAll, sum)$x
    data01$pcor <- data01$ncor / data01$nobs
    data01$rt.all <- aggregate(data00$RT, factorsAll, mean)$x
    data01$rt <- aggregate(dataCC$RT, factorsCor, mean)$x

    save(data01, file=outfile)
}

f.data01()
rm(f.data01)
