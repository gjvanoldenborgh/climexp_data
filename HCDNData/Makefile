FFLAGS = -g -C

FC = gfortran

all: getusrunoff

getusrunoff:	getusrunoff.o support.o
		$(FC) $(FFLAGS) -o $@ $@.o support.o
