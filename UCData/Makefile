.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

FFLAGS = -O3 -m64 -Dlinux -fbackslash # -fno-backtrace

FC = gfortran

LD = $(FC) $(FFLAGS) -Wl,-framework -Wl,vecLib

LIBS = $(HOME)/NINO/Fortran/$(PVM_ARCH)/climexp.a

SYSLIBS=-L/sw/lib -lnetcdff -lnetcdf -L$(HOME)/lib/$(PVM_ARCH) -lnr

asc2nc: asc2nc.o $(LIBS)
	$(LD) $(FFLAGS) -o $@ $@.o $(LIBS) $(SYSLIBS)
