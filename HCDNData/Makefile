FFLAGS = -g -C

###FC = g95
FC = gfortran

all: getusrunoff

getusrunoff:	getusrunoff.o support.o
		$(FC) $(FFLAGS) -o $@ $@.o support.o
