# Explicit rules

all : fig0201.pdf fig0301.pdf fig0302.pdf tab0303.txt \
	fig0401.pdf fig0402.pdf tab0402.txt tab0403.txt \
	fig0501.pdf fig0502.pdf tab0504.txt \
	fig0601.pdf fig0602.pdf tab0602.txt tab0604.txt \
	Exp2-ModelFits.txt

rawdata.rda : data/*
data00.rda : rawdata.rda
data01.rda : data00.rda
data02.rda : data01.rda ComputeDprime.r
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
data05.rda : data02.rda maxrule.r logLikeBinom.r ComputeDprime.r
fig0501.pdf : data05.rda
fig0502.pdf : data05.rda
tab0504.txt : data03.rda data05.rda
data06.rda : data02.rda maxrule.r logLikeBinom.r ComputeDprime.r
fig0601.pdf : data06.rda
fig0602.pdf : data06.rda
tab0602.txt : data05.rda data06.rda
tab0604.txt : data04.rda data06.rda
Exp2-ModelFits.txt : data03.rda data04.rda

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
