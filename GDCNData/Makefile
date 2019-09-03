###FFLAGS = -g -C -m64
FFLAGS = -O -m64
###LDFLAGS = -Wl,-Bstatic

.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

FC=gfortran

LIBS = $(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a \
        $(HOME)/climexp_numerical/$(PVM_ARCH)/wrappers.a

SYSLIBS = -L/sw/lib -lnetcdff -lnetcdf -L/usr/local/lib -L$(HOME)/lib -lfgsl -lgsl -lfgsl -lgsl

addyears:	addyears.o
		$(FC) $(FFLAGS) -o $@ addyears.o $(LIBS)

gdcndata:	gdcndata.o gdcnsupport.o
		$(FC) $(FFLAGS) $(LDFLAGS) -o $@ gdcndata.o gdcnsupport.o $(LIBS) $(SYSLIBS)

ghcnd_data:	ghcnd_data.o gdcnsupport.o
		$(FC) $(FFLAGS) $(LDFLAGS) -o $@ $@.o gdcnsupport.o

