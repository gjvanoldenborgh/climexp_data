.SUFFIXES: .f90 .o

.f90.o:
		$(FC) $(FFLAGS)  -c $<

FFLAGS=-I/sw/include -fbackslash -ffpe-trap=invalid,zero,overflow

FC=gfortran

LIBS=$(HOME)/NINO/Fortran/$(PVM_ARCH)/climexp.a -L/sw/lib -lnetcdff -lnetcdf -L$(HOME)/lib/$(PVM_ARCH) -lnr

sysu2nc:	sysu2nc.o
			$(FC) $(FFLAGS) -o sysu2nc sysu2nc.o $(LIBS)