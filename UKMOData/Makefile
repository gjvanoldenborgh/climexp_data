.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

FC=pgf90
FFLAGS = -O
###FFLAGS = -g -fbounds-check

LIBS = $(HOME)/NINO/Fortran/$(PVM_ARCH)/climexp.a \
	$(HOME)/NINO/Fortran/$(PVM_ARCH)/libnr.a

LDFLAGS = $(FFLAGS) -L/sw/lib -lnetcdff -lnetcdf

hadslp2grads: hadslp2grads.o
		$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

hadghcnd2grads: hadghcnd2grads.o
		$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

ts2sigma:	ts2sigma.o
		$(FC) $(LDFLAGS) -o $@ $@.o $(LIBS)

cet2dat:	cet2dat.o
		$(FC) $(LDFLAGS) -o $@ $@.o 

dailycet2dat:	dailycet2dat.o
		$(FC) $(LDFLAGS) -o $@ $@.o 

dailyprcp2dat:	dailyprcp2dat.o
		$(FC) $(LDFLAGS) -o $@ $@.o 

