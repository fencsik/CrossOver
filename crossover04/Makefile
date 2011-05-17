# Explicit rules

all : fig0201.pdf fig0301.pdf fig0302.pdf tab0303.txt \
	fig0401.pdf fig0402.pdf tab0402.txt tab0403.txt \
	Exp1-ModelFits.txt

data02.rda : data.txt ComputeDprime.r
fig0201.pdf : data02.rda
data03.rda: data02.rda maxrule.r logLikeBinom.r ComputeDprime.r
fig0301.pdf : data03.rda
fig0302.pdf : data03.rda
tab0303.txt : data03.rda
data04.rda : data02.rda maxrule.r logLikeBinom.r ComputeDprime.r
fig0401.pdf : data04.rda
fig0402.pdf : data04.rda
tab0402.txt : data03.rda data04.rda
tab0403.txt : data04.rda
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
