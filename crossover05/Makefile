# Explicit rules

all : fig0201.pdf data03.rda data04.rda

rawdata.rda : data/*
data00.rda : rawdata.rda
data01.rda : data00.rda
data02.rda : data01.rda ComputeDprime.r
fig0201.pdf : data02.rda
data03.rda: data02.rda maxrule.r logLikeBinom.r ComputeDprime.r
data04.rda : data02.rda maxrule.r logLikeBinom.r ComputeDprime.r

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
