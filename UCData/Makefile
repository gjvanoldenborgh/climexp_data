.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

FFLAGS = -O

FC = gfortran

LD = $(FC) $(FFLAGS)

LIBS = $(HOME)/NINO/Fortran/$(PVM_ARCH)/climexp.a

SYSLIBS=-L/sw/lib -L$(HOME)/lib -lnetcdff -lnetcdf -L$(HOME)/lib/$(PVM_ARCH) -lnr

asc2nc: asc2nc.o $(LIBS)
	$(LD) $(FFLAGS) -o $@ $@.o $(LIBS) $(SYSLIBS)
