.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)	 -c $<

FC = gfortran
###FFLAGS = -g -fbounds-check -I/sw/include -I/usr/local/free/include
FFLAGS = -O -I/sw/include -I/usr/local/free/include -I/home/oldenbor/include -I/usr/include/

LIBS    = $(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a \
	  $(HOME)/climexp_numerical/$(PVM_ARCH)/wrappers.a

###SYSLIBS = -L/sw/lib -L/sw/lib//netcdf-gfortran/lib -L/usr/local/lib -lnetcdff -lnetcdf -lfftw3f
SYSLIBS = -L/sw/lib -L/sw/opt/netcdf7/lib -L/usr/local/free/lib -L/usr/local/lib -L$(HOME)/lib -lnetcdff -lnetcdf -lcurl

prcp2mm:	prcp2mm.o $(LIBS)
		$(FC) $(FFLAGS) -o $@ prcp2mm.o $(LIBS) $(SYSLIBS)

bandpass_variance:	bandpass_variance.o $(LIBS)
		$(FC) $(FFLAGS) -o $@ $@.o $(LIBS) $(SYSLIBS) -lfftw3f

autocorrelation:	autocorrelation.o $(LIBS)
		$(FC) $(FFLAGS) -o $@ $@.o $(LIBS) $(SYSLIBS)
