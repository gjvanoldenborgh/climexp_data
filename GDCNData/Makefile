###FFLAGS = -g -C -m64
FFLAGS = -O -m64
###LDFLAGS = -Wl,-Bstatic

.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

FC=gfortran

LIBS=$(HOME)/NINO/Fortran/$(PVM_ARCH)/climexp.a

addyears:	addyears.o
		$(FC) $(FFLAGS) -o $@ addyears.o $(LIBS)

gdcndata:	gdcndata.o gdcnsupport.o
		$(FC) $(FFLAGS) $(LDFLAGS) -o $@ gdcndata.o gdcnsupport.o $(LIBS)

ghcnd_data:	ghcnd_data.o gdcnsupport.o
		$(FC) $(FFLAGS) $(LDFLAGS) -o $@ $@.o gdcnsupport.o

