# Explicit rules

all : data02.rda

rawdata.rda : rawdata.r data/*
data00.rda : rawdata.rda data00.r
data01.rda : data00.rda data01.r
data02.rda : data01.rda data02.r

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
