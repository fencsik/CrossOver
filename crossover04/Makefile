# Explicit rules

all : fig0201.pdf tab0402.txt Exp1-ModelFits.txt

data02.rda : data.txt ComputeDprime.r
fig0201.pdf : data02.rda
data03.rda: data02.rda maxrule.r logLikeBinom.r ComputeDprime.r
data04.rda : data02.rda maxrule.r logLikeBinom.r ComputeDprime.r
tab0402.txt : data03.rda data04.rda
Exp1-ModelFits.txt : data03.rda data04.rda

# Commands and implicit rules

R = /usr/bin/R --slave --no-save --no-restore --no-readline --file=$<

%.rda: %.r; $(R)
%.pdf: %.r; $(R)
%.txt: %.r; $(R)

.PHONY : clean
clean :
	-rm -f *.rda fig*.pdf tab*.txt

# Local Variables:
# mode:makefile-gmake
# End:
