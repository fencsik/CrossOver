### tab0403.r: test effects of setsize on criterion for limited-capacity
### models

### dt <- melt(data03$par, c("sub", "cond"), c("c1", "c2", "c4", "c8"),
### variable.name="setsize", value.name="criterion")

### print(ezANOVA(data=dt[dt$cond == "Orientation", ], dv=.(criterion),
### wid=.(sub), within=.(setsize)))

f.tab0403 <- function () {
    infile <- "data04.rda"
    outfile <- "tab0403.txt"
    library("ez", quietly=TRUE, warn.conflicts=FALSE)
    ### ## The ez package loads reshape2, then ggplot2, which loads reshape in
    ### ## front of reshape2, so I lose that functionality.  The following
    ### ## three lines move reshape2 to the front of the line, but it's hackish
    ### if (any(search() == "package:reshape2"))
    ###     detach("package:reshape2", force=TRUE)
    ### library("reshape2", quietly=TRUE, warn.conflicts=FALSE)
    load(infile)
    on.exit(while (sink.number() > 0) sink())
    dt <- melt(data04$par, id.vars=c("sub", "cond"),
               measure.vars=c("c1", "c2", "c4", "c8"),
               variable_name="setsize", value.name="criterion")
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

f.tab0403()
rm(f.tab0403)
