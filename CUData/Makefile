###FFLAGS = -Ktrap=fp -O3  -Mlarge_arrays
FFLAGS = -g -C -Ktrap=fp -Mlarge_arrays

###FC = g95
FC = pgf90

LIBS = 	$(HOME)/NINO/Fortran/$(PVM_ARCH)/climexp.a \
        $(HOME)/lib/$(PVM_ARCH)/libnr.a

tenday2month:	tenday2month.o $(LIBS)
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS) -L$(HOME)/lib -lnetcdff -lnetcdf
