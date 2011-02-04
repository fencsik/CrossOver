# Explicit rules

all : fig0201.pdf

rawdata.rda : data/*
data00.rda : rawdata.rda
data01.rda : data00.rda
data02.rda : data01.rda
fig0201.pdf : data02.rda

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
