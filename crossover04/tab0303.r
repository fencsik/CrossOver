### tab0303.r: test effects of setsize on criterion for unlimited-capacity
### models

f.tab0303 <- function () {
    infile <- "data03.rda"
    outfile <- "tab0303.txt"
    library("ez", quietly=TRUE, warn.conflicts=FALSE)
    load(infile)
    on.exit(while (sink.number() > 0) sink())
    dt <- melt(data03$par, id.vars=c("sub", "cond"),
               measure.vars=c("c1", "c2", "c4", "c8"),
               variable_name="setsize")
    dt$setsize <- factor(sub("c", "", as.character(dt$setsize)))
    names(dt)[names(dt) == "value"] <- "criterion"
    sink(outfile)
    cat("ANOVA on criterion as a function of setsize for the 2v5 task\n\n")
    print(ezANOVA(data=dt[dt$cond == "2v5", ],
                  dv=.(criterion),
                  wid=.(sub),
                  within=.(setsize),
                  detailed=TRUE))
    cat("\n\n")
    cat("ANOVA on criterion as a function of setsize for the Orientation task\n\n")
    print(ezANOVA(data=dt[dt$cond == "Orientation", ],
                  dv=.(criterion),
                  wid=.(sub),
                  within=.(setsize),
                  detailed=TRUE))
}

f.tab0303()
rm(f.tab0303)
