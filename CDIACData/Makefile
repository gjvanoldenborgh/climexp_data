.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

all: getpress

###FFLAGS = -O
FFLAGS = -m64 -g -fbounds-check

###FC = g95
FC = gfortran

LIBS = $(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a

getpress:	getpress.o support.o
		$(FC) $(FFLAGS) -o $@ $@.o support.o

maunaloa2dat:	maunaloa2dat.o
		$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)
