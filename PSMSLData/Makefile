.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

all: getsealev

FFLAGS = -g -fbounds-check
LIBS = $(HOME)/climexp_numerical/$(PVM_ARCH)/wrappers.a -L/usr/local/lib -lfgsl -lgsl

FC = gfortran

getsealev:	getsealev.o support.o Makefile
		$(FC) $(FFLAGS) -o $@ $@.o support.o $(LIBS)
