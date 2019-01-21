FFLAGS = -g -fbounds-check

FC = gfortran

.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

LIBS = 	$(HOME)/NINO/Fortran/$(PVM_ARCH)/climexp.a

SYSLIBS = -L$(HOME)/lib -L/sw/lib -L/sw/opt/netcdf7/lib -lnetcdff -lnetcdf -lhdf5 -lcurl

27today:	27today.o
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)