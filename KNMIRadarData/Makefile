FFLAGS = -m64 -g -fbounds-check -I/usr/include
###FFLAGS = -m64 -O

.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

FC = gfortran

LIBS = $(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a \
       $(HOME)/climexp_numerical/$(PVM_ARCH)/wrappers.a

SYSLIBS=-L/sw/lib -L/usr/local/lib -lnetcdff -lnetcdf

km2latlon:	km2latlon.o geotoradar.o
	$(FC) $(FFLAGS) -o $@ $@.o geotoradar.o $(LIBS) $(SYSLIBS)
