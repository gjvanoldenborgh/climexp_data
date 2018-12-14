FFLAGS = -O # -m64
###FFLAGS = -g -C # -m64

###FC = g95
FC = gfortran

LIBS = 	$(HOME)/NINO/Fortran/$(PVM_ARCH)/climexp.a \
	$(HOME)/NINO/Fortran/$(PVM_ARCH)/libnr.a

SYSLIBS = -L$(HOME)/lib -L/sw/lib -lnetcdf -lnetcdff

dat2grads:	dat2grads.o $(LIBS)
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS) $(SYSLIBS)

somdat:	somdat.o $(LIBS)
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)
