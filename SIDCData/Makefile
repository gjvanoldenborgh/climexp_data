.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

FC = gfortran

LIBS = $(HOME)/NINO/Fortran/$(PVM_ARCH)/climexp.a \
       $(HOME)/NINO/Fortran/$(PVM_ARCH)/wrappers.a \
       -lnetcdff -lnetcdf -llapack -lblas -lcurl -lfgsl -lgsl

LDFLAGS = -L$(HOME)/lib -L/usr/local/free/lib/ -L$(HOME)/l -L/sw/opt/netcdf7/lib -L/sw/lib 

convert:	convert.o
		$(FC) -o $@ convert.o

sunspots2double:	sunspots2double.o
		$(FC) $(LDFLAGS) -o $@ sunspots2double.o $(LIBS)
