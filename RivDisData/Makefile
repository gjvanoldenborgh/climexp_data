FFLAGS = -O # -g -C

###FC = g95
FC = gfortran

all: makeindex getrunoff

makeindex:	makeindex.o llen.o
		$(FC) $(FFLAGS) -o $@ makeindex.o llen.o

getrunoff:	getrunoff.o support.o
		$(FC) $(FFLAGS) -o $@ $@.o support.o
